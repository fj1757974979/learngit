module Social {

	class ApplyItemCom extends fairygui.GComponent {

		private _headCom: Social.HeadCom;
		private _nameText: fairygui.GTextField;
		private _rankTitleText: fairygui.GTextField;
		private _rankImg: fairygui.GLoader;
		private _agreeBtn: fairygui.GButton;
		private _refuseBtn: fairygui.GButton;
		private _bg: fairygui.GLoader;

		private _host: FriendApplyWnd;
		private _info: pb.FriendApply;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._headCom = this.getChild("head").asCom as Social.HeadCom;
			this._nameText = this.getChild("nameText").asTextField;
			this._nameText.textParser = Core.StringUtils.parseColorText;
			this._rankImg = this.getChild("rankImg").asLoader;
			this._rankTitleText = this.getChild("rankTitleText").asTextField;
			this._agreeBtn = this.getChild("agreeBtn").asButton;
			this._refuseBtn = this.getChild("refuseBtn").asButton;
			this._bg = this.getChild("bg").asLoader;

			this._agreeBtn.addClickListener(this._onAgree, this);
			this._refuseBtn.addClickListener(this._onRefuse, this);

			this._bg.addClickListener(this._onDetail, this);

			if (window.gameGlobal.isMultiLan) {
				this._rankTitleText.fontSize = 12;
			}
		}

		public setApplyInfo(info: pb.FriendApply, host: FriendApplyWnd) {
			this._info = info;
			this._host = host;
			if (!info.HeadFrame && info.HeadFrame == "") {
				info.HeadFrame = "1";
			}
			this._headCom.setAll(info.HeadImgUrl, `headframe_${info.HeadFrame}_png`);
			this._nameText.text = info.Name;
			let pvpScore = info.PvpScore;
			let pvpLevel = Pvp.PvpMgr.inst.getPvpLevel(pvpScore);
			this._rankTitleText.text = Pvp.Config.inst.getPvpTitle(pvpLevel);
			let team = Pvp.Config.inst.getPvpTeam(pvpLevel);
			this._rankImg.url = `common_rank${team}_png`;
		}

		private async _onAgree() {
			if (await FriendMgr.inst.replyAddFriendApply(<Long>this._info.Uid, true)) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60137));
				Core.EventCenter.inst.dispatchEventWith(GameEvent.AddFriend, false, "");

				// 发私聊
				let text = Core.StringUtils.TEXT(60197);
				let chatlets = await ChatMgr.inst.sendPrivateChat(<Long>this._info.Uid, this._info.Name, this._info.HeadImgUrl, text);
			} else {
			}
			this._host.delApplyItem(this);
		}

		private async _onRefuse() {
			if (await FriendMgr.inst.replyAddFriendApply(<Long>this._info.Uid, false)) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60138));
			} else {
			}
			this._host.delApplyItem(this);
		}

		private async _onDetail() {
				let playerInfo = await FriendMgr.inst.fetchPlayerInfo(<Long>this._info.Uid);
				if (playerInfo) {
					Core.ViewManager.inst.open(ViewName.friendInfo, <Long>this._info.Uid, playerInfo);
				}
			}

	}

	export class FriendApplyWnd extends Core.BaseWindow {
		
		private _applyList: fairygui.GList;
		private _closeBtn: fairygui.GButton;

		public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

			this._applyList = this.contentPane.getChild("applyList").asList;
			this._closeBtn = this.contentPane.getChild("closeBtn").asButton;

			this._closeBtn.addClickListener(this._onClose, this);
		}		

		public async open(...param: any[]) {
			super.open(...param);
			let applyList = await FriendMgr.inst.fetchAddFriendApplies();
			if (applyList && applyList.FriendApplys && applyList.FriendApplys.length > 0) {
				this.contentPane.getChild("emptyHintText").visible = false;
				applyList.FriendApplys.forEach(info => {
					let item = fairygui.UIPackage.createObject(PkgName.social, "friendApplyItem", ApplyItemCom).asCom as ApplyItemCom;
					item.setApplyInfo(<pb.FriendApply>info, this);
					this._applyList.addChild(item);
				});
			} else {
				this.contentPane.getChild("emptyHintText").visible = true;
			}
		}

		public delApplyItem(item: ApplyItemCom) {
			this._applyList.removeChild(item);
			let applyNum = FriendMgr.inst.applyNum;
			FriendMgr.inst.applyNum = Math.max(0, applyNum - 1);
		}

		public async close(...param: any[]) {
			super.close(...param);
			this._applyList.removeChildren();
		}

		private _onClose() {
			Core.ViewManager.inst.closeView(this);
		}
	}
}