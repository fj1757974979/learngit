module War {

    export class CityCom extends fairygui.GComponent {

        private _city: City;
        private _country: Country;

        private _flag: fairygui.GLoader;
        private _icon: fairygui.GLoader;
        private _cityName: fairygui.GTextField;
        private _campName: fairygui.GTextField;
        private _signCom: fairygui.GLoader;
        private _defenseBar: UI.MaskProgressBar;
        private _chooseCtr: fairygui.Controller;
        private _fightCtr: fairygui.Controller;
        private _headCom: Social.HeadCom;
        private _defPlayerNumText: fairygui.GTextField;

        private _touchX: number;
        private _touchY: number;

        private _watchCityProps: Array<string>;
        private _watchCountryProps: Array<string>;

         protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);

            this._flag = this.getChild("flag").asLoader;
            this._icon = this.getChild("icon").asLoader;
            this._cityName = this.getChild("title").asTextField;
            this._campName = this.getChild("campName").asTextField;
            this._defPlayerNumText = this.getChild("amount").asTextField;
            // this._signCom = this.getChild("n8").asLoader;
            this._defenseBar = this.getChild("expProgressBar").asCom as UI.MaskProgressBar;
            this._chooseCtr = this.getController("choose");
            this._fightCtr = this.getController("fight");
            this._headCom = this.getChild("head").asCom as Social.HeadCom;
            this._chooseCtr.selectedIndex = 1;

            this.addEventListener(egret.TouchEvent.TOUCH_BEGIN, this._touchBegin, this);
            // this.addEventListener(fairygui.DropEvent.FOCUS_OUT.)
            // this.addClickListener(this._onCity, this);
            this.addEventListener(egret.TouchEvent.TOUCH_END, this._touchEnd, this);

            this._watchCityProps = ["defence"];
            this._watchCountryProps = ["countryFlag","countryName"];
        }
        private _touchBegin(evt: egret.TouchEvent) {
            this._touchX = evt.stageX;
            this._touchY = evt.stageY;
        }
        private _touchEnd(evt: egret.TouchEvent) {
            if (this._touchX == null || this._touchY == null) {
                return;
            }
            let diffX = this._touchX - evt.stageX;
            let diffY = this._touchY - evt.stageY;
            this._touchX = null;
            this._touchY = null;
            if (Math.abs(diffX) > 10 || Math.abs(diffY) > 10) {
                return ;
            } else {
                this._onCity();
            }
        }
        private _watch() {
            if (this._city) {
                this._city.watchProp(City.PropDefence, this._updateCityDefence, this);
                this._city.watchProp(City.PropCountry, this._updateCountryProps, this);
                this._city.watchProp(City.PropDefPlayerNum, this._updateDefPlayerNum, this);
            }
            
        }
        private _unwatch() {
            if (this._city) {
                this._city.unwatchProp(City.PropDefence, this._updateCityDefence, this);
                this._city.unwatchProp(City.PropCountry, this._updateCountryProps, this);
                this._city.unwatchProp(City.PropDefPlayerNum, this._updateDefPlayerNum, this);
            }
            if (this._country) {
                this._unwatchCountry();
            }
        }

        private _watchCountry() {
            if (this._country) {
                this._watchCountryProps.forEach(prop => {
                    this._country.watchProp(prop, this._updateCountryProps, this);
                });
            }
        }

        private _unwatchCountry() {
            if (this._country) {
                this._watchCountryProps.forEach(prop => {
                    this._country.unwatchProp(prop, this._updateCountryProps, this);
                })
            }
        }

        public setCity(city: City) {
            this._unwatch();
            this._city = city;
            this._cityName.text = this._city.cityName;
            this.setXY(this._city.cityPoint.x, this._city.cityPoint.y);
            this._chooseCtr.selectedIndex = 0;
            this.refresh();
            this._watch();
        }

        public async refresh() {
            // this._country = CountryMgr.inst.getCountry(this._city.countryID);
            
            // if (MyWarPlayer.inst.isMyCity(this._city.cityID)) {
            //     this._headCom.visible =true;
            //     this._headCom.setHead(Player.inst.avatarUrl);
            //     this._headCom.setFrame(Player.inst.frameUrl);
            //     Core.EventCenter.inst.addEventListener(GameEvent.ModifyAvatarEv, (evt: egret.Event) => {
            //         this._headCom.setHead(evt.data);
            //     }, this);
            //     Core.EventCenter.inst.addEventListener(GameEvent.ModifyFrameEv, (evt: egret.Event) => {
            //         this._headCom.setFrame(Player.inst.frameUrl);
            //     }, this);
            //     if (this._country) {
            //         this._headCom.x = 55;
            //     } else {
            //         this._headCom.x = 10;
            //     }
            // } else {
            //     this._headCom.visible =false;
            // }
            this._updateCityDefence();
            this._updateCountryProps();
            this._updateDefPlayerNum();
        }
        public setInFallenMode(bool: boolean) {
            if (bool) {
                this._fightCtr.setSelectedIndex(2);
            } else {
                this._fightCtr.setSelectedIndex(0);
            }
        }
        private async _updateCityDefence() {
            //设置城防
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING)) {
                if (this._city.defence <= 0) {
                    this._defenseBar.visible = false;
                } else {
                    this._defenseBar.setProgress(this._city.defence, this._city.defenceMax);
                    this._defenseBar.setProgress2(this._city.defence, this._city.defenceMax);
                    this._defenseBar.getChild("text").asTextField.text = `${this._city.defence}`;
                    this._defenseBar.visible = true;
                    this._fightCtr.setSelectedIndex(1);
                }
            } else {
                this._defenseBar.visible = false;
            }
        }
        private async _updateDefPlayerNum() {
            if (WarMgr.inst.inStatus(BattleStatusName.ST_DURING)) {
                if (this._city.defPlayerNum > 0) {
                    this._defPlayerNumText.text = `x${this._city.defPlayerNum.toString()}`;
                } else {
                    this._defPlayerNumText.text = "";
                }
            } else {
                this._defPlayerNumText.text = "";
            }
        }

        private async _updateCountryProps() {
            this._unwatchCountry();
            if (this._city.countryID != 0) {
                this._country = CountryMgr.inst.getCountry(this._city.countryID);
                if (this._country) {
                    this._campName.text = this._country.countryName;
                    this._flag.visible = true;
                    this._flag.url = this._country.countryFlag;
                    this._watchCountry();
                } else {
                    this._country = null;
                    this._campName.text = "";
                    this._flag.visible = false;
                }
            } else {
                this._country = null;
                this._campName.text = "";
                this._flag.visible = false;
            }
            if (this._country) {
                this._headCom.x = 55;
            } else {
                this._headCom.x = 10;
            }
        }

        public async setHead(bool: boolean) {
            this._headCom.visible = bool;
            if (bool) {
                this._headCom.setHead(Player.inst.avatarUrl);
                this._headCom.setFrame(Player.inst.frameUrl);
                if (this._country) {
                    this._headCom.x = 55;
                } else {
                    this._headCom.x = 10;
                }
            }
        }
        private async _onCity() {
            if (WarMgr.inst.mapState != MapState.Normal) {
                if (WarMgr.inst.mapState != MapState.SurrenderCamp && WarMgr.inst.mapState != MapState.SurrenderCity) {
                    if (WarMgr.inst.nowSelectCity.cityID == this._city.cityID) {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70236)));
                        return;
                    }
                } else if (this._city.countryID != 0 && this._city.countryID == MyWarPlayer.inst.countryID) {
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70237)));
                    return;
                }
                
                Core.EventCenter.inst.dispatchEventWith(WarMgr.SelectCity, false, this._city.cityID);
                return;
            } else {
                WarMgr.inst.openCityInfo(this._city.cityID);
                // if (WarMgr.inst.inStatus(BattleStatusName.ST_NORMAL)) {
                //     WarMgr.inst.openCityInfo(this._city.cityID);
                // } else if (WarMgr.inst.inStatus(BattleStatusName.ST_PREPARE)) {
                //     WarMgr.inst.openCityInfo(this._city.cityID);
                // }
            }           
        }

        public setCitySelectMode(b: boolean) {
            if (b) {
                this._chooseCtr.selectedIndex = 1;
            } else {
                this._chooseCtr.selectedIndex = 0;
            }
        }

        public setCityInWarMode(b: boolean) {
            this._defPlayerNumText.visible = b;
            this._updateDefPlayerNum();
            if (b) {
                if (this._city.defence <= 0) {
                    this._fightCtr.selectedIndex = 1;
                } else {
                    this._fightCtr.selectedIndex = 1;
                }
            } else {
                this._fightCtr.selectedIndex = 0;
            }
        }

        public setCityInAttackedMode(b: boolean) {
            if (b) {
                this.getTransition("attacking").play();
            } else {
                this.getTransition("attacking").stop();
            }
            this.getChild("n11").asLoader.visible = b;
        }

        public onDestroy() {
            this._unwatch();
            this.removeFromParent();
        }
    }
}