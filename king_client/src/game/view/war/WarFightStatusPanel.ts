module War {
	export class WarFightStatusPanel extends fairygui.GComponent {

		private _quitBtn: fairygui.GButton;
		private _continueBtn: fairygui.GButton;
		private _cancelBtn: fairygui.GButton;
		private _contributionText: fairygui.GTextField;
		private _waitProgress: UI.MaskProgressBar;
		private _titleText: fairygui.GTextField;
		private _destCityText: fairygui.GTextField;
		private _foodText: fairygui.GTextField;
		private _statusCtrl: fairygui.Controller;

		protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

			this._quitBtn = this.getChild("quitBtn").asButton;
			this._cancelBtn = this.getChild("cancelBtn").asButton;
			this._continueBtn =this.getChild("continueBtn").asButton;
			// this._contributionText = this.getChild("zhanji").asTextField;
			this._waitProgress = this.getChild("shangyeProgress").asCom as UI.MaskProgressBar;
			// this._titleText = this.getChild("attackPlayerTxt1").asTextField;
			// this._destCityText = this.getChild("attackPlayerTxt2").asTextField;
			this._foodText = this.getChild("foodInput").asTextField;
			this._statusCtrl = this.getController("status");
			this._quitBtn.addClickListener(this._onQuitBtn, this);
			this._continueBtn.addClickListener(this._onContinueBtn, this);
			this._cancelBtn.addClickListener(this._onCancelBtn, this);
		}
		public watch() {
			MyWarPlayer.inst.watchProp(MyWarPlayer.PropForage, this._updateFood, this);
		}
		private _updateFood() {
			this._foodText.text = MyWarPlayer.inst.forage.toString();
		}
		public unwatch() {
			MyWarPlayer.inst.unwatchProp(MyWarPlayer.PropForage, this._updateFood, this);
		}
		public setTeamStatus(stName: number, ...param: any[]) {
			// if (stName == TeamStatusName.ST_NORMAL || stName == PlayerStatusName.ST_SUPPORT) {
			// 	this._statusCtrl.selectedIndex = 0;
			// 	let destCityId = param[0];
			// 	let city = CityMgr.inst.getCity(destCityId);
			// 	if (city) {
			// 		this._destCityText.text = Core.StringUtils.format("目标：【{0}】", city.cityName);
			// 	}
			// }
		}
		public closePanel() {
			this.visible = false;
		}
		public updateContinueStatus() {
			let team = WarTeamMgr.inst.myTeam;
			if (team) {
				this.visible = true;
				this._statusCtrl.selectedIndex = 5;
				this._foodText.text = MyWarPlayer.inst.forage.toString();
				let continueText = this.getChild("attackPlayerContinueTxt1").asTextField;
				if (team.inStatus(TeamStatusName.ST_CAN_ATT_CITY)) {
					continueText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70292));
				} else if (team.inStatus(TeamStatusName.ST_FIELD_BATTLE_END)) {
					continueText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70293));
				} else if (team.inStatus(TeamStatusName.ST_DEF_BATTLE_END)) {
					continueText.text = Core.StringUtils.format(Core.StringUtils.TEXT(70294));
				}
			}
		}
		public updateRectifyStatus(remainTime: number, maxTime: number) {
			this.visible = true;
			this._statusCtrl.selectedIndex = 4;
			this._foodText.text = MyWarPlayer.inst.forage.toString();
			this._waitProgress.getChild("text").asTextField.text = Core.StringUtils.format(Core.StringUtils.TEXT(70295), maxTime - remainTime, maxTime);
			this._waitProgress.setProgress(maxTime - remainTime, maxTime);
		}
		public updateExpeditionStatus() {
			if (!WarTeamMgr.inst.myTeam) {
				return;
			}
			this.visible = true;
			if (WarTeamMgr.inst.myTeam.isAttCity()) {
				this._statusCtrl.selectedIndex = 2;
				this._foodText.text = MyWarPlayer.inst.forage.toString();
				let city = CityMgr.inst.getCity(WarTeamMgr.inst.myTeam.toCityID);
				let textCom = this.getChild("attackCityTxt2").asTextField;
				textCom.text = Core.StringUtils.format(Core.StringUtils.TEXT(70296), city.cityName)
			} else {
				this._statusCtrl.selectedIndex = 1;
				this._foodText.text = MyWarPlayer.inst.forage.toString();
				let city = CityMgr.inst.getCity(WarTeamMgr.inst.myTeam.toCityID);
				let textCom = this.getChild("attackPlayerTxt2").asTextField;
				textCom.text = Core.StringUtils.format(Core.StringUtils.TEXT(70296), city.cityName)
			}
		}
		public updateAcctakCityStatus() {
			if (!WarTeamMgr.inst.myTeam) {
				return;
			}
			this.visible = true;
			this._statusCtrl.selectedIndex = 2;
			this._foodText.text = MyWarPlayer.inst.forage.toString();
			let city = CityMgr.inst.getCity(WarTeamMgr.inst.myTeam.toCityID);
			let textCom = this.getChild("attackCityTxt2").asTextField;
			textCom.text = Core.StringUtils.format(Core.StringUtils.TEXT(70296), city.cityName)

		}
		public updateSupportStatus() {
			if (!WarTeamMgr.inst.myTeam) {
				return;
			}
			let city = CityMgr.inst.getCity(WarTeamMgr.inst.myTeam.toCityID);
			if (city) {
				this.visible = true;
				this._statusCtrl.selectedIndex = 0;
				this._foodText.text = MyWarPlayer.inst.forage.toString();
				// this._titleText.text = Core.StringUtils.format("支援中……");
				let textCom = this.getChild("movePlayerTxt2").asTextField;
				textCom.text = Core.StringUtils.format(Core.StringUtils.TEXT(70296), city.cityName)
			}
			
		}
		public updateDefendStatus() {
			let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
			if (city) {
				this.visible = true;
				this._statusCtrl.selectedIndex = 3;
				this._foodText.text = MyWarPlayer.inst.forage.toString();
				let textCom = this.getChild("defenseCItyTxt2").asTextField;
				textCom.text = Core.StringUtils.format(Core.StringUtils.TEXT(70296), city.cityName)
			}	
		}
		private async _onContinueBtn() {
			let team = WarTeamMgr.inst.myTeam;
			if (team) {
				if (team.inStatus(TeamStatusName.ST_CAN_ATT_CITY)) {
					await Net.rpcCall(pb.MessageID.C2S_BEGIN_ATTACK_CITY, null);
				} else if (team.inStatus(TeamStatusName.ST_FIELD_BATTLE_END)) {
					await Net.rpcCall(pb.MessageID.C2S_MY_TEAM_MARCH, null);
				} else if (team.inStatus(TeamStatusName.ST_DEF_BATTLE_END)) {
					await Net.rpcCall(pb.MessageID.C2S_DEF_CITY, null);
				}
			}
			// this.closePanel();
		}

		private async _onQuitBtn() {
			let team = WarTeamMgr.inst.myTeam;
			if (team) {
				if (team.inStatus(TeamStatusName.ST_CAN_ATT_CITY)) {
					// await Net.rpcCall(pb.MessageID.C2S_MY_TEAM_RETREAT, null);
					this._onQuit();
				} else if (team.inStatus(TeamStatusName.ST_FIELD_BATTLE_END)) {
					// await Net.rpcCall(pb.MessageID.C2S_MY_TEAM_RETREAT, null);
					this._onQuit();
				} else if (team.inStatus(TeamStatusName.ST_DEF_BATTLE_END)) {
					// await Net.rpcCall(pb.MessageID.C2S_CANCEL_DEF_CITY, null);
					this._onCanelDefCity();
				}
			}
			// this.closePanel();
		}
		private async _onCancelBtn() {
			if (MyWarPlayer.inst.inStatus(PlayerStatusName.ST_DEFEND)) {
				Core.TipsUtils.confirm(Core.StringUtils.TEXT(70297), ()=> {
					this._onCanelDefCity();
				}, null, this);
			} else {
				Core.TipsUtils.confirm(Core.StringUtils.TEXT(70298), ()=> {
					this._onQuit();
				}, null, this);
			}
			
		}
		private async _onCanelDefCity() {
			let result = await Net.rpcCall(pb.MessageID.C2S_CANCEL_DEF_CITY, null);
			if (result.errcode == 0) {
				// Core.TipsUtils.alert(Core.StringUtils.format("放弃"));
				if (WarTeamMgr.inst.myTeam) {
					WarTeamMgr.inst.myTeam.changeStatus(TeamStatusName.ST_DISAPPEAR);
				}
				WarMgr.inst.warView.setCloseBtn(true);
				MyWarPlayer.inst.changeStatus(PlayerStatusName.ST_NORMAL);
			}
		}
		private async _onQuit() {
			let result = await Net.rpcCall(pb.MessageID.C2S_MY_TEAM_RETREAT, null);
			if (result.errcode == 0) {
				let reply = pb.TeamRetreat.decode(result.payload);
				if (reply.NewCity != reply.OldCity) {
					let oldCity = CityMgr.inst.getCity(reply.OldCity);
					let newCity = CityMgr.inst.getCity(reply.NewCity);
					if (oldCity && newCity) {
						Core.TipsUtils.alert(Core.StringUtils.format(Core.StringUtils.TEXT(70299), oldCity.cityName, newCity.cityName));
					}
				} else {
					let city = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
					if (city) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70300), city.cityName))
					}
				}
				if (WarTeamMgr.inst.myTeam) {
					WarTeamMgr.inst.myTeam.changeStatus(TeamStatusName.ST_DISAPPEAR);
				}
				WarMgr.inst.warView.setCloseBtn(true);
				MyWarPlayer.inst.changeStatus(PlayerStatusName.ST_NORMAL);
			}
		}
		

	}
}