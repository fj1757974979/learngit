module Social {
    export enum PrivType {
        vip = 1,
        priv = 2,
        miniVip = 99,
    }
    export class PrivCom extends fairygui.GComponent {
        private _privData: any;
        private _privIcon: fairygui.GLoader;
        private _privName: fairygui.GTextField;
        private _privDesc: fairygui.GTextField;
        private _privTime: fairygui.GTextField;

        constructFromXML(xml: any): void {
            this._privIcon = this.getChild("icon").asLoader;
            this._privName = this.getChild("name").asTextField;
            let descCom = this.getChild("desc");
            if (descCom) {
                this._privDesc = descCom.asTextField;
            }
            let timeCom = this.getChild("time");
            if (timeCom) {
                this._privTime = timeCom.asTextField;
            }
        }

        public async setPriv(type: PrivType, id?: number) {
            if (type == PrivType.vip || type == PrivType.miniVip) {
                let giftData = Payment.PayMgr.inst.getProducts();
                if (type == PrivType.vip) {
                    this._privData = giftData.getValue("advip") as Payment.GiftProduct
                } else {
                    this._privData = giftData.getValue("minivip") as Payment.GiftProduct
                }
                this._privName.text =  this._privData.name;
                this._privIcon.url = `shop_${this._privData.icon}_png`;
                if (this._privDesc) {
                    this._privDesc.text = this._privData.desc;
                    if (Player.inst.isNewVersionPlayer()) {
                        if (type == PrivType.vip) {
                            this._privDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(60382), 30) + "\n" + this._privDesc.text;
                        } else if (type == PrivType.miniVip) {
                            this._privDesc.text = Core.StringUtils.format(Core.StringUtils.TEXT(60382), 7) + "\n" + this._privDesc.text;
                        }
                    }
                }
                if (this._privTime) {
                    let timeStr = "";
                    let time = await Player.inst.getVipTime();
                    if (time > 0) {
                        timeStr = Core.StringUtils.secToString(time, "dhm");
                    }
                    this._privTime.text = timeStr;
                }
            } else if (type == PrivType.priv) {
                this._privData = Data.priv_config.get(id);
                this._privIcon.url = `reborn_${this._privData.icon}_png`;
                this._privName.text = this._privData.name;
                if (this._privDesc) {
                    this._privDesc.text = this._privData.desc;
                }
            }
        }

    }

    export class PrivPanelWnd extends Core.BaseWindow {

        private _privList: fairygui.GList;
        private _closeBtn: fairygui.GButton;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._privList = this.contentPane.getChild("headList").asList;
            this._closeBtn = this.contentPane.getChild("confirmBtn").asButton;

            this._privList.addEventListener(fairygui.ItemEvent.CLICK, this._onPriv, this);

            this._closeBtn.addClickListener(() => {
                Core.ViewManager.inst.closeView(this);
            }, this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            this._refresh();
        }
        private _refresh() {
            this._privList.removeChildrenToPool();
            let vipCom = this._privList.addItemFromPool() as PrivCom;
            vipCom.setPriv(PrivType.vip);
            vipCom.grayed = !Player.inst.isVip;
            let allPrivKeys = Data.priv_config.keys;
            allPrivKeys.forEach( _id => {
                let com = this._privList.addItemFromPool() as PrivCom;
                com.setPriv(PrivType.priv, _id);
                com.grayed = !Player.inst.hasPrivilege(_id);
            })
        }
        private _onPriv(evt: fairygui.ItemEvent) {
            let index = this._privList.getChildIndex(evt.itemObject);
            Core.ViewManager.inst.open(ViewName.privView, index);
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }

    export class PrivViewWnd extends Core.BaseWindow {

        private _privList: fairygui.GList;

        public initUI() {
            super.initUI();
            this.center();
            this.modal = true;
            this._privList = this.contentPane.getChild("list").asList;
            this.adjust(this.contentPane.getChild("closeBg"));
			this.contentPane.getChild("closeBg").addClickListener(() => {
				Core.ViewManager.inst.closeView(this);
			},this);
        }

        public async open(...param: any[]) {
            super.open(...param);
            let index = param[0];
            this._refresh();
            if (this._privList.numItems > index) {
                this._privList.scrollToView(index);
            }
        }
        private _refresh() {
            this._privList.removeChildrenToPool();
            let vipCom = this._privList.addItemFromPool() as PrivCom;
            vipCom.setPriv(PrivType.vip);
            vipCom.getChild("icon").grayed = !Player.inst.isVip;
            vipCom.getChild("light").visible = Player.inst.isVip;
            let allPrivKeys = Data.priv_config.keys;
            allPrivKeys.forEach( _id => {
                let com = this._privList.addItemFromPool() as PrivCom;
                com.setPriv(PrivType.priv, _id);
                com.getChild("icon").grayed = !Player.inst.hasPrivilege(_id);
                com.getChild("light").visible = Player.inst.hasPrivilege(_id);
            })
        }
        public async close(...param: any[]) {
            super.close(...param);
        }
    }
}