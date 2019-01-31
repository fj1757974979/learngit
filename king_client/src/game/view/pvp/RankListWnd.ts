module Pvp {
	export class BaseRankPlayerInfoCom extends fairygui.GComponent {

		protected _orderText: fairygui.GTextField;
		protected _changeText: fairygui.GTextField;
		protected _campImg: fairygui.GLoader;
		protected _nameText: fairygui.GTextField;
		protected _bg: fairygui.GLoader;
		protected _scoreTextBg: fairygui.GLoader;

		protected _uid: Long;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._orderText = this.getChild("orderText").asTextField;
			this._changeText = this.getChild("rankChangeText").asTextField;
			this._campImg = this.getChild("campImg").asLoader;
			this._nameText = this.getChild("nameText").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._bg = this.getChild("bg").asLoader;
			this._scoreTextBg = this.getChild("scoreImg").asLoader;

			this._uid = null;
		}

		protected clearContent() {
			this._orderText.text = "-";
			this._changeText.text = "-";
			this._campImg.visible = false;
			this._nameText.text = Core.StringUtils.TEXT(60071);
		}
		protected refreshBase(rank: number, lastRank: number, uid: Long, name: string, camp: Camp) {
			this._uid = uid;
			if (rank <= 3) {
				this._orderText.fontSize = 40;
				if (rank == 1) {
					//this._bg.color = 0xffcc00;
					this._scoreTextBg.url = "pvp_ranking1_png";
				} else if (rank == 2) {
					//this._bg.color = 0xff99ff;
					this._scoreTextBg.url = "pvp_ranking2_png";
				} else {
					//this._bg.color = 0x66ffff;
					this._scoreTextBg.url = "pvp_ranking3_png";
				}
			} else {
				this._orderText.fontSize = 24;
				//this._bg.color = 0xffffff;
				this._scoreTextBg.url = "pvp_rankingMore_png";
			}
			if (this._uid == Player.inst.uid) {
				this._bg.color = 0xffffff;
			}
			this._orderText.text = `${rank}`;
			this._changeText.visible = true;
			if (lastRank == -1) {
				this._changeText.visible = false;
			} else if (lastRank == 0) {
				this._changeText.text = "";
				this._changeText.color = 0x0c7114;
			} else if (rank > lastRank) {
				this._changeText.text = `${rank - lastRank}`;
				this._changeText.color = 0x8a140b;
			} else if (rank == lastRank) {
				this._changeText.text = "";
				this._changeText.color = 0x000000;
			} else {
				this._changeText.text = `${lastRank - rank}`;
				this._changeText.color = 0x0c7114;
			}
			this._nameText.text = name;
			this._campImg.visible = true;
			if (camp == Camp.WEI) {
				this._campImg.url = "guide_wei_png";
			} else if (camp == Camp.SHU) {
				this._campImg.url = "guide_shu_png";
			} else {
				this._campImg.url = "guide_wu_png";
			}
		}

		protected async fetchAndShowDetail(view: Core.BaseWindow) {
			console.debug(`${this._uid}`);
			if (this._uid != null) {
				let reply = await Net.rpcCall(pb.MessageID.C2S_FETCH_RANK_USER, pb.FetchRankUserArg.encode({"Uid":this._uid}));
				if (reply.errcode == 0) {
					let result = pb.RankUser.decode(reply.payload);
					let gcardIds: Array<pb.ISkinGCard> = [];
					result.FightCards.forEach(gcardId => {
						gcardIds.push(gcardId);
					});
					// console.debug(`${gcardIds.toString()}`);

					let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(this._uid);
					if (playerInfo) {
						Core.ViewManager.inst.open(ViewName.friendInfo, this._uid, playerInfo);
					}
				}
			}
		}
	}
	export class RankPlayerInfoCom extends BaseRankPlayerInfoCom {


		private _rankImg: fairygui.GLoader;
		private _rankTitleText: fairygui.GTextField;
		private _scoreText: fairygui.GTextField;

		private _friend: Social.Friend;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._rankImg = this.getChild("rankImg").asLoader;
			this._rankTitleText = this.getChild("rankTitleText").asTextField;
			this._scoreText = this.getChild("scoreText").asTextField;

			if (window.gameGlobal.isMultiLan) {
				this._rankTitleText.fontSize = 12;
			}
			this.clearContent();
		}

		public clearContent() {
			this.displayObject.cacheAsBitmap = false;
			super.clearContent();
			this._rankImg.visible = false;
			this._rankTitleText.text = "";
			this._scoreText.text = "-";
			this.displayObject.cacheAsBitmap = true;
		}

		private _refresh(rank: number, lastRank: number, uid:Long, name: string, score: number, camp: Camp) {
			this.displayObject.cacheAsBitmap = false;
			super.refreshBase(rank, lastRank, uid, name, camp);

			this._scoreText.text = `${PvpMgr.inst.getPvpStarCnt(score)}`;
			let pvpLevel = PvpMgr.inst.getPvpLevel(score);
            this._rankTitleText.text = Config.inst.getPvpTitle(pvpLevel);

			this._rankImg.visible = true;
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this._rankImg.url = `common_rank${team}_png`;

			this.displayObject.cacheAsBitmap = true;
		}

		public refresh(data: pb.RankItem) {
			let uid = <Long>data.Uid;
			let rank = data.Rank;
			let lastRank = data.LastRank;
			let name = data.Name;
			let score = data.PvpScore;
			let camp = data.Camp;
			this._refresh(rank, lastRank, uid, name, score, camp);
		}

		public refreshByData(data: any, rank: number) {
			let uid = data.uid;
			let name = data.name;
			let score = data.score;
			let camp = data.camp;
			this._refresh(rank, -1, uid, name, score, camp);
		}

		public async fetchAndShowDetail(view: Core.BaseWindow) {
			super.fetchAndShowDetail(view);
		}
	}

	export class SeasonRankPlayerInfoCom extends BaseRankPlayerInfoCom {

		private _starCnt: fairygui.GTextField;
		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);
			this._starCnt = this.getChild("cnt").asTextField;

		}

		public clearContent() {
			this.displayObject.cacheAsBitmap = false;
			super.clearContent();
			this._starCnt.text = "";
			this.displayObject.cacheAsBitmap = true;
		}
		private _refresh(rank: number, lastRank: number, uid:Long, name: string, score: number, camp: Camp) {
			this.displayObject.cacheAsBitmap = false;
			super.refreshBase(rank, lastRank, uid, name, camp);
			this._starCnt.text = `${score}`;
			this.displayObject.cacheAsBitmap = true;
		}
		public refresh(data: pb.RankItem) {
			let uid = <Long>data.Uid;
			let rank = data.Rank;
			let lastRank = data.LastRank;
			let name = data.Name;
			let score = data.WinDiff;
			let camp = data.Camp;
			this._refresh(rank, lastRank, uid, name, score, camp);
		}

		public async fetchAndShowDetail(view: Core.BaseWindow) {
			super.fetchAndShowDetail(view);
		}

	}

	export class RankListWnd extends Core.BaseWindow {

		private _updateTimeText: fairygui.GTextField;
		private _rankList: fairygui.GList;
		private _friendList: fairygui.GList;
		private _seasonRankList: fairygui.GList;
		private _selfInfo: RankPlayerInfoCom;
		private _worldRankBtn: fairygui.GButton;
		private _friendRankBtn: fairygui.GButton;
		private _rankSeasonBtn: fairygui.GButton;
		private _selfSeasonCom: SeasonRankPlayerInfoCom;

		private _initialized: boolean;
		private _rankInfo: any; //pb.RankInfo;
		private _seasonRankInfo: any; // pb.RankInfo;
		private _selfWorldRankinfo: pb.RankItem;
		private _selfSeasonRankInfo:pb.RankItem;
		private _friendInfo: Array<any>;

		public initUI() {
			super.initUI();
			this.adjust(this.contentPane.getChild("panel"), Core.AdjustType.EXCEPT_MARGIN);
			this.modal = true;
			this._initialized = false;
			this.center();
			this.y += window.support.topMargin/2;

			this._updateTimeText = this.contentPane.getChild("updateTime").asTextField;
			this._rankList = this.contentPane.getChild("rankList").asList;
			this._friendList = this.contentPane.getChild("friendList").asList;
			this._seasonRankList = this.contentPane.getChild("rankSeasonList").asList;
			this._selfInfo = this.contentPane.getChild("selfInfo").asCom as RankPlayerInfoCom;
			this._selfSeasonCom = this.contentPane.getChild("selfInfoRankSeason").asCom as SeasonRankPlayerInfoCom;
			this._selfInfo.clearContent();
			this._selfSeasonCom.clearContent();

			this.contentPane.getChild("closeBtn").asButton.addClickListener(this._onClickClose, this);
			this._rankList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickItem, this);
			this._friendList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickItem, this);
			this._seasonRankList.addEventListener(fairygui.ItemEvent.CLICK, this._onClickItem, this);

			this._rankList.itemClass = RankPlayerInfoCom;
			this._rankList.itemRenderer = this._renderWorldRank;
			this._rankList.callbackThisObj = this;
			this._rankList.setVirtual();

			this._seasonRankList.itemClass = SeasonRankPlayerInfoCom;
			this._seasonRankList.itemRenderer = this._renderSeasonRank;
			this._seasonRankList.callbackThisObj = this;
			this._seasonRankList.setVirtual();

			this._friendList.itemClass = RankPlayerInfoCom;
			this._friendList.itemRenderer = this._renderFriendRank;
			this._friendList.callbackThisObj = this;
			this._friendList.setVirtual();

			this._worldRankBtn = this.contentPane.getChild("worldChk").asButton;
			this._friendRankBtn = this.contentPane.getChild("friendChk").asButton;
			this._rankSeasonBtn = this.contentPane.getChild("rankSeasonChk").asButton;

			this._friendRankBtn.addClickListener(() => {
				this.initFriendList();
			}, this);

			this._worldRankBtn.addClickListener(() => {
				this.initWorldList();
			}, this);

			this._rankSeasonBtn.addClickListener(() => {
				this.initSeasonRankList();
			}, this);

			this._rankInfo = null;
			this._seasonRankInfo =null;
			this._friendInfo = null;
			this._selfWorldRankinfo = null;

			if (!LanguageMgr.inst.isChineseLocale()) {
				this.contentPane.getChild("updateTxt").asTextField.align = fairygui.AlignType.Center;
				this.contentPane.getChild("updateTxt2").asTextField.align = fairygui.AlignType.Center;
			}

			this._rankSeasonBtn.visible = Home.FunctionMgr.inst.isRankSeasonOpen();
		}

		public async open(...param: any[]) {
			super.open(...param);
			this.initWorldList();
			this.contentPane.getController("switch").selectedIndex = 0;
			Core.ViewManager.inst.getView(ViewName.newHome).setVisible(false);
		}

		public async initFriendList() {
			this._friendList.numItems = 0;
			this._selfInfo.clearContent();
			let result = await Social.FriendMgr.inst.fetchFriendList();
			let allData = [];
			if (result && result.friends != null) {
				result.friends.forEach(friend => {
					allData.push(friend.toData());
				});
			}
			allData.push({
				uid: Player.inst.uid,
				name: Player.inst.name,
				score: Player.inst.getResource(ResType.T_SCORE),
				camp: PvpMgr.inst.fightCamp,
				rebornCnt: Player.inst.rebornCnt,
			});
			allData = allData.sort((d1, d2) => {
				if (d1.rebornCnt > d2.rebornCnt) {
							return -1;
						} else if (d1.rebornCnt < d2.rebornCnt) {
							return 1;
						} else {
							if (d1.score > d2.score) {
								return -1;
							} else {
								return 1;
							}
						}
			});
			this._friendInfo = allData;
			this._friendList.numItems = this._friendInfo.length;
		}

		public async initWorldList() {
			let date = new Date();
            let day = date.getDate();

			this._rankList.numItems = 0;

			if (!this._rankInfo || PvpMgr.inst.pvpRankNeedRefresh) {
				let reply = await Net.rpcCall(pb.MessageID.C2S_FETCH_RANK, null);
				if (reply.errcode == 0) {
					let result = pb.RankInfo.decode(reply.payload);
					this._rankInfo = result;
					PvpMgr.inst.pvpRankNeedRefresh = false;
				} else {
					return
				}
			}

			this._selfInfo.clearContent();
			this._updateTimeText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60091), Core.StringUtils.secToDate(this._rankInfo.UpdateTime, "mdh"));
			this._rankList.numItems = this._rankInfo.Items.length;
		}

		public async initSeasonRankList() {
			this._seasonRankList.numItems = 0;
			if (!this._seasonRankInfo || PvpMgr.inst.pvpSeasonRankNeedRefresh) {
				let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_SEASON_RANK, null);
				if (result.errcode == 0) {
					let reply = pb.RankInfo.decode(result.payload);
					this._seasonRankInfo = reply;
					
					PvpMgr.inst.pvpSeasonRankNeedRefresh = false;
				} else {
					return;
				}
			}
			this._selfSeasonCom.clearContent();
			this._seasonRankList.numItems = this._seasonRankInfo.Items.length;
		}

		private _renderWorldRank(idx:number, item:fairygui.GObject) {
			let data = <pb.RankItem>this._rankInfo.Items[idx];
			let com = item as RankPlayerInfoCom;
			com.refresh(data);
			if (data.Uid == Player.inst.uid) {
				this._selfInfo.refresh(data);
			}
		}

		private _renderSeasonRank(idx:number, item: fairygui.GObject) {
			let data = <pb.RankItem>this._seasonRankInfo.Items[idx];
			let com = item as SeasonRankPlayerInfoCom;
			com.refresh(data);
			if (data.Uid == Player.inst.uid) {
				this._selfSeasonCom.refresh(data);
			}
		}

		private _renderFriendRank(idx: number, item: fairygui.GObject) {
			let data = this._friendInfo[idx];
			let rank = idx + 1;
			let com = item as RankPlayerInfoCom;
			com.refreshByData(data, rank);
			if (data.uid == Player.inst.uid) {
				this._selfInfo.refreshByData(data, rank);
			}
		}

		public get initialized(): boolean {
			return this._initialized;
		}

		public set initialized(b: boolean) {
			this._initialized = b;
		}

		private _onClickClose() {
			Core.ViewManager.inst.closeView(this);
		}

		private async _onClickItem(evt:fairygui.ItemEvent) {
			// console.debug("=---------- _onClickItem");
			let rankItem = evt.itemObject as RankPlayerInfoCom;
			await rankItem.fetchAndShowDetail(this);
			//this.hide();
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._rankList.numItems = 0;
			this._seasonRankList.numItems = 0;
			this._friendList.numItems = 0;
			this._friendInfo = null;
			Core.ViewManager.inst.getView(ViewName.newHome).setVisible(true);

		}
	}
}
