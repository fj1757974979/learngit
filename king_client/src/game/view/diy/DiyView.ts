module Diy {

    export class DiyView extends Core.BaseView {
        private _weaponCtrl: fairygui.Controller;
        private _wineAmountTxt: fairygui.GTextField;
        private _bookAmountTxt: fairygui.GTextField;
        private _cardImg: fairygui.GLoader;
        private _uploadImgBtn: fairygui.GButton;
        private _nameInput: fairygui.GLabel;
        private _addSkillBtn1: fairygui.GButton;
        private _addSkillBtn2: fairygui.GButton;
        private _upNumText: fairygui.GTextField;
        private _downNumText: fairygui.GTextField;
        private _leftNumText: fairygui.GTextField;
        private _rightNumText: fairygui.GTextField;
        private _upNumOffset: fairygui.GTextField;
        private _downNumOffset: fairygui.GTextField;
        private _leftNumOffset: fairygui.GTextField;
        private _rightNumOffset: fairygui.GTextField;
        private _singleNumText: fairygui.GTextField;
        private _totalNumText: fairygui.GTextField;
        private _saveBtn: fairygui.GButton;

        private _diySkillId1: number;
        private _diySkillId2: number;
        private _needWine1: number;
        private _needWine2: number;
        private _needBook1: number;
        private _needBook2: number;
        private _curCardData: any;
        private _uploadImgData:string = "";

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("bg"));
            this._weaponCtrl = this.getController("weapon");
            this._wineAmountTxt = this.getChild("wineAmountTxt").asTextField;
            this._bookAmountTxt = this.getChild("bookAmountTxt").asTextField;
            this._cardImg = this.getChild("cardImg").asLoader;
            this._uploadImgBtn = this.getChild("uploadImgBtn").asButton;
            this._nameInput = this.getChild("nameInput").asLabel;
            this._addSkillBtn1 = this.getChild("addSkillBtn1").asButton;
            this._addSkillBtn2 = this.getChild("addSkillBtn2").asButton;
            this._upNumText = this.getChild("upNumText").asTextField;
            this._downNumText = this.getChild("downNumText").asTextField;
            this._leftNumText = this.getChild("leftNumText").asTextField;
            this._rightNumText = this.getChild("rightNumText").asTextField;
            this._upNumOffset = this.getChild("upNumOffset").asTextField;
            this._downNumOffset = this.getChild("downNumOffset").asTextField;
            this._leftNumOffset = this.getChild("leftNumOffset").asTextField;
            this._rightNumOffset = this.getChild("rightNumOffset").asTextField;
            this._singleNumText = this.getChild("singleNumText").asTextField;
            this._totalNumText = this.getChild("totalNumText").asTextField;
            this._saveBtn = this.getChild("saveBtn").asButton;
            this._addSkillBtn1.getChild("title").asTextField.textParser = Core.StringUtils.parseColorText;
            this._addSkillBtn2.getChild("title").asTextField.textParser = Core.StringUtils.parseColorText;

            this.getChild("backBtn").asButton.addClickListener(this._onBack, this);
            this.getChild("confirmBtn").asButton.addClickListener(this._onConfirm, this);
            this._uploadImgBtn.addClickListener(this._onUpLoadImg, this);
            this._saveBtn.addClickListener(this._onSave, this);
            this._addSkillBtn1.addClickListener(this._onChoiceSkill1, this);
            this._addSkillBtn2.addClickListener(this._onChoiceSkill2, this);
        }

        public async open(...param:any[]) {
            super.open(...param);
            this._reset();
        }

        public async close(...param:any[]) {
            super.close(...param);
            this._uploadImgData = null;
        }

        private _reset() {
            this._diySkillId1 = 0;
            this._diySkillId2 = 0;
            this._needWine1 = 0;
            this._needWine2 = 0;
            this._needBook1 = 0;
            this._needBook2 = 0;
            this._curCardData = null;
            //this._updateNumRange(0, 0, 0, 0);
            this._updateNeedResTxt();
            this._saveBtn.disabled = true;
            this._visibleNumOffset(false);
            this._uploadImgBtn.touchable = true;
            this._updateChoiceSkill();
            this._nameInput.title = "";
            this._updateNumText(0, 0, 0, 0);

            this._addSkillBtn1.touchable = true;
            this._addSkillBtn2.touchable = true;
            this._uploadImgBtn.touchable = true;
            this._nameInput.touchable = true;
        }

        private _visibleNumOffset(visible:boolean) {
            this._upNumOffset.visible = visible;
            this._downNumOffset.visible = visible;
            this._leftNumOffset.visible = visible;
            this._rightNumOffset.visible = visible;
        }

        private _updateChoiceSkill() {
            let singleMinNum = 0;
            let singleMaxNum = 0;
            let totalMinNum = 0;
            let totalMaxNum = 0;
            let self = this;
            let _update = function(skillBtn:fairygui.GButton, diySkillId:number) {
                if (diySkillId > 0) {
                    let diyData = Data.diy.get(diySkillId);
                    if (singleMinNum <= 0) {
                        singleMinNum = diyData.min_single;
                        singleMaxNum = diyData.max_single;
                        totalMinNum = diyData.min_total;
                        totalMaxNum = diyData.max_total;
                    } else {
                        singleMinNum = singleMinNum > diyData.min_single ? singleMinNum : diyData.min_single;
                        singleMaxNum = singleMaxNum < diyData.max_single ? singleMaxNum : diyData.max_single;
                        totalMinNum = totalMinNum > diyData.min_total ? totalMinNum : diyData.min_total;
                        totalMaxNum = totalMaxNum < diyData.max_total ? totalMaxNum : diyData.max_total;
                    }

                    skillBtn.title = DiyMgr.inst.getDiySkillName(diySkillId);
                    skillBtn.getChild("icon").visible = false;
                } else {
                    skillBtn.title = "";
                    skillBtn.getChild("icon").visible = true;
                }
            }

            _update(this._addSkillBtn1, this._diySkillId1);
            _update(this._addSkillBtn2, this._diySkillId2);
            this._updateNumRange(singleMinNum, singleMaxNum, totalMinNum, totalMaxNum);
        }

        private _updateNumText(up:number, down:number, left:number, right:number) {
            this._upNumText.text = up > 0 ? up.toString() : "";
            this._downNumText.text = down > 0 ? down.toString() : "";
            this._leftNumText.text = left > 0 ? left.toString() : "";
            this._rightNumText.text = right > 0 ? right.toString() : "";
        }

        private _updateNumRange(singleMin:number, singleMax:number, totalMin:number, totalMax:number) {
            this._singleNumText.text = `${singleMin} ~ ${singleMax}`
            this._totalNumText.text = `${totalMin} ~ ${totalMax}`
        }

        private _updateNeedResTxt() {
            this._wineAmountTxt.text = `x${this._needWine1 + this._needWine2}`;
            this._bookAmountTxt.text = `x${this._needBook1 + this._needBook2}`;
        }

        private _onChoiceSkill1() {
            this._onChoiceSkill(1);
        }

        private _onChoiceSkill2() {
            this._onChoiceSkill(2);
        }

        private _onChoiceSkill(idx:number) {
            if (idx != 1 && idx != 2) {
                return;
            }
            let viewMgr = Core.ViewManager.inst;
            let curSelectedSkillId = 0;
            let otherSelectedSkillId = 0;
            if (idx == 1) {
                otherSelectedSkillId = this._diySkillId2;
                curSelectedSkillId = this._diySkillId1;
            } else {
                otherSelectedSkillId = this._diySkillId1;
                curSelectedSkillId = this._diySkillId2;
            }
            viewMgr.open(ViewName.diySkillPanel, idx, curSelectedSkillId, otherSelectedSkillId);
        }

        private _onSave() {
            this._reset();
            this._saveBtn.disabled = true;
        }

        private _onUpLoadImg() {
            Core.TipsUtils.showTipsFromCenter("更换形象功能尚未开放！");
            //selectImage(this._selectedImgHandler, this);
        }

        private async _selectedImgHandler(thisObj:DiyView, imgURL:string, file:Blob) {
            thisObj._uploadImgData = await thisObj._loadSelectedImgData(file);
        }

        private async _loadSelectedImgData(imgFile:Blob): Promise<string> {
            return await new Promise<string>(resolve => {
                getImageData(imgFile, (thisObj:DiyView, imgBytes:ArrayBuffer) => {
                    egret.BitmapData.create("arraybuffer", imgBytes, (bitmapData:egret.BitmapData)=>{
                        let cardImg = <egret.Bitmap>this._cardImg.displayObject;
                        //cardImg.bitmapData = bitmapData;
                        cardImg.$setBitmapData(bitmapData);
                    });
                    resolve( egret.Base64Util.encode(imgBytes) );
                }, this);
            });
        }

        private _checkCondition(): boolean {
            if (this._needBook1 + this._needBook2 > Player.inst.getResource(ResType.T_BOOK)) {
                Core.TipsUtils.showTipsFromCenter("你的书不够");
                return false;
            }
            if (this._needWine1 + this._needWine2 > Player.inst.getResource(ResType.T_WINE)) {
                Core.TipsUtils.showTipsFromCenter("你的酒不够");
                return false;
            }
            if (!this._nameInput.text || this._nameInput.text.trim().length == 0) {
                Core.TipsUtils.showTipsFromCenter("请输入名字");
                return false;
            } else if (this._nameInput.text.trim().length >= 8) {
                Core.TipsUtils.showTipsFromCenter("你的名字太长了");
                return false;
            }
            if (!this._diySkillId1 || this._diySkillId1 <= 0 || !this._diySkillId2 || this._diySkillId2 <= 0) {
                Core.TipsUtils.showTipsFromCenter("请选好两个技能");
                return false;
            }
            return true;
        }

        private async _playScrollNumEffect(numText:fairygui.GTextField, targetNum:number) {
            let scrollNum = new DiyScrollNum();
            await scrollNum.playEffect(numText, targetNum);
            numText.text = targetNum.toString();
        }

        private async _playDiyDoneEffect(diyCardData:any) {
            this._updateNumText(0, 0, 0, 0);
            Core.MaskUtils.showTransMask();
            let ps:Promise<void>[] = [];
            ps.push( this._playScrollNumEffect(this._upNumText, diyCardData.MinUp) );
            ps.push( this._playScrollNumEffect(this._downNumText, diyCardData.MinDown) );
            ps.push( this._playScrollNumEffect(this._leftNumText, diyCardData.MinLeft) );
            ps.push( this._playScrollNumEffect(this._rightNumText, diyCardData.MinRight) );
            await Promise.all(ps);
            this._visibleNumOffset(true);
            Core.MaskUtils.hideTransMask();
        }
        
        private async _doDiy() {
            if (!this._checkCondition()) {
                return;
            }

            let diyCardData:any;
            if (this._curCardData) {
                diyCardData = await DiyMgr.inst.doAgainDiy(this._curCardData.CardId);
            } else {
                diyCardData = await DiyMgr.inst.doDiy(this._nameInput.text.trim(), this._diySkillId1, this._diySkillId2, 
                    this._weaponCtrl.selectedPage, this._uploadImgData);
            }
            if (!diyCardData) {
                return;
            }
            this._curCardData = diyCardData;
            
            await this._playDiyDoneEffect(diyCardData); 
            this._saveBtn.disabled = false;
            this._addSkillBtn1.touchable = false;
            this._addSkillBtn2.touchable = false;
            this._uploadImgBtn.touchable = false;
            this._nameInput.touchable = false;
        }

        private _onConfirm() {
            Core.TipsUtils.confirm("are you 确定 ?", this._doDiy, null, this);
        }

        public onConfirmChoiceSkill(skillIdx:number, diySkillId:number) {
            let diySkillData = Data.diy.get(diySkillId);
            if (diySkillData == null) {
                return;
            }

            if (skillIdx == 1) {
                this._diySkillId1 = diySkillId;
                this._needWine1 = diySkillData.wine;
                this._needBook1 = diySkillData.book;
            } else if (skillIdx == 2) {
                this._diySkillId2 = diySkillId;
                this._needWine2 = diySkillData.wine;
                this._needBook2 = diySkillData.book;
            } else {
                return;
            }

            this._updateChoiceSkill();
            this._updateNeedResTxt();
        }

        private _onBack() {
            //Core.ViewManager.inst.open(ViewName.match);
            Core.ViewManager.inst.closeView(this);
        }
    }

}