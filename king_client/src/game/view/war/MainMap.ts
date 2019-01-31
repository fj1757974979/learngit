module War {
	
    export class MainMap extends Core.BaseView {

        // private _map: fairygui.GLoader;

        private _baseWidth: number;
        private _baseHeight: number;
		private _baseSX: number;
		private _baseSY: number;

		private _cityComList: Collection.Dictionary<number, CityCom>;
		private _myChar: Char;
		private _charList: Collection.Dictionary<number, Char>;
		private _mapList: Array<fairygui.GLoader>;

		private _dragDetector: Core.DragDetector = null;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._baseWidth = this.width;
			this._baseHeight = this.height;
        }

		public refreshAllCity() {
			this._cityComList.forEach((_key) => {
				this.refreshCity(_key);
			})
		}
		public refreshCity(cityID: number) {
			this._cityComList.getValue(cityID).refresh();
		}
		
		public initSize() {
			this._calcBaseScale();
			this._center();
		}

		public beginDragDetect() {
			if (this._dragDetector) {
				this._dragDetector.unregisterTouch(this);
			} else {
				this._dragDetector = new Core.DragDetector();
			}

			this._dragDetector.registerTouch(this, Core.DragDetector.T_ZOOM, {
				minScale: this._baseSX, maxScale: 1, 
				checkBoundCb: (x: number, y: number) => {
					return this._checkBound(x, y);
				},
				onDropCb: () => {
					this._checkObjOnScreen()
				}
			});
		}
		
		private _calcBaseScale() {
			let uiRoot = fairygui.GRoot.inst;
			let scaleX = (uiRoot.getDesignStageWidth() / this.width);
			let scaleY = (uiRoot.getDesignStageHeight() / this.height);
			let scale = scaleX > scaleY ? scaleX: scaleY;
			this._baseSX = scale;
			this._baseSY = scale;
		}

		private _center() {
			let x = 0;
			let y = 0;
			let myTeam = WarTeamMgr.inst.myTeam;
			if (myTeam && myTeam.char) {
				let uiRoot = fairygui.GRoot.inst;
				x = (-myTeam.char.x) * this.scaleX + uiRoot.getDesignStageWidth() / 2;
				y = (-myTeam.char.y) * this.scaleY + uiRoot.getDesignStageHeight() / 2;//50
			} else if (MyWarPlayer.inst.locationCityID == 0) {
				x = this.parent.width / 2 - (this.width * this.scaleX) / 2;
				y = this.parent.height / 2 - (this.height * this.scaleY) / 2;
			} else {
				let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
				if (city) {
					let uiRoot = fairygui.GRoot.inst;
					x = (-city.cityPoint.x) * this.scaleX + uiRoot.getDesignStageWidth() / 2;
					y = (-city.cityPoint.y) * this.scaleY + uiRoot.getDesignStageHeight() / 2;//50
				} else {
					x = this.parent.width / 2 - (this.width * this.scaleX) / 2;
					y = this.parent.height / 2 - (this.height * this.scaleY) / 2;
				}
			}
			let point = this._checkBound(x, y);
			this.x = point.x;
			this.y = point.y;
			this._checkObjOnScreen();
		}

		public moveCenter(city?: City) {
			if (city) {
				this._moveMap(city);
			} else if (MyWarPlayer.inst.cityID == 0) {
				let x = this.parent.width / 2 - (this.width * this.scaleX) / 2;
				let y = this.parent.height / 2 - (this.height * this.scaleY) / 2;
				let point = this._checkBound(x, y);
				egret.Tween.get(this,{ onChange:this._checkObjOnScreen, onChangeObj:this }).to({x: point.x, y: point.y}, 300, egret.Ease.backOut);
			} else {
				let mycity = CityMgr.inst.getCity(MyWarPlayer.inst.cityID);
				this._moveMap(mycity);
			}
		}
		private _moveMap(city: City) {
			let uiRoot = fairygui.GRoot.inst;
				let x = (-city.cityPoint.x -50) * this.scaleX + uiRoot.getDesignStageWidth() / 2;
				let y = (-city.cityPoint.y - 50) * this.scaleY + uiRoot.getDesignStageHeight() / 2;//50
				let point = this._checkBound(x, y);
				egret.Tween.get(this,{ onChange:this._checkObjOnScreen, onChangeObj:this }).to({x: point.x, y: point.y}, 300, egret.Ease.sineIn);
		}

		public destroyResMap() {
			for (let i = 1; i <= 18; i++) {
				RES.destroyRes(`war_map${i}_jpg`);
			}
		}

		public async loadResMap() {
			for (let i = 1; i <= 18; i++) {
				let mapCom = this.getChild(`map${i}`).asLoader;
				mapCom.texture = await this._getResMap(i);
			}
		}

		private async _getResMap (mapID: number) {
			return await RES.getResAsync(`war_map${mapID}_jpg`);
		}

        private _checkBound(fx: number, fy: number): {x: number, y: number} {
			let uiRoot = fairygui.GRoot.inst;
			let x = fx;
			if (uiRoot.getDesignStageWidth() == this.width * this.scaleX) {
				x = this.parent.width / 2 - (this.width * this.scaleX) / 2;
			} else {
				let minX = (this.parent.width - uiRoot.getDesignStageWidth()) / 2;
				x = Math.min(minX, x);
				x = Math.max(this.parent.width - this.width * this.scaleX - minX, x);
			}
			let y = fy;
			if (uiRoot.getDesignStageHeight() == this.height * this.scaleY) {
				y = this.parent.height / 2 - (this.height * this.scaleY) / 2;
			} else {
				let minY = (this.parent.height - uiRoot.getDesignStageHeight())/2
				y = Math.min(minY, y);
				y = Math.max(this.parent.height - this.height * this.scaleY - minY, y);
			}
			return {x: x, y: y};
		}

		private _checkObjOnScreen() {
			let uiRoot = fairygui.GRoot.inst;
			let screenWidth = uiRoot.getDesignStageWidth();
			let screenHeight = uiRoot.getDesignStageHeight();
			if (this._cityComList) {
				let diff = 50;
				this._cityComList.forEach((cityID, city) => {
					let cityPoint = city.localToGlobal(0,0);
					if (cityPoint.x < -diff || cityPoint.x > screenWidth + diff  || cityPoint.y < - diff || cityPoint.y > screenHeight + diff) {
						city.visible = false;
					} else {
						city.visible = true;
					}
				});
			}
			if (this._mapList) {
				let diff = 100;
				this._mapList.forEach((mapCom, index) => {
					let mapPoint = mapCom.localToGlobal(0, 0);
					let comW = mapCom.width * this.scaleX;
					let comH = mapCom.height * this.scaleY;
					if (mapPoint.x < -mapCom.width - diff || mapPoint.x > screenWidth + diff || mapPoint.y < - mapCom.height - diff || mapPoint.y > screenHeight + diff) {
					// if (mapPoint.x < -comW - diff || mapPoint.x > screenWidth + diff || mapPoint.y < -comH - diff || mapPoint.y > screenHeight + diff) {
						mapCom.visible = false;
					} else {
						mapCom.visible = true;
					}
				})
			}
		}

		public initUI() {
			super.initUI();
		}
		public async open(...param: any[]) {
			super.open(...param);
		}
		public async close(...param: any[]) {
			super.close(...param);
		}
    }
}
