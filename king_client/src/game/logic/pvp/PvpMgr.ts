module Pvp {

    export class PvpMgr {
        private static _inst: PvpMgr;

        private _fightCamp: Camp;
        private _fightPool: FightCardPool;
        private _isMatching: boolean;
        private _camp2CardPools: Collection.Dictionary<Camp, Array<FightCardPool>>;

        private _pvpLevel: number;
        private _pvpRankNeedRefresh: boolean;
        private _pvpSeasonRankNeedRefresh: boolean;

        private _onEnterPvpPromise: Promise<Array<any>> = null;
        
        public static get inst(): PvpMgr {
            if (!PvpMgr._inst) {
                PvpMgr._inst = new PvpMgr();
            }
            return PvpMgr._inst;
        }

        public constructor() {
            Player.inst.addEventListener(Player.PvpScoreChangeEvt, this._onScoreChange, this);
            this._pvpLevel = this.getPvpLevelByScore(Player.inst.getResource(ResType.T_SCORE));
            this._pvpRankNeedRefresh = true;
            this._pvpSeasonRankNeedRefresh = true;
            Core.EventCenter.inst.addEventListener(GameEvent.CardInCampaignMsEv, this._onCardInCampaignMs, this);
        }

        public isCardInTeam(cardId: number): boolean {
            let card = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
            if (!card) {
                return false;
            } else {
                let pools = this._camp2CardPools.getValue(card.camp);
                if (!pools) {
                    return false;
                } else {
                    for (let i = 0; i < pools.length; ++ i) {
                        if (pools[i].isCardInPool(cardId)) {
                            return true;
                        }
                    }
                    return false;
                }
            }
        }
        public isCardInSeason(cardId: number): boolean {
            let card = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
            console.log(card.name,card.isInSeason, card.cardId);
            return card.isInSeason;

        }

        public get pvpRankNeedRefresh(): boolean {
            return this._pvpRankNeedRefresh;
        }

        public set pvpRankNeedRefresh(b: boolean) {
            this._pvpRankNeedRefresh = b;
        }

        public get pvpSeasonRankNeedRefresh(): boolean {
            return this._pvpSeasonRankNeedRefresh;
        }

        public set pvpSeasonRankNeedRefresh(b: boolean) {
            this._pvpSeasonRankNeedRefresh = b;
        }

        private _onRelogin() {
            this._pvpRankNeedRefresh = true;
        }

        public onLogout() {
            this._fightCamp = null;
            this._isMatching = false;
        }

        public isNewbie(): boolean {
            return Player.inst.getResource(ResType.T_SCORE) <= 0;
        }

        public get fightCamp(): Camp {
            return this._fightCamp;
        }

        public set fightCamp(camp:Camp) {
            this._fightCamp = camp;
        }

        public get fightPool(): FightCardPool {
            return this._fightPool;
        }

        public set fightPool(pool:FightCardPool) {
            this._fightPool = pool;
            //console.log(`set pool`, pool, this.fightPool);
        }

        public get isMatching(): boolean {
            return this._isMatching;
        }

        public isOpen(): boolean {
            return Level.LevelMgr.inst.getLevel(9).state >= Level.LevelState.Clear
        }

        public getPvpLevel(score?: number): number {
            if (score == null) {
                //score = Player.inst.getResource(ResType.T_SCORE);
                return this._pvpLevel;
            } else {
                return this.getPvpLevelByScore(score);
            }
        }

        private _onScoreChange() {
            let pvpLevel = this.getPvpLevelByScore(Player.inst.getResource(ResType.T_SCORE));
            if (pvpLevel != this._pvpLevel) {
                this._pvpLevel = pvpLevel;
                Core.EventCenter.inst.dispatchEventWith(GameEvent.PvpLevelChangeEv);
            }
        }

        private _onCardInCampaignMs(ev:egret.Event) {
            let card = ev.data as CardPool.Card;
            if (!card.isInCampaignMission) {
                return;
            }
            if (!this._camp2CardPools) {
                return;
            }

            let needRefresh = false;
            this._camp2CardPools.forEach((_:Camp, pools:Array<FightCardPool>) => {
                pools.forEach(p => {
                    let needRefresh2 = p.onCardInCampaignMs(card.cardId);
                    if (!needRefresh) {
                        needRefresh = needRefresh2;
                    }
                });
            });

            if (needRefresh) {
                let view = <Pvp.TeamView>Core.ViewManager.inst.getView(ViewName.team);
                if (view) {
                    view.refresh(this._fightCamp, this._camp2CardPools);
                }
            }
        }

        public getPvpStarCnt(score?: number): number {
            let level = this.getPvpLevel(score);
            if (score == null) {
                score = Player.inst.getResource(ResType.T_SCORE);
            }
            let ret = score
            for (let i = 1; i < level; i ++) {
                ret -= Config.inst.getPvpMaxStar(i);
            }
            //console.debug(`getPvpStarCnt level=${level} score=${score}, star=${ret}`);
            return ret;
        }

        public getPvpLevelByScore(val:number): number {
            /*
            let allLevel = Data.duel.keys;
            for (let i=allLevel.length-1; i>=0; i--) {
                let lv = allLevel[i];
                if (val >= Data.duel.get(lv).score) {
                    return lv;
                }
            }
            */
            let allLevel = Data.rank.keys;
            for (let i = 0; i < allLevel.length; i ++) {
                let maxStar = Config.inst.getPvpMaxStar(allLevel[i]);
                val -= maxStar;
                if (val <= 0) {
                    return allLevel[i];
                }
            }
            return allLevel[allLevel.length - 1];
        }

        public getNextPvpLevelScore(): number {
            return this.getNextPvpLevelScoreByLevel(this.getPvpLevel());
        }

        public getNextPvpLevelScoreByLevel(lv:number): number {
            let lvData = Data.duel.get(lv + 1);
            if (lvData) {
                return lvData.score;
            } else {
                return 0;
            }
        }

        public async onEnterPvp(): Promise<Array<any>> {
            if (!this._onEnterPvpPromise) {
                this._onEnterPvpPromise = this._doEnterPvp();
            }
            let ret = await this._onEnterPvpPromise;
            this._onEnterPvpPromise = null;
            return ret;
        }

        private async _doEnterPvp():Promise<Array<any>> {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_CARD_DATA, null);
            if (result.errcode != 0) {
                return;
            }

            //let _localfightCamp = egret.localStorage.getItem(`player:${Player.inst.uid}:fightCamp`);
            //if (!this._fightCamp && _localfightCamp) {
            //    this._fightCamp = parseInt(_localfightCamp);
            //}

            let campPools = new Collection.Dictionary<Camp, Array<FightCardPool>>();
            let reply = pb.CardPools.decode(result.payload);
            reply.Pools.forEach(poolData => {
                let pool = new FightCardPool(poolData);
                let pools = campPools.getValue(pool.camp);
                if (!pools) {
                    pools = [];
                    campPools.setValue(pool.camp, pools);
                }
                pools.push(pool);
            })

            this._fightCamp = reply.FightCamp;

			PvpMgr.inst.fightCamp = this._fightCamp;
            campPools.getValue(this._fightCamp).forEach((pool, index) => {
                if (pool.isFight) {
                    PvpMgr.inst.fightPool = pool;
                }
            });
            console.log(`set fight pool ${this._fightCamp} ${campPools}`, PvpMgr.inst);
            this._camp2CardPools = campPools
            return [this._fightCamp, campPools];
        }

        public updateFightPool(modifyPool:Array<any>, fightCamp:Camp) {
            Net.rpcPush(pb.MessageID.C2S_UPDATE_CARD_POOL, pb.UpdateCardPools.encode({"Pools": modifyPool, "FightCamp":fightCamp}));
        }

        public async beginMatch() {
            // 正在匹配不能继续匹配
            if (Core.ViewManager.inst.isShow(ViewName.matching)) return;
            // 在战斗中不能匹配
            if (Battle.BattleMgr.inst.battle) return;
            if (!Core.DeviceUtils.isWXGame() && Player.inst.isNewbieName( Player.inst.name ) && this.getPvpLevel() >= 2) {
                Core.ViewManager.inst.open(ViewName.modifyName);
                await new Promise<void>(reslove => {
                    Core.EventCenter.inst.once(GameEvent.ModifyNameEv, ()=>{
                        reslove();
                    }, this);
                });
            }
            
            // Core.ViewManager.inst.open(ViewName.matching);
            // Core.ViewManager.inst.open(ViewName.rankSeasonRandomCard, 3);
            let result = await Net.rpcCall(pb.MessageID.C2S_BEGIN_MATCH, pb.MatchArg.encode({"Camp":this.fightCamp}));
            if (result.errcode == 0) {
                // this._isMatching = true;
                let reply = pb.MatchReply.decode(result.payload);
                if (reply.ChooseCardData) {
                    Core.ViewManager.inst.open(ViewName.rankSeasonRandomCard, reply.ChooseCardData, reply.LastCamp);
                } else if (reply.NeedChooseCamp) {
                    Core.ViewManager.inst.open(ViewName.rankSeasonRandomCard, reply.ChooseCardData, reply.LastCamp);
                } else {
                    Core.ViewManager.inst.open(ViewName.matching);
                    this._isMatching = true;
                }
            } else {
                Core.ViewManager.inst.close(ViewName.matching);
            }
        }

        public async cancelMatch() {
            if (!this._isMatching) {
                SoundMgr.inst.playBgMusic("bg_mp3");
                Core.ViewManager.inst.close(ViewName.matching);
                return;
            }

            let result = await Net.rpcCall(pb.MessageID.C2S_STOP_MATCH, null);
            if (result.errcode != 1) {
                this._isMatching = false;
                SoundMgr.inst.playBgMusic("bg_mp3");
                Core.ViewManager.inst.close(ViewName.matching);
            }

            Core.EventCenter.inst.dispatchEventWith(GameEvent.MatchStopEv);
        }

        public async readyFight() {
            // console.log(this._isMatching);
            if (!this._isMatching) {
                return;
            }
            this._isMatching = false;
            let matchingWnd = Core.ViewManager.inst.getView(ViewName.matching) as MatchingWnd;
            await matchingWnd.readyFight();
            //Core.ViewManager.inst.close(ViewName.match);
        }

        public onMatchTimeout() {
            this._isMatching = false;
            SoundMgr.inst.playBgMusic("bg_mp3");
            Core.ViewManager.inst.close(ViewName.matching);
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60225));
            Core.EventCenter.inst.dispatchEventWith(GameEvent.MatchStopEv);
        }

        public async watchVideo() {
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_BATTLE_VIDEO, null, true, false);
            if (result.errcode != 0) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60127));
                return;
            }

            Battle.VideoPlayer.inst.play(pb.VideoBattleData.decode(result.payload));
        }

    }

    function onLogout() {
        try {
            PvpMgr.inst.onLogout();
        } catch (e) {
            console.error(e);
        }
    }

    export function init() {
        Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);
        initRpc();

        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;

        registerView(ViewName.match, () => {
            return createObject(PkgName.pvp, ViewName.match, MatchView);
        });

        registerView(ViewName.choiceFightCard, () => {
            return createObject(PkgName.common, ViewName.choiceFightCard, UI.ChoiceFightCardView);
        });


        registerView(ViewName.rankSeason, () => {
            return createObject(PkgName.pvp, ViewName.rankSeason, RankSeasonWnd);
        });
        
        registerView(ViewName.rankSeasonTreasureInfo, () => {
            return createObject(PkgName.pvp, ViewName.rankSeasonTreasureInfo, RankSeasonTreasureInfo);
        });

        registerView(ViewName.rebornShopView, () => {
            return createObject(PkgName.reborn, ViewName.rebornShopView, Reborn.RebornShopView);
        });
        registerView(ViewName.rebornWnd, () => {
            let rebornWnd = new Reborn.RebornWnd();
            rebornWnd.contentPane = createObject(PkgName.reborn, ViewName.rebornWnd).asCom;
            return rebornWnd;
        });
        registerView(ViewName.refineWnd, () => {
            let refineWnd = new Reborn.RefineWnd();
            refineWnd.contentPane = createObject(PkgName.reborn, ViewName.refineWnd).asCom;
            return refineWnd;
        });
        registerView(ViewName.refineInfoWnd, () => {
            let refineInfoWnd = new Reborn.RefineInfoWnd();
            refineInfoWnd.contentPane = createObject(PkgName.reborn, ViewName.refineInfoWnd).asCom;
            return refineInfoWnd;
        });
        registerView(ViewName.featCardInfo, () => {
            let featCardInfo = new CardPool.BuyCardInfoWnd();
            featCardInfo.contentPane = createObject(PkgName.reborn, ViewName.featCardInfo).asCom;
            return featCardInfo;
        });
        registerView(ViewName.privInfo, () => {
            let privInfo = new Reborn.PrivInfo();
            privInfo.contentPane = createObject(PkgName.reborn, ViewName.privInfo).asCom;
            return privInfo;
        });
        registerView(ViewName.rebornEquipInfo, () => {
            let rebornEquipInfo = new Reborn.RebornEquipInfo();
            rebornEquipInfo.contentPane = createObject(PkgName.reborn, ViewName.rebornEquipInfo).asCom;
            return rebornEquipInfo;
        });
        registerView(ViewName.buySkinInfo, () => {
            let buySkinInfo = new Reborn.BuySkinInfo();
            buySkinInfo.contentPane = createObject(PkgName.reborn, ViewName.buySkinInfo).asCom;
            return buySkinInfo;
        });
        registerView(ViewName.matching, () => {
            return createObject(PkgName.pvp, ViewName.matching, MatchingWnd);
        });
        
        registerView(ViewName.team, () => {
            return createObject(PkgName.pvp, ViewName.team, TeamView);
        });

        registerView(ViewName.rankRewardView, () => {
            return createObject(PkgName.pvp, ViewName.rankRewardView, RankRewardView);
        });

       registerView(ViewName.rankListWnd, () => {
            let rankListWnd = new RankListWnd();
            rankListWnd.contentPane = createObject(PkgName.pvp, ViewName.rankListWnd).asCom;
            return rankListWnd;
       });  

        registerView(ViewName.rankUpTips, () => {
            let rankupTipsWnd = new RankupTipsWnd();
            rankupTipsWnd.contentPane = createObject(PkgName.pvp, ViewName.rankUpTips).asCom;
            return rankupTipsWnd;
        });  
        
        registerView(ViewName.rankUpRewardTips, () => {
            let rankupRewardTipsWnd = new RankupRewardTipsWnd();
            rankupRewardTipsWnd.contentPane = createObject(PkgName.pvp, ViewName.rankUpRewardTips).asCom;
            return rankupRewardTipsWnd;
        });  

        registerView(ViewName.videoHall, () => {
            return createObject(PkgName.pvp, ViewName.videoHall, VideoHallWnd);
        });  

        registerView(ViewName.videoRecord, () => {
            return createObject(PkgName.pvp, ViewName.videoRecord, VideoRecordWnd);
        });

        registerView(ViewName.videoUpload, () => {
            return createObject(PkgName.pvp,ViewName.videoUpload, VideoUploadWnd);
        });

        registerView(ViewName.videoDiscuss, () => {
            return createObject(PkgName.pvp, ViewName.videoDiscuss, VideoDiscussWnd);
        });

		registerView(ViewName.videoSearch, () =>{
            let videoSearchWnd = new VideoSearchWnd();
		    videoSearchWnd.contentPane = createObject(PkgName.pvp, ViewName.videoSearch).asCom;
            return videoSearchWnd;
        });   

        registerView(ViewName.wechatPlatform, () => {
            return createObject(PkgName.pvp, ViewName.wechatPlatform, WechatPlatform);
        });

        registerView(ViewName.mail, () => {
            return createObject(PkgName.pvp, ViewName.mail, MailWnd);
        });
        
        registerView(ViewName.mailInfo, () => {
            return createObject(PkgName.pvp, ViewName.mailInfo, MailInfoWnd);
        });

        registerView(ViewName.getRewardWnd, () => {
            return createObject(PkgName.common, ViewName.getRewardWnd, GetRewardWnd);
        });

        registerView(ViewName.faqView, () => {
            return createObject(PkgName.pvp, ViewName.faqView, FaqView);
        });

        registerView(ViewName.videoShareOption, () => {
			let videoShareOptionWnd = new Pvp.VideoShareOptWnd();
			videoShareOptionWnd.contentPane = createObject(PkgName.pvp, ViewName.videoShareOption).asCom;
			return videoShareOptionWnd;
		});
        registerView(ViewName.rankSeasonRandomCard, () => {
            let rankSeasonRandomCard = new Pvp.RankFirstWnd();
            rankSeasonRandomCard.contentPane = createObject(PkgName.pvp, ViewName.rankSeasonRandomCard).asCom;
            return rankSeasonRandomCard;
        })
        registerView(ViewName.rankSeasonRandomCard, () => {
            let rankSeasonRandomCard = new Pvp.RankFirstWnd();
            rankSeasonRandomCard.contentPane = createObject(PkgName.pvp, ViewName.rankSeasonRandomCard).asCom;
            return rankSeasonRandomCard;
        })
        registerView(ViewName.rankSeasonHandCard, () => {
            let rankSeasonHandCard = new Pvp.RankHandWnd();
            rankSeasonHandCard.contentPane = createObject(PkgName.pvp, ViewName.rankSeasonHandCard).asCom;
            return rankSeasonHandCard;
        });


        if (Core.DeviceUtils.isWXGame()) {
            registerView(ViewName.wxgameFriendRankView, () => {
                let wxgameFriendRankView = new WXGameFriendRankView();
                wxgameFriendRankView.contentPane = createObject(PkgName.pvp, ViewName.wxgameFriendRankView).asCom;
                return wxgameFriendRankView;
            });
        }
    }

}
