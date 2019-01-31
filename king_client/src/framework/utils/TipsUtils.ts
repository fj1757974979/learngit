module Core {

    export interface ITipsCom extends fairygui.GObject {
        show(msg:string): Promise<void>
    }

    class DefTipsCom extends fairygui.GTextField implements ITipsCom {

        public show(msg:string): Promise<void> {
            this.textParser = StringUtils.parseColorText;
            this.color = TextColors.red;
            this.text = msg;
            this.fontSize = UIConfig.defaultFontSize;
            //effectTips.strokeColor = TextColors.black;
            //effectTips.stroke  = 3;
            this.align = fairygui.AlignType.Center;
            this.verticalAlign = fairygui.VertAlignType.Middle;
            this.font = UIConfig.defaultFont;
            this.bold = true;
            this.stroke = 2;
            this.alpha = 0;
            this.visible = true;
            
            if (this.width > 400) {
                this.autoSize = fairygui.AutoSizeType.Height;
                this.width = 400;
                this.text = msg;
            }
        
            this.y = fairygui.GRoot.inst.height / 2;
            this.x = fairygui.GRoot.inst.width / 2 - this.width / 2; 
            
            return new Promise<void>(resolve => {
                egret.Tween.get(this).to({y:this.y - 120,alpha:1},800,egret.Ease.backOut).wait(100).to({alpha:0},600).call(()=>{
                    resolve();
                }, this); 
            });
        }
    }

    export class TipsUtils {
        private static _confirmPanel: fairygui.Window;
        private static _alertPanel: fairygui.Window;
        private static _privPanel: fairygui.Window;
        private static _flagTips: fairygui.Window;
        public static newTipsCom: () => ITipsCom;

        private _time: number;

        public static showTipsFromCenter(msg:string) {
            let com: ITipsCom;
            if (!TipsUtils.newTipsCom) {
                com = new DefTipsCom();
            } else {
                com = TipsUtils.newTipsCom();
            }
            LayerManager.inst.maskLayer.addChild(com);
            com.show(msg).then(()=>{
                com.removeFromParent();
            });
        }
        public static registerConfirmPanel(panel: IConfirmPanel) {
            if (!TipsUtils._confirmPanel) {
                TipsUtils._confirmPanel = new fairygui.Window();
            }
            TipsUtils._confirmPanel.contentPane = panel;
            TipsUtils._confirmPanel.modal = true;
            panel.getTitle().funcParser = StringUtils.parseFuncText;
        }

        public static registerAlertPanel(panel: IAlertPanel) {
            if (!TipsUtils._alertPanel) {
                TipsUtils._alertPanel = new fairygui.Window();
            }
            TipsUtils._alertPanel.contentPane = panel;
            TipsUtils._alertPanel.modal = true;
            panel.getTitle().funcParser = StringUtils.parseFuncText;
        }
        public static registerPrivPanel(panel: fairygui.GComponent) {
            if (!TipsUtils._privPanel) {
                TipsUtils._privPanel = new fairygui.Window();
            }
            TipsUtils._privPanel.contentPane = panel;       
        }
        public static registerFlagPanel(panel: fairygui.GComponent) {
            if (!TipsUtils._flagTips) {
                TipsUtils._flagTips = new fairygui.Window();
            }
            TipsUtils._flagTips.contentPane = panel as FlagShowPanel;
        }
        /**
        * @param 发动特权的id
        *
        */
        public static privTips(priv: Priv) {
            if (!TipsUtils._privPanel) {
                return ;
            }
            let contentPane = <PrivShowPanel>TipsUtils._privPanel.contentPane;
            let privList = contentPane.showTip(priv);       
            Core.LayerManager.inst.topLayer.root.showWindow(TipsUtils._privPanel);
        }
        public static closePrivTips() {
            Core.LayerManager.inst.topLayer.root.hideWindow(TipsUtils._privPanel);
        }
        public static closeFlagTips() {
            Core.LayerManager.inst.topLayer.root.hideWindow(TipsUtils._flagTips);
        }
        /**
         * @param 显示旗帜
         * 
         */
        public static flagTips(oldCnt: number, newCnt: number) {
            if (!TipsUtils._flagTips) {
                return;
            }
            let contentPane = <FlagShowPanel>TipsUtils._flagTips.contentPane;
            contentPane.showTip(oldCnt, newCnt);
            Core.LayerManager.inst.topLayer.root.showWindow(TipsUtils._flagTips);
        }

        // 关闭投降界面 wuchao
        public static closeConfirmPanel() {
            if (!TipsUtils._confirmPanel) {
                return ;
            }
            if (TipsUtils._confirmPanel.visible) {
                //fairygui.GRoot.inst.hideWindow(TipsUtils._confirmPanel);
                Core.LayerManager.inst.topLayer.root.hideWindow(TipsUtils._confirmPanel);
            } 
            
        }
        public static closeAlertPanel() {
            if (!TipsUtils._alertPanel) {
                return;
            }
            if (TipsUtils._alertPanel.visible) {
                Core.LayerManager.inst.topLayer.root.hideWindow(TipsUtils._alertPanel);
            }
        }
        /**
         * 确认框
         * @param title       标题
         * @param cancelFun      取消方法
         * @param acceptFun      确认方法
         * @param thisObj
         * @param effectType        0：没有动画 1:从中间轻微弹出 2：从中间猛烈弹出  3：从左向右 4：从右向左 5、从上到下 6、从下到上
        */
        public static confirm(title:string = "", acceptFun:Function=null, cancelFun:Function=null, thisObj:any=null,
            acceptTitle:string=Core.StringUtils.TEXT(60047), cancelTitle:string=Core.StringUtils.TEXT(60046), effectType:number = 1) {
            if (!TipsUtils._confirmPanel) {
                return;
            }

            let contentPane = <IConfirmPanel>TipsUtils._confirmPanel.contentPane;

            async function _onAccept() {
                contentPane.getAcceptBtn().removeClickListener(_onAccept, this);
                contentPane.getCancelBtn().removeClickListener(_onCancel, this);
                if (acceptFun) {
                    acceptFun.apply(thisObj);
                }
                //await PopUpUtils.removePopUp(TipsUtils._confirmPanel);
                fairygui.GRoot.inst.hideWindow(TipsUtils._confirmPanel);
            }

            async function _onCancel() {
                contentPane.getAcceptBtn().removeClickListener(_onAccept, this);
                contentPane.getCancelBtn().removeClickListener(_onCancel, this);
                if (cancelFun) {
                    cancelFun.apply(thisObj);
                }
                //await PopUpUtils.removePopUp(TipsUtils._confirmPanel);
                Core.LayerManager.inst.topLayer.root.hideWindow(TipsUtils._confirmPanel);
                //fairygui.GRoot.inst.hideWindow(TipsUtils._confirmPanel);
            }
            
            let acceptBtn = contentPane.getAcceptBtn();
            acceptBtn.title = acceptTitle;
            acceptBtn.addClickListener(_onAccept, this);
            let cancelBtn = contentPane.getCancelBtn();
            cancelBtn.title = cancelTitle;
            cancelBtn.addClickListener(_onCancel, this);
            contentPane.getTitle().text = title;
            //TipsUtils._confirmPanel.show();
            Core.LayerManager.inst.topLayer.root.showWindow(TipsUtils._confirmPanel);
            TipsUtils._confirmPanel.center();
            PopUpUtils.addPopUp(TipsUtils._confirmPanel, effectType);
        }

        /**
         * 提示框
         * @param title       标题
         * @param acceptFun      确认方法
         * @param thisObj
         * @param effectType        0：没有动画 1:从中间轻微弹出 2：从中间猛烈弹出  3：从左向右 4：从右向左 5、从上到下 6、从下到上
        */
        public static alert(title:string = "", acceptFun:Function=null, thisObj:any=null, acceptTitle:string=Core.StringUtils.TEXT(60047), effectType:number = 1) {
            if (!TipsUtils._alertPanel) {
                return;
            }

            let contentPane = <IConfirmPanel>TipsUtils._alertPanel.contentPane;

            async function _onAccept() {
                contentPane.getAcceptBtn().removeClickListener(_onAccept, this);
                if (acceptFun) {
                    acceptFun.apply(thisObj);
                }
                Core.LayerManager.inst.topLayer.root.hideWindow(TipsUtils._alertPanel);
                //PopUpUtils.removePopUp(TipsUtils._alertPanel, 0);
            }
            
            let acceptBtn = contentPane.getAcceptBtn()
            acceptBtn.title = acceptTitle;
            acceptBtn.addClickListener(_onAccept, this);
            contentPane.getTitle().text = title;
            Core.LayerManager.inst.topLayer.root.showWindow(TipsUtils._alertPanel);
            //TipsUtils._alertPanel.show();
            TipsUtils._alertPanel.center();
            // if (!TipsUtils._alertPanel.parent) {
                //Core.LayerManager.inst.topLayer.addChild(TipsUtils._alertPanel);
            // }
            PopUpUtils.addPopUp(TipsUtils._alertPanel, effectType);
            return TipsUtils._alertPanel;
        }
        

        /**
         * 
         * @param effectType        0：没有动画 1:从下到上渐现 2：从左向右 3：从右向左
         */
        public static showTipsFromTarget(display:fairygui.GObject, effectType:number=1, target:fairygui.GObject=null) { 
            egret.Tween.removeTweens(display);
            fairygui.GRoot.inst.showPopup(display, target);

            switch (effectType)
            {
                case 0: {
                    display.alpha = 0;
                    egret.Tween.get(display).to({alpha:1},300);  
                    break;
                }
                case 1: {
                    display.alpha = 0;
                    display.y += display.height;
                    egret.Tween.get(display).to({alpha:1,y:display.y - display.height},500,egret.Ease.backOut); 	                
                    break;
                }
                case 2: {
                    display.alpha = 0;
                    display.x -= display.width;
                    egret.Tween.get(display).to({alpha:1,x:display.x + display.width},500,egret.Ease.backOut); 
                    break;
                }
                case 3: {
                    display.alpha = 0;
                    display.x += display.width;
                    egret.Tween.get(display).to({alpha:1,x:display.x - display.width},500,egret.Ease.backOut); 
                    break;
                }
                default: {
                }
            }
        }
    }

}
