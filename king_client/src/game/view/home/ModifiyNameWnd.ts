module Home {

    export class ModifyNameWnd extends Core.BaseWindow {
        private _errorText: fairygui.GTextField;
        private _searchInput: fairygui.GTextField;

        public initUI() {
			super.initUI();
			this.center();
			this.modal = true;

            this._searchInput = this.getChild("searchInput").asTextField;
            this._errorText = this.getChild("warning").asTextField;

            this.getChild("confirmBtn").addClickListener(this._onModifyName, this);
            this.getChild("modifyBtn").addClickListener(this._onModifyName, this);
            this.getChild("randomNameBtn").addClickListener(this._randomName, this);
            this.getChild("randomNameBtn").asButton.visible = Home.FunctionMgr.inst.isRandomNameOpen();
            this.getChild("closeBtn").addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
        }

        public async open(...param: any[]) {
            if (Core.ViewManager.inst.isShow(ViewName.battle)) {
                this.toTopLayer();
            } else {
            
            }
            super.open(...param);
            

            this._errorText.text = "";
            this._searchInput.text = "";
            //if (Player.inst.name.search(Core.StringUtils.TEXT(60036))) {
            if (!Player.inst.isNewbieName(Player.inst.name)) {
                this.getChild("txt").text = Core.StringUtils.TEXT(60163);
                this.getChild("title").text = Core.StringUtils.TEXT(60084);
                this.getChild("confirmBtn").visible = false;
                this.getChild("modifyBtn").visible = true;
                this.getChild("closeBtn").visible = true;
            } else {
                this.getChild("txt").text = Core.StringUtils.TEXT(60229);
                this.getChild("title").text = Core.StringUtils.TEXT(60035);
                this.getChild("confirmBtn").visible = true;
                this.getChild("modifyBtn").visible = false;
                this.getChild("closeBtn").visible = false;
            }
        }

        public async close(...param: any[]) {
            super.close(...param);
        }

        private _randomName() {
            if (window.gameGlobal.isMultiLan) {
                let name = "";
                let keys = Data.name_en_1.keys;
                let firstNameConf = Data.name_en_1.get(keys[Core.RandomUtils.randInt(keys.length)]);
                let firstName = firstNameConf.name;
                keys = Data.name_en_2.keys;
                let lastNameConf = Data.name_en_2.get(keys[Core.RandomUtils.randInt(keys.length)]);
                let lastName = lastNameConf.name;
                name = firstName + " " + lastName;
                this._searchInput.text = name;
            } else {
                let nameGameDatas: Array<any>;
                if (Math.round(Math.random()) == 0) {
                    nameGameDatas = [Data.name1, Data.name2, Data.name3];
                } else {
                    nameGameDatas = [Data.name3, Data.name4, Data.name5];
                }
                let name = "";
                for (let data of nameGameDatas) {
                    let keys = <Array<number>>data.keys;
                    let key = keys[Core.RandomUtils.randInt(keys.length)];
                    name += data.get(key).value;
                }
                this._searchInput.text = name;
            }
        }

        private async _onModifyName() {
            let name = this._searchInput.text.trim();
            if (name.length <= 0) {
                this._errorText.text = Core.StringUtils.TEXT(60102);
                return;
            }
            if (window.gameGlobal.isMultiLan) {
                if (Core.StringUtils.utf8Length(name) > 18) {
                    this._errorText.text = Core.StringUtils.TEXT(70198);
                    return;
                }
            } else {
                if (name.length > 10) {
                    this._errorText.text = Core.StringUtils.TEXT(60173);
                    return;
                }
            }
            
            if (name.indexOf("#c") != -1) {
                this._errorText.text = Core.StringUtils.TEXT(60166);
                return;
            }
            
            //if (Player.inst.isNewbieName(name) || Core.WordFilter.inst.containsDirtyWords(name)) {
            if (Player.inst.isNewbieName(name)) {    
                this._errorText.text = Core.StringUtils.TEXT(60166);
                return;
            }

            if (name == Player.inst.name) {
                this._errorText.text = Core.StringUtils.TEXT(60165);
                return;
            }
            //if (Player.inst.name.search(Core.StringUtils.TEXT(60036)) != -1) {
            if (Player.inst.isNewbieName(Player.inst.name)) {    
                let errcode = await HomeMgr.inst.modifyName(name);
                if (errcode == 101) {
                    this._errorText.text = Core.StringUtils.TEXT(60166);
                    return;
                } else if (errcode != 0) {
                    this._errorText.text = Core.StringUtils.TEXT(60185);
                    return;
                } else if (errcode == 0) {
                    Player.inst.name = name;
                    Core.ViewManager.inst.closeView(this);
                }
            } else {
                if (Player.inst.hasEnoughJade(50)) {
                    let ret = await new Promise(resolve => {
                        Core.TipsUtils.confirm(Core.StringUtils.TEXT(60105)+`#cp${name}#n?`, () => {
                            resolve(true);
                        }, () => {
                            resolve(false)
                        }, this);
                    });
                    if (ret) {
                        let colorCode = "";
                        if (Player.inst.name.indexOf("#c") != -1) {
                                colorCode = Player.inst.name.slice(0, 8);
                            }
                        let errcode = await HomeMgr.inst.updateName(name, colorCode);
                        if (errcode == 101) {
                            this._errorText.text = Core.StringUtils.TEXT(60166);
                            return;
                        } else if (errcode == -2) {
                            this._errorText.text = Core.StringUtils.TEXT(60185);
                            return;
                        } else if (errcode == 1) {
                            this._errorText.text = Core.StringUtils.TEXT(60180);
                            return;
                        } else if (errcode == 4) {
                            this._errorText.text = Core.StringUtils.TEXT(60211);
                            return;
                        } else if (errcode == 0) {
                            if (colorCode && colorCode != "") {
                                name = `${colorCode+name}#n`;
                            }                        
                            Player.inst.name = name;
                            Core.ViewManager.inst.closeView(this);
                        }
                    }
                } else {
                        this._errorText.text = Core.StringUtils.TEXT(60180);
                        return;
                }
            }
        }
    }

}