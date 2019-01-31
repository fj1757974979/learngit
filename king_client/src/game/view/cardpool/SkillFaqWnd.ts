module CardPool {

    export class SkillFaqWnd extends Core.BaseWindow {

        private _faqList: fairygui.GList;
        private _closeBtn: fairygui.GButton;

        public initUI() {
            super.initUI()
            
            this.center();
            this.modal = true;


            this._closeBtn = this.contentPane.getChild("closeBtn").asButton;
            this._faqList = this.contentPane.getChild("textList").asList;

            this._closeBtn.addClickListener( () => {
                Core.ViewManager.inst.closeView(this);
            }, this);

            this._faqList.removeChildrenToPool();
            let skillKeys = Data.priority.keys;
            let headCom = this._faqList.addItemFromPool().asCom;
            headCom.getChild("mailText").asRichTextField.text ="\n" + Core.StringUtils.TEXT(70128);
            skillKeys.forEach((key) => {
                let skillData = Data.priority.get(key);
                let com = this._faqList.addItemFromPool().asCom;
                let txt = "";
                if (skillData.priority1) {
                    let skillNames = <string>skillData.priority1;
                    let skills = skillNames.split(";");
                    if (txt == "") {                      
                        txt =this._getLinkText(skills, 1);
                    } else {
                        txt +=`，${this._getLinkText(skills, 1)}`;
                    }
                }
                if (skillData.priority2) {
                    let skillNames = <string>skillData.priority2;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 2);
                    } else {
                        txt += `，${this._getLinkText(skills, 2)}`;
                    }
                }
                if (skillData.priority3) {
                    let skillNames = <string>skillData.priority3;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 3);
                    } else {
                        txt += `，${this._getLinkText(skills, 3)}`;
                    }
                }
                if (skillData.priority4) {
                    let skillNames = <string>skillData.priority4;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 4);
                    } else {
                        txt += `，${this._getLinkText(skills, 4)}`;
                    }
                }
                if (skillData.priority5) {
                    let skillNames = <string>skillData.priority5;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 5);
                    } else {
                        txt += `，${this._getLinkText(skills, 5)}`;
                    }
                }
                if (skillData.priority6) {
                    let skillNames = <string>skillData.priority6;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 6);
                    } else {
                        txt += `，${this._getLinkText(skills, 6)}`;
                    }
                }
                if (skillData.priority7) {
                    let skillNames = <string>skillData.priority7;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 7);
                    } else {
                        txt += `，${this._getLinkText(skills, 7)}`;
                    }
                }
                if (skillData.priority8) {
                    let skillNames = <string>skillData.priority8;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 8);
                    } else {
                        txt += `，${this._getLinkText(skills, 8)}`;
                    }
                }
                if (skillData.priority9) {
                    let skillNames = <string>skillData.priority9;
                    let skills = skillNames.split(";");
                    if (txt == "") {
                        txt = this._getLinkText(skills, 9);
                    } else {
                        txt += `，${this._getLinkText(skills, 9)}`;
                    }
                }
                com.getChild("mailText").asRichTextField.text = `<b>${skillData.desOpp}</b> \n` + txt + "\n";
                com.getChild("mailText").asRichTextField.addEventListener(egret.TextEvent.LINK, htmlClickCallback, this);
            })


        }

        private _getLinkText(skills: string[], index: number): string {
            let txt = "";
            skills.forEach((_id) => {
                let t = `<a href="event:skill,${_id}"><u>${index}.${Data.skill.get(_id).name}</u></a>`;
                if (txt == "") {
                    txt = t;
                } else {
                    txt += `，${t}`;
                }
            })
            return txt;

        }

        public async open(...param: any[]) {
            super.open(...param);
        }

        public async close(...param: any[]) {
            super.close(...param);
        }

    }
}