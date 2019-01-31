module Social {

    export class HeadCom extends fairygui.GComponent {
        
        private _bg: fairygui.GLoader;
        private _icon: fairygui.GImage;
        private _frame: fairygui.GLoader;

         protected constructFromXML(xml:any) {
			super.constructFromXML(xml);

			this._bg = this.getChild("n0").asLoader;
			this._icon = this.getChild("headIcon").asImage;
            this._frame = this.getChild("headFrame").asLoader;
		}


        public setAll(headIcon: string, frameIcon: string) {
            this.setHead(headIcon);
            this.setFrame(frameIcon);
        }
        public setHead(headIcon: string) {
            if (headIcon.trim() == "") {
                this._icon.visible = false;
            } else {
                this._icon.visible = true;
                Utils.setImageUrlPicture(this._icon, headIcon);    
            }
        }
        public setFrame(frameIcon: string) { 
            this.visible = true;
            let frameIconNum = parseInt(frameIcon);
            if (!isNaN(frameIconNum)) {
                frameIcon = `headframe_${frameIconNum}_png`;
            }
            this._frame.url = frameIcon;
        }
    }

}