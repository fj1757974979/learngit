module Core {

    export class MaskUtils {
        private static transMask: fairygui.GGraph;
        private static netMask: IBaseView;
        private static _timeoutHdr: () => void = null;
        private static _forbidTimeout: boolean = true;

        public static showTransMask() {
            if (!MaskUtils.transMask) {
                MaskUtils.transMask = new fairygui.GGraph();
                MaskUtils.transMask.graphics.clear();
                MaskUtils.transMask.graphics.beginFill(0x000000, 0);
                MaskUtils.transMask.graphics.drawRect(0, 0, fairygui.GRoot.inst.width, fairygui.GRoot.inst.height);
                MaskUtils.transMask.graphics.endFill();
                MaskUtils.transMask.width = fairygui.GRoot.inst.getDesignStageWidth();
                MaskUtils.transMask.height = fairygui.GRoot.inst.getDesignStageHeight();
                MaskUtils.transMask.x = fairygui.GRoot.inst.width / 2 - MaskUtils.transMask.width / 2;
                MaskUtils.transMask.y = fairygui.GRoot.inst.height / 2 - MaskUtils.transMask.height / 2;
                
                MaskUtils.transMask.touchable = true;     
                MaskUtils.transMask.visible = true;
                //MaskUtil.transMask.alpha = 0;
            }

            if (MaskUtils.transMask.parent) {
                return;
            }

            LayerManager.inst.topLayer.addChild(MaskUtils.transMask);
        }

        public static hideTransMask() {
            if (!MaskUtils.transMask) {
                return;
            }
            if (MaskUtils.transMask.parent) {
                MaskUtils.transMask.parent.removeChild(MaskUtils.transMask);
            }
        }

        public static registerNetMask(mask: IBaseView) {
            MaskUtils.netMask = mask;
            MaskUtils.netMask.initUI();
        }

        public static showNetMask() {
            if (!MaskUtils.netMask) {
                return;
            }
            MaskUtils.netMask.open();
            if (Core.DeviceUtils.isWXGame() && !this._forbidTimeout) {
                if (MaskUtils._timeoutHdr) {
                    fairygui.GTimers.inst.remove(this._timeoutHdr, this);
                }
                this._timeoutHdr = () => {
                    MaskUtils._netTimeoutAlert();
                }
                fairygui.GTimers.inst.add(10 * 1000, 1, this._timeoutHdr, this);
            }
        }

        public static hideNetMask() {
            if (!MaskUtils.netMask) {
                return;
            }
            if (Core.DeviceUtils.isWXGame() && !this._forbidTimeout) {
                if (MaskUtils._timeoutHdr) {
                    fairygui.GTimers.inst.remove(this._timeoutHdr, this);
                    MaskUtils._timeoutHdr = null;
                }
            }
            MaskUtils.netMask.close();
        }

        private static _netTimeoutAlert() {
            if (!Core.DeviceUtils.isWXGame()) {
                return;
            }
            MaskUtils._timeoutHdr = null;
            Core.TipsUtils.alert(Core.StringUtils.TEXT(60216), () => {
                WXGame.WXGameMgr.inst.exitGame();
            }, this, Core.StringUtils.TEXT(60024));
        }

        public static forbidTimeout(b: boolean) {
            this._forbidTimeout = b;
            if (b && MaskUtils._timeoutHdr) {
                fairygui.GTimers.inst.remove(this._timeoutHdr, this);
                MaskUtils._timeoutHdr = null;
            }
        }
    }

}