module Battle {

    export class BattleMgr {
        public static _inst: BattleMgr;

        private _group2Skill: Collection.MultiDictionary<string, any>;
        private _battle: Battle;

        public static get inst(): BattleMgr {
            if (!BattleMgr._inst) {
                BattleMgr._inst = new BattleMgr();
            }
            return BattleMgr._inst;
        }

        private _initSkillData() {
            this._group2Skill = new Collection.MultiDictionary<string, any>();
            Data.skill.keys.forEach(skillID => {
                let skillData = Data.skill.get(skillID);
                if (!skillData.skillGroup || skillData.skillGroup == "") {
                    return;
                }

                this._group2Skill.setValue(skillData.skillGroup, skillData);
            });
        }

        public getGroupSkills(groupID: string): Array<any> {
            return this._group2Skill.getValue(groupID);
        }

        public onLogout() {
            this._battle = null;
        }

        public get battle(): Battle {
            return this._battle;
        }

        public async beginBattle(data:any, type:BattleType, ...param:any[]) {
            if (this._battle) {
                console.error("i am already in battle");
            }

            if (!this._group2Skill) {
                this._initSkillData();
            }

            switch(type) {
            case BattleType.PVP:
                this._battle = new Battle(data, ...param);
                TD.onPvpBegin(this._battle);
                break;
            case BattleType.LEVEL:
                TD.onLevelBegin(param[0]);
                this._battle = new LevelBattle(data, ...param);
                break;
            case BattleType.LevelHelp:
                TD.onLevelBegin(param[0]);
                this._battle = new LevelHelpBattle(data, ...param);
                break;
            /*
            case BattleType.CAMPAIGN:
            case BattleType.CAMPAIGN_DEF:
                if (type == BattleType.CAMPAIGN) {
                    TD.onCampaignBegin(param[0], param[1], param[2]);
                } else {
                    TD.onCampaignDefBegin(param[0], param[1]);
                }
                this._battle = new CampaignBattle(data, type, ...param);
                break;
            */
            case BattleType.Guide:
                 this._battle = new GuideBattle(data, ...param);
                 Guide.GuideMgr.inst.saveGuideBattleSign(false);
                 break;
            case BattleType.VIDEO:
                this._battle = new VideoBattle(data, ...param);
                break;
            case BattleType.Friend:
                this._battle = new FriendBattle(data, ...param);
                break;
            case BattleType.Campaign:
                this._battle = new CampaignBattle(data, ...param);
                break;
            default:
                break;
            }
            if (!this._battle) {
                console.debug("create battle error %d", type);
                return;
            }

            BoutActionPlayer.createInst();
            await Core.ViewManager.inst.close(ViewName.battle);
            await Core.ViewManager.inst.open(ViewName.battle, this._battle);
            if (this._battle.isPvp() || type == BattleType.Guide) {
                await fairygui.GTimers.inst.waitTime(1000);
                await Core.ViewManager.inst.open(ViewName.pvpVs, this._battle);
                Core.ViewManager.inst.close(ViewName.pvpVs);
            }
            //await BoutActionPlayer.inst.playActions(data.Effects, false);
            this._battle.readyDone();
        }

        public async endBattle(data:any, isReplay:boolean = false) {
            if (!this._battle) {
                return;
            }
            this._battle.beforeEndBattle(data.WinUid == this._battle.getOwnFighter().uid);
            await BoutActionPlayer.inst.waitActionComplete();
            await fairygui.GTimers.inst.waitTime(300);
            await this._battle.endBattle(data, isReplay);
            if (Core.DeviceUtils.isWXGame()) {
                WXGame.WXGameMgr.inst.onBattleEnd();
            }
            this._battle = null;
        }

        private async restoredBattle(data:pb.RestoredFightDesk) {
            if (this._battle) {
                console.debug("restoredBattle error, i am already in battle");
                return;
            }

            if (!data.Desk) {
                return;
            }

            if (!this._group2Skill) {
                this._initSkillData();
            }

            let type = data.Desk.Type as BattleType;
            switch(type) {
            case BattleType.PVP:
                this._battle = new Battle(data.Desk);
                break;
            case BattleType.LEVEL:
                let levelBattle = new LevelBattle(data, data.LevelID);
                levelBattle.isBeginFight = true;
                this._battle = levelBattle;
                break;
            case BattleType.LevelHelp:
                let levelHelpBattle = new LevelHelpBattle(data, data.LevelID);
                levelHelpBattle.isBeginFight = true;
                this._battle = levelHelpBattle;
                break;
            /*
            case BattleType.CAMPAIGN:
            case BattleType.CAMPAIGN_DEF:
                this._battle = new CampaignBattle(data.Desk, type, data.CampaignType, data.CampaignLevel, data.FieldCnt);
                break;
            */
            case BattleType.Guide:
                 this._battle = new GuideBattle(data.Desk);
                 break;
            case BattleType.Friend:
                 this._battle = new FriendBattle(data.Desk);
                 break;
            case BattleType.Campaign:
                 this._battle = new CampaignBattle(data.Desk);
                 break;
            default:
                break;
            }
            if (!this._battle) {
                console.debug("restoredBattle error %d", type);
                return;
            }

            BoutActionPlayer.createInst();
            await Core.ViewManager.inst.close(ViewName.battle);
            await Core.ViewManager.inst.open(ViewName.battle, this._battle);
            //await BoutActionPlayer.inst.playActions(data.Effects, false);
            this._battle.restoredDone(data.CurBoutUid as Long, data.CurBout);
            Core.EventCenter.inst.dispatchEventWith(GameEvent.BattleBeginEv);
        }

        public async loadBattle(battleID:Long) {
            if (!battleID) {
                return;
            }

            let isIgnorePve = false;
            if (Core.DeviceUtils.isWXGame()) {
                isIgnorePve = WXGame.WXGameMgr.inst.hasLaunchActionToHandle();
            }
            let args = {
                IsIgnorePve: isIgnorePve
            }
            let result = await Net.rpcCall(pb.MessageID.C2S_LOAD_FIGHT, pb.C2SLoadFightArg.encode(args), true, false);
            if (result.errcode != 0 || !result.payload) {
                return;
            }
            await this.restoredBattle(pb.RestoredFightDesk.decode(result.payload));
        }

        public async levelBattleReadyDone() {
            if (this._battle && this._battle instanceof LevelBattle) {
                let ok = await (<LevelBattle>this._battle).levelBattleReadyDone();
                return ok;
            }
            return false;
        }

        public surrender() {
            Net.rpcPush(pb.MessageID.C2S_FIGHT_SURRENDER, null);
        }

        public gmWin() {
            Net.rpcPush(pb.MessageID.C2S_FIGHT_GM_WIN, null);
        }

        public async exitVideo() {
            await VideoPlayer.inst.stop();
            await Core.ViewManager.inst.close(ViewName.battle);
            Core.EventCenter.inst.dispatchEventWith(GameEvent.BattleEndEv);
            this._battle = null;
        }

        public async exitLevel() {
            await Core.ViewManager.inst.close(ViewName.battle);
            Level.LevelMgr.inst.onEnterLevel();
            this._battle = null;
        }

        public sendEmoji(emojiID:number) {
            if (!this._battle || !this._battle.isPvp()) {
                return;
            }
            
            let battleView = Core.ViewManager.inst.getView(ViewName.battle) as BattleView;
            if (!battleView.isShow() || !battleView.showSelfEmoji(emojiID)) {
                return;
            }

            Net.rpcPush(pb.MessageID.C2S_SEND_EMOJI, pb.SendEmojiArg.encode({EmojiID:emojiID}));
        }
    }

    function onLogout() {
        BattleMgr.inst.onLogout();
    }

    export function init() {
        initRpc();
        Player.inst.addEventListener(Player.LogoutEvt, onLogout, null);

        
        //fairygui.UIObjectFactory.setPackageItemExtension(fairygui.UIPackage.getItemURL(PkgName.common, "rewardResBar"), RewardResBar);


        let registerView = Core.ViewManager.inst.registerView.bind(Core.ViewManager.inst);
        let createObject = fairygui.UIPackage.createObject;
        registerView(ViewName.battle, () => {
            return createObject(PkgName.battle, ViewName.battle, BattleView);
        });

        registerView(ViewName.videoFunction, () => {
            return createObject(PkgName.battle, ViewName.videoFunction, VideoFunctionView);
        })

        registerView(ViewName.pvpVs, () => {
            return createObject(PkgName.battle, ViewName.pvpVs, PvpVsView);
        });
        
        //registerView(ViewName.emojiChoiceWnd, () => {
            let emojiChoiceContentPane = createObject(PkgName.battle, ViewName.emojiChoiceWnd).asCom;
            let emojiChoiceWnd = new EmojiChoiceWnd();
            emojiChoiceWnd.contentPane = emojiChoiceContentPane;
            Core.ViewManager.inst.register(ViewName.emojiChoiceWnd, emojiChoiceWnd);
            //return emojiChoiceWnd;
        //});
        
        registerView(ViewName.pvpNewBattleEnd, ()=> {
            return createObject(PkgName.battle, ViewName.pvpNewBattleEnd, PvpNewBattleEnd);
        })
        
        registerView(ViewName.levelNewBattleEnd, () => {
            return createObject(PkgName.battle, ViewName.levelNewBattleEnd, LevelNewBattleEnd);
        })
        
        registerView(ViewName.friendBattleEnd, () => {
            return createObject(PkgName.battle, ViewName.friendBattleEnd, FriendBattleEnd);
        });
        
        registerView(ViewName.bigCard, () => {
            return createObject(PkgName.cards, "bigCardView", CardBigWnd);
        });

        registerView(ViewName.cardDetail, () => {
            return createObject(PkgName.cards, "bigCard", CardDetailWnd);
        });

        registerView(ViewName.advertUpTreasureWnd, () => {
            let advertUpTreasureWnd = new AdvertUpTreasureWnd();
            advertUpTreasureWnd.contentPane = createObject(PkgName.common, ViewName.advertUpTreasureWnd).asCom;
            return advertUpTreasureWnd;
        })
    }

}