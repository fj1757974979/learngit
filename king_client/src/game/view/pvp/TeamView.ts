module Pvp {

	export class TeamView extends Core.BaseView{
		private _weiPoolList: CampPoolList;
        private _shuPoolList: CampPoolList;
        private _wuPoolList: CampPoolList;

        private _weiPoolClickWnd: fairygui.GLoader;
        private _shuPoolClickWnd: fairygui.GLoader;
        private _wuPoolClickWnd: fairygui.GLoader;

		private _fightCampCtrl: fairygui.Controller;
		private _renderPoolsExecutor: Core.FrameExecutor;
        private _curFightCamp: Camp;
        private _lastFightCamp: Camp;

		public initUI() {
            //this.height += Utils.getResolutionDistance();
			this._weiPoolList = new CampPoolList(this.getChild("weiPoolList").asList, this.getController("weiPoolCtrl"));
            this._shuPoolList = new CampPoolList(this.getChild("shuPoolList").asList, this.getController("shuPoolCtrl"));
            this._wuPoolList = new CampPoolList(this.getChild("wuPoolList").asList, this.getController("wuPoolCtrl"));
            this._fightCampCtrl = this.getController("campCtrl");

            this._weiPoolClickWnd = this.getChild("weiPoolClickWnd").asLoader;
            this._shuPoolClickWnd = this.getChild("shuPoolClickWnd").asLoader;
            this._wuPoolClickWnd = this.getChild("wuPoolClickWnd").asLoader;

			this.getChild("weiPrePoolBtn").asButton.addClickListener(this._onWeiPrePool, this);
            this.getChild("weiNextPoolBtn").asButton.addClickListener(this._onWeiNextPool, this);
            this.getChild("shuPrePoolBtn").asButton.addClickListener(this._onShuPrePool, this);
            this.getChild("shuNextPoolBtn").asButton.addClickListener(this._onShuNextPool, this);
            this.getChild("wuPrePoolBtn").asButton.addClickListener(this._onWuPrePool, this);
            this.getChild("wuNextPoolBtn").asButton.addClickListener(this._onWuNextPool, this);

			this._fightCampCtrl.addEventListener(fairygui.StateChangeEvent.CHANGED, this._onFightCampChanged, this);
			Core.EventCenter.inst.addEventListener(Core.Event.HomeListChangedEvt, this._onHomeListChanged, this);
            Core.EventCenter.inst.addEventListener(GameEvent.FightPoolUpdateCardEv, this._onFightPoolUpdateCard, this);
            
            this._weiPoolClickWnd.addClickListener(() => {
                this._weiPoolList.fireClick();
            }, this);

            this._shuPoolClickWnd.addClickListener(() => {
                this._shuPoolList.fireClick();
            }, this);

            this._wuPoolClickWnd.addClickListener(() => {
                this._wuPoolList.fireClick();
            }, this);
        }

		public async open(...param:any[]) {
            super.open(...param);
            this.refresh(...param);
        }

        public async refresh(...param:any[]) {            
            let fightCamp = param[0] as Camp;
            this._curFightCamp = fightCamp;
            this._lastFightCamp = fightCamp;
            let pools = param[1] as Collection.Dictionary<Camp, Array<FightCardPool>>;
            this._changeFightCampCtrl(fightCamp);

            this._renderPoolsExecutor = new Core.FrameExecutor();
            let _list = this._getPoolList(fightCamp);
            if (!_list) return;
            this._renderPoolsExecutor.regist(_list.refresh, _list, pools.getValue(fightCamp)); 
            for (let _camp of [Camp.WEI, Camp.SHU, Camp.WU]) {
                if (_camp != fightCamp) {
                    let __list = this._getPoolList(_camp);
                    this._renderPoolsExecutor.regist(__list.refresh, __list, pools.getValue(_camp)); 
                }
            }

            egret.callLater(()=>{ this._renderPoolsExecutor.execute(); }, this);

			this._updateFightCampAndPool();
        }

		public async close(...param:any[]) {
            super.close(...param);
            if (this._renderPoolsExecutor) {
                this._renderPoolsExecutor.cancel();
                this._renderPoolsExecutor = null;
            }
            this._weiPoolList.clear();
            this._shuPoolList.clear();
            this._wuPoolList.clear();
        }

		private _changeFightCampCtrl(camp:Camp) {
            switch(camp) {
            case Camp.WEI:
                this._fightCampCtrl.selectedIndex = 0;
                break;
            case Camp.SHU:
                this._fightCampCtrl.selectedIndex = 1;
                break;
            case Camp.WU:
                this._fightCampCtrl.selectedIndex = 2;
                break;
            default:
                return;
            }
        }

        private _onFightPoolUpdateCard(evt:egret.Event) {
            this._changeFightCampCtrl((<FightCardPool>evt.data).camp);
        }

        private _onFightCampChanged() {
            let fightCamp = this._getFightCamp();
            if (fightCamp != this._curFightCamp) {
                this._curFightCamp = fightCamp;
            }
            PvpMgr.inst.fightCamp = fightCamp;
        }

        private _getFightCamp(): Camp {
            switch(this._fightCampCtrl.selectedIndex) {
            case 0:
                return Camp.WEI;
            case 1:
                return Camp.SHU;
            case 2:
                return Camp.WU;
            default:
                return Camp.WEI;
            }
        }

        private _getPoolList(camp:Camp):CampPoolList {
            switch(camp) {
            case Camp.WEI:
                return this._weiPoolList;
            case Camp.SHU:
                return this._shuPoolList;
            case Camp.WU:
                return this._wuPoolList;
            default:
                return null;
            }
        }

        private _getFightPool(camp:Camp):FightCardPool {
            //let ctrl = this._getPoolCtrl(camp);
            let poolList = this._getPoolList(camp);
            return poolList.getCurFightPool();
            //let hand = poolList.getChildAt(ctrl.selectedIndex).asCom as UI.HandCardGrid;
            //return hand.dataProvider as FightCardPool;
        }

		private _prePool(camp:Camp) {
            this._getPoolList(camp).prePool();
        }

        private _nextPool(camp:Camp) {
            this._getPoolList(camp).nextPool();
        }

        private _onWeiPrePool() {
            this._prePool(Camp.WEI);
        }

        private _onWeiNextPool() {
            this._nextPool(Camp.WEI);
        }

        private _onShuPrePool() {
            this._prePool(Camp.SHU);
        }

        private _onShuNextPool() {
            this._nextPool(Camp.SHU);
        }

        private _onWuPrePool() {
            this._prePool(Camp.WU);
        }

        private _onWuNextPool() {
            this._nextPool(Camp.WU);
        }

		private _updateFightPool() {
            let modifyPool = [];
            [Camp.WEI, Camp.SHU, Camp.WU].forEach(camp => {
                let poolList = this._getPoolList(camp);
                let fightPool = this._getFightPool(camp);
                if (fightPool && (!poolList.oldfightPool || poolList.oldfightPool.id != fightPool.id)) {
                    modifyPool.push( {"PoolId":fightPool.id, "Camp":camp} );
                    poolList.oldfightPool = fightPool;
                }
            })

            if (modifyPool.length > 0 || this._curFightCamp != this._lastFightCamp) {
                this._lastFightCamp = this._curFightCamp;
                PvpMgr.inst.updateFightPool(modifyPool, this._curFightCamp);
            }
        }

		private _updateFightCampAndPool() {
			let camp = this._getFightCamp();
            let fightPool = this._getFightPool(camp);
            if (fightPool && camp) {
			    PvpMgr.inst.fightPool = fightPool;
			    PvpMgr.inst.fightCamp = camp;
            }
		}

		private _onHomeListChanged() {
			this._updateFightPool();
			this._updateFightCampAndPool();
		}
	}
}