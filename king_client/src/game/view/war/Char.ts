module War {

	export class CharType {
		public static T_CALVERY = 0;
		public static T_BOAT = 1;
		public static T_TROOPS = 2;

		public static getAllType() {
			return [CharType.T_CALVERY, CharType.T_BOAT, CharType.T_TROOPS];
		}
	}

	export class CharDir {
		public static UP = 0;
		public static RIGHT_UP = 1;
		public static RIGHT = 2;
		public static RIGHT_DOWN = 3;
		public static DOWN = 4;
		public static LEFT_DOWN = 5;
		public static LEFT = 6;
		public static LEFT_UP = 7;

		public static MAX_DIR_NUM = 8;

		public static getAllDirs() {
			return [CharDir.UP, CharDir.RIGHT_UP, CharDir.RIGHT, CharDir.RIGHT_DOWN, CharDir.DOWN, CharDir.LEFT_DOWN, CharDir.LEFT, CharDir.LEFT_UP];
		}

		public static getResSupportDirs() {
			return [CharDir.UP, CharDir.RIGHT_UP, CharDir.RIGHT, CharDir.RIGHT_DOWN, CharDir.DOWN];
		}
	}

    export class Char {

        // private _type: CharType;
		protected _x: number;
		protected _y: number;

        protected _charCom: fairygui.GComponent;
        protected _parent: fairygui.GComponent;
        protected _speed: number;
        protected _designedPath: Array<Array<{x:number, y:number}>>;
		protected _curEff: fairygui.GMovieClip;
		protected _dir: CharDir;
		protected _dirCtrl: fairygui.Controller;
		protected _attCtrl: fairygui.Controller;
		protected _isMoving: boolean;
		protected _dirty: boolean;
		protected _charType: CharType;
		protected _countryFlagCom: CampIconCom;
		protected _fightAni: fairygui.Transition;
		protected _amountText: fairygui.GTextField;
		protected _headCom: Social.HeadCom;

		protected _effId2ECEffect: Collection.Dictionary<string, Core.EMovieClip>;

		protected _curECEff: Core.EMovieClip;
		protected _shootEff: Core.EMovieClip;

        public constructor(parent: fairygui.GComponent, type: CharType) {
			this._parent = parent;
            this._designedPath = new Array<Array<{x:number, y:number}>>();
            this._x = 0;
            this._y = 0;
            this._speed = 50;
			this._dir = CharDir.RIGHT;
			this._isMoving = false;
			this._dirty = false;
			this._charType = -1;
			this._countryFlagCom = null;
			this._fightAni = null;
			this._dir = -1;

			this._curECEff = null;

			this._effId2ECEffect = new Collection.Dictionary<string, Core.EMovieClip>();
			this._shootEff = Core.MCFactory.inst.getMovieClip("shoot", "shoot");
			this._shootEff.scaleX = 3/5;
			this._shootEff.scaleY = 3/5;
			this._shootEff.setPivot(0, this._shootEff.height/2, true);
			this.updateCharType(type);
        }

		public updateAmount(amount: number) {
			if (this._amountText) {
				if (amount > 0) {
					this._amountText.text = `x${amount}`;
				} else {
					this._amountText.text = "";
				}
			}
		}

		public updateCharType(type: CharType) {
			if (this._charType == type) {
				return;
			}
			this._charType = type;
			if (this._charCom) {
				// this._parent.removeChild(this._charCom, true);
				// this._charCom = null;
				// this._curEff = null;
				this._destroyCharCom();
				if (this._shootEff.parent) {
					this._shootEff.parent.removeChild(this._shootEff);
				}
			}
			
			this._charCom = fairygui.UIPackage.createObject(PkgName.war, "troops").asCom;
			this._charCom.touchable = false;
			this._dirCtrl = this._charCom.getController("dir");
			this._attCtrl = this._charCom.getController("attacking");
			this._countryFlagCom = this._charCom.getChild("flag").asCom as CampIconCom;
			//this._countryFlagCom.getChild("campName").y = this._countryFlagCom.getChild("campName").y - 5;
			this._fightAni = this._charCom.getTransition("t0");
			this._amountText = this._charCom.getChild("amount").asTextField;
			this._headCom = this._charCom.getChild("head").asCom as Social.HeadCom;
			this._parent.addChild(this._charCom);
			this._charCom.addChild(this._shootEff);
			this._shootEff.x = this._charCom.width/2
			this._shootEff.y = this._charCom.height/2;
			this._shootEff.visible = false;
			this._shootEff.stop();
			this._charType = type;
			if (this._dir > 0) {
				this._dirty = true;
				this._curEff = null;
				this._curECEff = null;
				this._onDirChange();
			}
			console.log("char.updateCharType ", type);
		}

		public updateCountry(country: Country) {
			if (this._countryFlagCom) {
				this._countryFlagCom.setCamp(country);
				this._countryFlagCom.getChild("campName").asTextField.fontSize = 12;
			}
		}

		public showMyHead(b: boolean) {
			this._headCom.visible = b;
			if (b) {
				this._headCom.setHead(Player.inst.avatarUrl);
            	this._headCom.setFrame(Player.inst.frameUrl);
			}
		}

        protected async _runTo(x: number, y: number) {
			let dis = Math.sqrt(Math.pow((this._x - x), 2) + Math.pow((this._y - y), 2));
			let time = Math.ceil(dis / this._speed);
            //修改朝向
			this.dir = this.calcDir({x:this._x, y:this._y}, {x:x, y:y});
			console.debug(`runTo distance=${dis}, time=${time}`);
			await new Promise<void>(resolve => {
				egret.Tween.get(this).to({x:x, y:y}, time).call(()=>{
                    resolve();
                }, this);
			});
		}

		public calcDir(from: {x: number, y: number}, to: {x: number, y: number}): CharDir {
			let fx = from.x;
			let fy = from.y;
			let tx = to.x;
			let ty = to.y;
			let PI = Math.PI;
			let angel = (Math.atan2(ty - fy, tx - fx) + 2*PI) % (2*PI);
			if (angel >= 0 && angel < PI/8) {
				return CharDir.RIGHT;
			} else if (angel >= PI/8 && angel < PI*3/8) {
				return CharDir.RIGHT_DOWN;
			} else if (angel >= PI*3/8 && angel < PI*5/8) {
				return CharDir.DOWN;
			} else if (angel >= PI*5/8 && angel < PI*7/8) {
				return CharDir.LEFT_DOWN;
			} else if (angel >= PI*7/8 && angel < PI*9/8) {
				return CharDir.LEFT;
			} else if (angel >= PI*9/8 && angel < PI*11/8) {
				return CharDir.LEFT_UP;
			} else if (angel >= PI*11/8 && angel < PI*13/8) {
				return CharDir.UP;
			} else if (angel >= PI*13/8 && angel < PI*15/8) {
				return CharDir.RIGHT_UP
			} else {
				return CharDir.RIGHT;
			}
		}

		public async moveAlongPath(path: Array<{x:number, y:number}>) {
			this._designedPath.push(path);
			if (!this._isMoving) {
				this._isMoving = true;
			}
			await this._doMoveAlongPath();
		}

		protected async _doMoveAlongPath() {
			// this.action = Action.RUN;
			let path = this._designedPath[0];
			if (path) {
				this._designedPath.splice(0, 1);
				for (let point of path) {
					await this._runTo(point.x, point.y);
				}
				await this._doMoveAlongPath();
			}
		}

		public get isMoving(): boolean {
			return this._isMoving;
		}

		public pause() {
			egret.Tween.pauseTweens(this);
		}

		public resume() {
			egret.Tween.resumeTweens(this);
		}
        
        public addToParent(parent: fairygui.GComponent) {
			if (this._parent && this._charCom) {
				this._parent.removeChild(this._charCom);
			}
			this._parent = parent;
			if (this._parent && this._charCom) {
				this._parent.addChild(this._charCom);
			}
		}

		public removeFromParent() {
			if (this._parent && this._charCom) {
				this._parent.removeChild(this._charCom);
			}
			this._parent = null;
		}

        public get charCom() {
            return this._charCom;
        }

        public set speed(num: number) {
            this._speed = num;
        }
		
        public get x(): number {
			return this._x;
		}

		public set x(x: number) {
			this._x = x;
			if (this._charCom) {
				this._charCom.x = this._x;
			}
		}

		public get y(): number {
			return this._y;
		}

		public set y(y: number) {
			this._y = y;
			if (this._charCom) {
				this._charCom.y = this._y;
			}
		}

		public get dir(): CharDir {
			return this._dir;
		}

		protected _doSetDir(dir: CharDir) {
			if (dir != this._dir) {
				this._dirty = true;
			}
			this._dir = dir;
			this._onDirChange();
		}

		public set dir(dir: CharDir) {
			if (this._isMoving) {
				fairygui.GTimers.inst.remove(this._doSetDir, this);
				fairygui.GTimers.inst.add(100, 1, this._doSetDir, this, dir);
			} else {
				this._doSetDir(dir);
			}
		}

		protected _getEffectIdPrefix() {
			if (this._charType == CharType.T_BOAT) {
				return "boat";
			} else {
				return "troop";
			}
		}

		protected _onDirChange() {
			let dir = <number>this._dir;
			if (dir > CharDir.DOWN) {
				dir = CharDir.MAX_DIR_NUM - dir;
			}
			let effId = `${this._getEffectIdPrefix()}${dir}`;
			if (!this._dirty) {
				return;
			}
			if (this._curECEff) {
				this._curECEff.gotoAndStop(1);
				this._curECEff.visible = false;
			}
			if (this._effId2ECEffect.containsKey(effId)) {
				this._curECEff = this._effId2ECEffect.getValue(effId);
			} else {
				this._curECEff = Core.MCFactory.inst.getMovieClip(effId, effId);
				this._effId2ECEffect.setValue(effId, this._curECEff);
			}
			this._curECEff.touchable = false;
			this._curECEff.visible = true;
			if (this._curECEff) {
				// this._curECEff.width = this._charCom.width;
				// this._curECEff.height = this._charCom.height;
				this._curECEff.scaleX = 3/5;
				this._curECEff.scaleY = 3/5;
				this._curECEff.setPivot(this._curECEff.width / 2, this._curECEff.height / 2, true);
				if (this._dir > CharDir.DOWN) {
					this._curECEff.scaleX = -1 * Math.abs(this._curECEff.scaleX);
					this._curECEff.x = this._curECEff.width * Math.abs(this._curECEff.scaleX) + this._charCom.width / 2;
				} else {
					this._curECEff.scaleX = Math.abs(this._curECEff.scaleX);
					this._curECEff.x = this._charCom.width / 2;
				}
				this._curECEff.y = this._charCom.height / 2;
				this._charCom.addChild(this._curECEff);
				this._curECEff.gotoAndPlay(1, -1);
			} else {
				console.log("can't find ec effect ", effId);
			}
			this._dirty = false;
		}

		protected _onDirChange2() {
			let dir = <number>this._dir;
			if (dir > CharDir.DOWN) {
				dir = CharDir.MAX_DIR_NUM - dir;
			}
			let eff = this._charCom.getChild(`${dir}`).asMovieClip;
			if (eff == this._curEff && !this._dirty) {
				return;
			}
			this._dirCtrl.setSelectedIndex(dir);
			// if (this._curEff) {
			// 	this._curEff.visible = false;
			// }
			this._curEff = eff;
			if (this._curEff) {
				// this._curEff.visible = true;
				if (this._dir > CharDir.DOWN) {
					this._curEff.scaleX = -1 * Math.abs(this._curEff.scaleX);
					this._curEff.x = this._curEff.width * Math.abs(this._curEff.scaleX);
				} else {
					this._curEff.scaleX = Math.abs(this._curEff.scaleX);
					this._curEff.x = 0;
				}
				this._curEff.y = 0;
			}
			this._dirty = false;
		}

		public setInAttCityMode(b: boolean, team?: WarTeam) {
			if (this._attCtrl) {
				if (b) {
					this._attCtrl.setSelectedIndex(1);
					if (team) {
						let toCityId = team.toCityID;
						let city = CityMgr.inst.getCity(toCityId);
						if (city) {
							if (this._shootEff) {
								this._shootEff.visible = true;
								this._shootEff.gotoAndPlay(1, -1);
								let tx = city.cityPoint.x;
								let ty = city.cityPoint.y;
								let fx = this.x;
								let fy = this.y;
								let angel = (Math.atan2(ty - fy, tx - fx) + 2*Math.PI) % (2*Math.PI);
								this._shootEff.rotation = angel * (180/Math.PI);
							}
							// if (this._charCom.getChild("arrow")) {
							// 	let attImg = this._charCom.getChild("arrow").asMovieClip;
							// 	let tx = city.cityPoint.x;
							// 	let ty = city.cityPoint.y;
							// 	let fx = this.x;
							// 	let fy = this.y;
							// 	let angel = (Math.atan2(ty - fy, tx - fx) + 2*Math.PI) % (2*Math.PI);
							// 	attImg.rotation = angel * (180/Math.PI);
							// }
							
						}
					}
				} else {
					this._attCtrl.setSelectedIndex(0);
					this._shootEff.visible = false;
					this._shootEff.gotoAndStop(1);
				}
			}
		}

		public setInFightMode(b: boolean) {
			if (this._attCtrl && this._fightAni) {
				if (b) {
					this._attCtrl.setSelectedIndex(2);
					this._fightAni.play(null, null, null, -1);
				} else {
					this._attCtrl.setSelectedIndex(0);
					this._fightAni.stop();
				}
			}
		}

		protected _destroyCharCom() {
			this.removeFromParent();
			this._charCom = null;
			this._curEff = null;
			if (this._curECEff) {
				this._curECEff.stop();
				this._curECEff = null;
			}
			this._effId2ECEffect.forEach((effId, effect) => {
				effect.stop();
				Core.MCFactory.inst.revertMovieClip(effect);
			});
			this._effId2ECEffect.clear();
		}

		public onDestroy() {
			fairygui.GTimers.inst.remove(this._doSetDir, this);
			egret.Tween.pauseTweens(this);
			this._destroyCharCom();
			if (this._shootEff) {
				Core.MCFactory.inst.revertMovieClip(this._shootEff);
				this._shootEff = null;
			}
			this._designedPath = [];
		}

		public static roadType2CharType(rtype: RoadType): CharType {
			if (rtype == RoadType.LAND) {
				return CharType.T_TROOPS
			} else {
				return CharType.T_BOAT;
			}
		}
    }
}