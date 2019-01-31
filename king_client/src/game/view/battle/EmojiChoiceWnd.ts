module Battle {

    export class EmojiCom extends fairygui.GComponent {
        private _icon: fairygui.GLoader;
        private _myParent: fairygui.GComponent;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._icon = this.getChild("emojiIcon").asLoader;
        }

        public setParent(display:fairygui.GComponent) {
            this._myParent = display;
            this.x = display.width / 2;
            this.y = display.height / 2;
        }

        public show(emojiID:number): boolean {
            fairygui.GTimers.inst.remove(this.removeFromParent, this);
            this._icon.url = "ui://common/emoji" + emojiID;
            if (!this.parent) {
                this._myParent.addChild(this);
            }
            fairygui.GTimers.inst.add(3000, 1, this.removeFromParent, this);
            return true;
        }
    }

    export class SelfEmojiCom extends EmojiCom {
        private _lastTime: number;
        private _isContinuity: boolean;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._lastTime = 0;
            this._isContinuity = false;
        }

        public show(emojiID:number): boolean {
            if (this.parent) {
                return false;
            }

            let now = Math.round(new Date().getTime()/1000);
            if (this._isContinuity) {
                this._isContinuity = false;
            } else {
                if (now - this._lastTime <= 2) {
                    this._isContinuity = true;
                }
            }
            this._lastTime = now + 3;
            return super.show(emojiID);
        }
    }

    export class EmojiListViewCom extends fairygui.GComponent {

        private _emojis: fairygui.GList;
        private _emojiTeam: Social.EmojiTeam;
        private _choiceCallback: (emojiIndex: number) => void;
        private _initialized: boolean;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._emojis = this.getChild("emoji").asList;
            this._emojis.addEventListener(fairygui.ItemEvent.CLICK, this._onClickEmoji, this);
            this._initialized = false;
        }

        private _onClickEmoji(evt: fairygui.ItemEvent) {
            if (!this._emojiTeam.isUnlock) {
                Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60063));
                return;
            }
            let eid = evt.itemObject.name;
            if (this._choiceCallback) {
                let emojiIdx = eid; //eid.substr(5, eid.length - 5);
                this._choiceCallback(parseInt(emojiIdx));
            }
        }

        public updateEmojiTeam(emojiTeam: Social.EmojiTeam, choiceCallback: (emojiId: number) => void) {
            this._emojiTeam = emojiTeam;
            this._choiceCallback = choiceCallback;
        }

        // public refresh() {
        //     if (!this._initialized) {
        //         this._emojis.removeChildren(0, -1, true);
        //         let emojiIds = this._emojiTeam.emojiIds;
        //         emojiIds.forEach(eid => {
        //             let emoji = fairygui.UIPackage.createObject(PkgName.common, "emoji").asCom;
        //             emoji.getChild("icon").asLoader.url = "ui://common/" + eid;
        //             emoji.name = eid;
        //             this._emojis.addChild(emoji);
        //         });
        //     }
        // }

        public get emojiTeam(): Social.EmojiTeam {
            return this._emojiTeam;
        }
    }

    export class EmojiTeamChkBtnCom extends fairygui.GButton {

        private _emojiChoiceWnd: EmojiChoiceWnd;
        private _emojiTeam: Social.EmojiTeam;
        private _ctrl: fairygui.Controller;

        protected constructFromXML(xml: any): void {
            super.constructFromXML(xml);
            this._ctrl = this.getController("button");

            this.addClickListener(this._onClick, this);
        }

        public updateEmojiTeam(emojiTeam: Social.EmojiTeam, emojiChoiceWnd: EmojiChoiceWnd) {
            this._emojiTeam = emojiTeam;
            this._emojiChoiceWnd = emojiChoiceWnd;
            if (!LanguageMgr.inst.isChineseLocale()) {
                this.getChild("title").asTextField.fontSize = 12;
            }
            this.getChild("title").asTextField.text = emojiTeam.name;
            if (emojiTeam.isUnlock) {
                this.getController("enable").setSelectedPage("true");
            } else {
                this.getController("enable").setSelectedPage("false");
            }
        }

        private _onClick() {
            this._emojiChoiceWnd.onChoiceTeam(this);
        }

        public get emojiTeam(): Social.EmojiTeam {
            return this._emojiTeam;
        }

        public setChosen(b: boolean) {
            if (b) {
                this._ctrl.setSelectedPage("down");
            } else {
                this._ctrl.setSelectedPage("up");
            }
        }
    }

    export class EmojiChoiceWnd extends Core.BaseWindow {
        private _choiceCallback: (emojiId: number) => void;
        private _pageList: fairygui.GList;
        private _emojiTeamIdToCom: Collection.Dictionary<number, EmojiListViewCom>;
        private _emojiTeamIdToChk: Collection.Dictionary<number, EmojiTeamChkBtnCom>;
        private _initialized: boolean;
        private _curChkBtn: EmojiTeamChkBtnCom;
        private _pageCtrl: fairygui.Controller;

        public initUI() {
            super.initUI();
            this.center();
            this._pageList = this.contentPane.getChild("pageList").asList;
            this._emojiTeamIdToCom = new Collection.Dictionary<number, EmojiListViewCom>();
            this._emojiTeamIdToChk = new Collection.Dictionary<number, EmojiTeamChkBtnCom>();
            this._initialized = false;
            this._curChkBtn = null;
            this._pageCtrl = this.contentPane.getController("pageCtrl");
            // this._emojiList.scrollPane.pageController = this._pageCtrl;
        }

        public async open(...param:any[]) {
            await super.open(...param);
            this._choiceCallback = param[0];
            //this.center();
            this.contentPane.setXY(0,100);

            let self = this;
            let emojiTeams = await Social.EmojiMgr.inst.getEmojiTeams();
            for (let i = 0; i < emojiTeams.length; ++ i) {
                let emojiTeam = emojiTeams[i];
                let emojiTeamId = emojiTeam.teamId;
                let chkBtn = this._emojiTeamIdToChk.getValue(emojiTeamId);
                if (!chkBtn) {
                    chkBtn = fairygui.UIPackage.createObject(PkgName.common, "emojiChk", EmojiTeamChkBtnCom) as EmojiTeamChkBtnCom;
                    this._emojiTeamIdToChk.setValue(emojiTeamId, chkBtn);
                    this._pageList.addChild(chkBtn);
                    // this._pageCtrl.addPage(emojiTeam.teamId.toString());
                    chkBtn.pageOption.controller = this._pageCtrl;
                    chkBtn.pageOption.name = emojiTeam.teamId.toString();
                    chkBtn.changeStateOnClick = true;
                }
                chkBtn.updateEmojiTeam(emojiTeam, this);

                let viewCom = this._emojiTeamIdToCom.getValue(emojiTeamId);
                if (!viewCom) {
                    // viewCom = fairygui.UIPackage.createObject(PkgName.battle, `emojiView${emojiTeamId}`, EmojiListViewCom) as EmojiListViewCom;
                    viewCom = this.contentPane.getChild(`view${emojiTeamId}`).asCom as EmojiListViewCom;
                    this._emojiTeamIdToCom.setValue(emojiTeam.teamId, viewCom);
                }
                viewCom.updateEmojiTeam(emojiTeam, (emojiIdx: number) => {
                    if (self._choiceCallback) {
                        self._choiceCallback(emojiIdx);
                        self._choiceCallback = null;
                    }
                    Core.ViewManager.inst.closeView(self);
                    fairygui.GRoot.inst.hidePopup(self);
                });

                if (!this._curChkBtn && i == 0) {
                    this._setCurChkBtn(chkBtn);
                } else if (this._curChkBtn != chkBtn) {
                    chkBtn.setChosen(false);
                }
            }
        }

        public onChoiceTeam(emojiTeamChkBtn: EmojiTeamChkBtnCom) {
            let emojiTeam = emojiTeamChkBtn.emojiTeam;
            let teamId = emojiTeam.teamId;
            let viewCom = this._emojiTeamIdToCom.getValue(teamId);
            if (viewCom) {
                this._setCurChkBtn(emojiTeamChkBtn);
            }
        }

        private _setCurChkBtn(emojiTeamChkBtn: EmojiTeamChkBtnCom) {
            if (this._curChkBtn) {
                this._curChkBtn.setChosen(false);
            }
            this._curChkBtn = emojiTeamChkBtn;
            this._curChkBtn.setChosen(true);

            let emojiTeam = emojiTeamChkBtn.emojiTeam;
            let teamId = emojiTeam.teamId;
            this._pageCtrl.setSelectedPage(`${teamId}`);
            
            // let viewCom = this._emojiTeamIdToCom.getValue(teamId);
            // viewCom.refresh();
        }

        private _onScrollEnd() {
            let teamId = parseInt(this._pageCtrl.selectedPage);
            let chkBtn = this._emojiTeamIdToChk.getValue(teamId);
            this._setCurChkBtn(chkBtn);
        }
    }

}