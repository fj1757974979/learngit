module CardPool {

    export class SkinItemCom extends fairygui.GComponent {

        private _tip: fairygui.GTextField;
        private _current: fairygui.GLoader;
        private _skinObj: fairygui.GComponent;
        private _Using: fairygui.GLoader;

        private _hasSkin: boolean;

        private _skinID: string;

        protected constructFromXML(xml: any): void {
			super.constructFromXML(xml);

            this._tip = this.getChild("tip").asTextField;
            this._current = this.getChild("current").asLoader;
            this._skinObj = this.getChild("n6").asCom;
            this._Using = this.getChild("usingFlag").asLoader;
            ;
        }

        public setCur(b: boolean) {
            this._current.visible = b;
            if (b) {
                this.setScale(1,1);
            } else {
                this.setScale(0.8,0.8);
            }
        }

        public setUsing(b: boolean) {
            this._Using.visible = b;
        }

        public setHasSkin(b: boolean) {
            this._hasSkin = b;
            // this.grayed = !b;
        }

        public get hasSkin(): boolean {
            return this._hasSkin;
        }

        public get skinID() {
            return this._skinID;
        }

        public setSkin(skinID: string, cardId: number, name: string, url: string) {
            let cardData = CardPoolMgr.inst.getCardData(cardId, 1);
            let skindata = CardSkinMgr.inst.getSkinConf(skinID);
            if (skinID == "") {
                this._tip.text = Core.StringUtils.TEXT(70113);
                url = `card_b_${url}_png`;
                let name = <string>cardData.name;
                if (name.indexOf("#") != -1) {
                    name = name.slice(3, name.length - 2);
                }
                this._skinObj.getChild("nameText").asTextField.text = name;
            } else {
                this._tip.text = skindata.desc;
                url = `skin_b_${skinID}_png`;
                this._skinObj.getChild("nameText").asTextField.text = skindata.name;
            }
            
            this._skinID = skinID;
            Utils.setImageUrlPicture(this._skinObj.getChild("icon").asImage, url);
        }

    }

    export class SkinWnd extends Core.BaseWindow {

        private _cardObj: Card;
        
        private _skinList: fairygui.GList;
         private _setBtn: fairygui.GButton;

         private _curCom: SkinItemCom;
         private _curSkinID: string;
         private _useSkinID: string;
         private _hasSkins: string[];
         private _hasCard: boolean;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this.adjust(this.contentPane.getChild("bg"));

            this._skinList = this.contentPane.getChild("skinList").asList;
            this._setBtn = this.contentPane.getChild("setBtn").asButton;

            this._setBtn.addClickListener(this._onSet, this);
            this.contentPane.getChild("bg").addClickListener(()=>{
                Core.ViewManager.inst.closeView(this);
            }, this);
            this._skinList.scrollPane.addEventListener(fairygui.ScrollPane.SCROLL, this._seletCom, this);
        }

        private _seletCom() {
            let midX = this._skinList.scrollPane.posX + this._skinList.viewWidth / 2;
		    let cnt = this._skinList.numChildren;
		    for (let i = 0; i < cnt; i++) {
                let obj = this._skinList.getChildAt(i) as SkinItemCom;
                let dist = Math.abs(midX - obj.x - obj.width / 2);
                if (dist > obj.width) {
                    obj.setCur(false);
                    obj.setScale(1, 1);
                } else {
                    if (dist == 0) {
                        obj.setCur(true);
                        this._curCom = obj;
                        this.changeSetBtn(obj);
                    }
                    let ss =1 + (1 - dist / obj.width) * 0.1;
                    obj.setScale(ss, ss);
                    
                }
            }
        }

        private changeSetBtn(obj: SkinItemCom) {
            if (obj.skinID == this._useSkinID) {
            //     this._setBtn.title = Core.StringUtils.TEXT(70115);
            //     this._setBtn.touchable = false;
            //     this._setBtn.grayed = true;
                this._setBtn.visible = false;
            } else {
                this._setBtn.visible = true;
                // this._setBtn.touchable = obj.hasSkin;
                this._setBtn.grayed = !obj.hasSkin;
                if (obj.hasSkin) {
                this._setBtn.title = Core.StringUtils.TEXT(70118);
                } else {
                    this._setBtn.title = Core.StringUtils.TEXT(60063);
                }
            }
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._cardObj = param[0];
            if (param[1]) {
                this._curSkinID = param[1];
                // this.contentPane.getTransition("openOther").play();
            } else {
                this._curSkinID = this._cardObj.skin;
                // this.contentPane.getTransition("openSelf").play();
            }
            this._useSkinID = this._cardObj.skin;
            this._hasSkins = this._cardObj.hasSkins;
            this._hasCard = !(this._cardObj.amount <= 0 && this._cardObj.level <= 1);
            this._updateSkinList();
        }

        private async _onSet() {
            if (!this._hasCard) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60125));
                return;
            } else if (!this._curCom.hasSkin) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70126));
                return;
            }
            if (this._curCom.skinID == this._useSkinID) {
                Core.ViewManager.inst.close(ViewName.skinView);
                return;
            }
            let arg = {"CardID": this._cardObj.cardId, "Skin": this._curCom.skinID};
            // console.log(arg, this._cardObj.state);
            let result = await Net.rpcCall(pb.MessageID.C2S_UPDATE_CARD_SKIN, pb.SkinCard.encode(arg));
            if (result.errcode == 0) {
                this._cardObj.skin = this._curCom.skinID;
                // CardInfoWnd.inst.changeSkin();
                Core.ViewManager.inst.close(ViewName.skinView);
            } else {
                console.log(result.errcode);
            }
        }

        private _updateSkinList() {
            this._skinList.removeChildrenToPool();
            let cardId = this._cardObj.cardId;
            let curIndex = 0;
            //读取该武将所有的皮肤
            let allSkins = CardSkinMgr.inst.getAllSkins(this._cardObj.cardId);
            if (allSkins) {
                allSkins.forEach( (skinID , index) => {
                    let _com = this._skinList.addItemFromPool().asCom as SkinItemCom;
                    let name = "";
                    let _icom ;
                    if (skinID == "") {
                        name = this._cardObj.name;
                        _icom = this._cardObj.icon;
                    } else {
                        name = CardSkinMgr.inst.getSkinConf(skinID).name;
                        _icom = skinID;
                    }
                    _com.setSkin(skinID, cardId, name, _icom);
                    
                    _com.setUsing(skinID == this._useSkinID);
                    _com.setCur(skinID == this._curSkinID);
                    let _hasSkin = this._hasSkins.indexOf(skinID) != -1;
                    _com.setHasSkin( this._hasCard && _hasSkin);
                    if (skinID == this._curSkinID) {
                        curIndex = index;
                        this._curCom = _com;
                    }
                })
                this._skinList.scrollToView(curIndex);
                this._seletCom();
            }

        }

        public async close(...param: any[]) {
            super.close(...param);

        }

    } 
}