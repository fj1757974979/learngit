module Home {

    export class ArchiveView extends Core.BaseView {
        private _archiveBtn1:fairygui.GButton;
        private _archiveBtn2:fairygui.GButton;
        private _archiveBtn3:fairygui.GButton;
        private _delArchiveBtn1:fairygui.GButton;
        private _delArchiveBtn2:fairygui.GButton;
        private _delArchiveBtn3:fairygui.GButton;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));
            this._archiveBtn1 = this.getChild("archiveBtn1").asButton;
            this._archiveBtn1.data = "1";
            this._archiveBtn2 = this.getChild("archiveBtn2").asButton;
            this._archiveBtn2.data = "2";
            this._archiveBtn3 = this.getChild("archiveBtn3").asButton;
            this._archiveBtn3.data = "3";
            this._delArchiveBtn1 = this.getChild("delArchiveBtn1").asButton;
            this._delArchiveBtn1.data = "1";
            this._delArchiveBtn2 = this.getChild("delArchiveBtn2").asButton;
            this._delArchiveBtn2.data = "2";
            this._delArchiveBtn3 = this.getChild("delArchiveBtn3").asButton;
            this._delArchiveBtn3.data = "3";

            this._archiveBtn1.addClickListener(this._loginAvatar, this);
            this._archiveBtn2.addClickListener(this._loginAvatar, this);
            this._archiveBtn3.addClickListener(this._loginAvatar, this);
            this._delArchiveBtn1.addClickListener(this._delAvatarArchive, this);
            this._delArchiveBtn2.addClickListener(this._delAvatarArchive, this);
            this._delArchiveBtn3.addClickListener(this._delAvatarArchive, this);
        }

        public async open(...param:any[]) {
            super.open(...param);
            let archiveDatas = param[0] as pb.AccountArchives;
            this._updateArchive(1, archiveDatas);
            this._updateArchive(2, archiveDatas);
            this._updateArchive(3, archiveDatas);
        }

        private _updateArchive(archiveID:number, archiveDatas:pb.AccountArchives) {
            let data:any;
            let btn: fairygui.GButton;
            let delBtn: fairygui.GButton;
            if (archiveDatas) {
                for (let _data of archiveDatas.Archives) {
                    if (_data.ID == archiveID) {
                        data = _data;
                        break;
                    }
                }
            }

            if (archiveID == 1) {
                btn = this._archiveBtn1;
                delBtn = this._delArchiveBtn1;
            } else if (archiveID == 2) {
                btn = this._archiveBtn2;
                delBtn = this._delArchiveBtn2;
            } else {
                btn = this._archiveBtn3;
                delBtn = this._delArchiveBtn3;
            }

            if (data) {
                btn.getController("archive").selectedPage = "old";
                let _date = new Date(data.LastTime * 1000);
                btn.title = `${_date.getFullYear().toString().substr(2)}-${_date.getMonth()+1}-${_date.getDate()} ${_date.getHours()}:${_date.getMinutes()}`;
                delBtn.visible = true;
            } else {
                btn.getController("archive").selectedPage = "new";
                delBtn.visible = false;
            }
        }

        private _loginAvatar(ev:egret.TouchEvent) {
            HomeMgr.inst.onPlayerLogin(parseInt(ev.target.data));
        }

        private async _delAvatarArchive(ev:egret.TouchEvent) {
            let archiveID = parseInt(ev.target.data);
            Core.TipsUtils.confirm(Core.StringUtils.TEXT(60113), ()=>{ 
                HomeMgr.inst.delPlayerArchive(archiveID).then(ok=>{
                    if (ok) {
                        this._updateArchive(archiveID, null);
                    }
                })
            }, null, this);
        }
    }

}