module Core {

    export class PopUpUtils {
        private static _darkSprite: fairygui.GGraph;

        /**
        * 添加面板方法
        * @param display      显示对象
        * @param dark         背景是否变黑
        * @param popUpWidth   指定弹窗宽度，定位使用
        * @param popUpHeight  指定弹窗高度，定位使用
        * @param effectType   0：没有动画 1:从中间轻微弹出 2：从中间猛烈弹出  3：从左向右 4：从右向左 5、从上到下 6、从下到上
        *                     7: 中间放大
        */
        public static async addPopUp(display:fairygui.GObject, effectType:number=0, dark:boolean=false, popUpWidth:number=0, popUpHeight:number=0) { 
            if (!display.parent) {
                fairygui.GRoot.inst.addChild(display);
            }

            display.scaleX = 1;
            display.scaleY = 1;
            //display.x = 0;
            //display.y = 0;
            display.alpha = 1;
            
            if(dark){
                if (!PopUpUtils._darkSprite) {
                    PopUpUtils._darkSprite = new fairygui.GGraph();
                    PopUpUtils._darkSprite.graphics.clear();
                    PopUpUtils._darkSprite.graphics.beginFill(0x000000, 0.3);
                    PopUpUtils._darkSprite.graphics.drawRect(0, 0, fairygui.GRoot.inst.width, fairygui.GRoot.inst.height);
                    PopUpUtils._darkSprite.graphics.endFill();
                    PopUpUtils._darkSprite.width = fairygui.GRoot.inst.width;
                    PopUpUtils._darkSprite.height = fairygui.GRoot.inst.height;
                }
                if(!PopUpUtils._darkSprite.parent) {
                    LayerManager.inst.maskLayer.addChild(PopUpUtils._darkSprite);
                }
                PopUpUtils._darkSprite.touchable = true;
                PopUpUtils._darkSprite.visible = true;
                egret.Tween.get(PopUpUtils._darkSprite).to({alpha:1}, 150);
            }

            if(popUpWidth != 0){
                display.x = fairygui.GRoot.inst.width/2 - display.width / 2;
                display.y = fairygui.GRoot.inst.height/2 - display.height / 2;
            }else{
                popUpWidth = display.width;
                popUpHeight = display.height;
            }

            //以下是弹窗动画
            let leftX:number = fairygui.GRoot.inst.width/2 - popUpWidth/2;
            let upY:number = fairygui.GRoot.inst.height/2 - popUpHeight/2;

            await new Promise<void>(resolve => {
                let _onDone = function () {
                    resolve();
                }

                switch(effectType){
                case 0:
                    _onDone()
                    break;
                case 1:
                    display.alpha = 0;
                    display.scaleX = 0.5;
                    display.scaleY = 0.5;
                    display.x = display.x + popUpWidth/4;
                    display.y = display.y + popUpHeight/4;
                    egret.Tween.get(display).to({alpha:1,scaleX:1,scaleY:1,x:display.x - popUpWidth/4,y:display.y - popUpHeight/4},300,
                        egret.Ease.backOut).call(_onDone, this); 
                    break;
                case 2:
                    display.alpha = 0;
                    display.scaleX = 0.5;
                    display.scaleY = 0.5;
                    display.x = display.x + popUpWidth/4;
                    display.y = display.y + popUpHeight/4;
                    egret.Tween.get(display).to({alpha:1,scaleX:1,scaleY:1,x:display.x - popUpWidth/4,y:display.y - popUpHeight/4},600,
                        egret.Ease.elasticOut).call(_onDone, this); 
                    break;
                case 3:
                    display.x = - popUpWidth;
                    egret.Tween.get(display).to({x:leftX},500,egret.Ease.cubicOut).call(_onDone, this); 
                    break;
                case 4:
                    display.x = popUpWidth;
                    egret.Tween.get(display).to({x:leftX},500,egret.Ease.cubicOut).call(_onDone, this);  
                    break;
                case 5:
                    display.y = - popUpHeight;
                    //egret.Tween.get(display).to({y:upY},500,egret.Ease.cubicOut).call(_onDone, this); 
                    egret.Tween.get(display).to({y:upY}, 500).call(_onDone, this);
                    break;
                case 6:
                    display.y = fairygui.GRoot.inst.height;
                    egret.Tween.get(display).to({y:upY},500,egret.Ease.cubicOut).call(_onDone, this); 
                    break;
                case 7:
                    display.scaleX = 0.5;
                    display.scaleY = 0.5;
                    egret.Tween.get(display).to({scaleX:1, scaleY:1}, 300, egret.Ease.backOut).call(_onDone, this);
                    break;
                default:
                    _onDone();
                    break;
                }		

            })
        } 

        /**
        * 移除面板方法
        * @param display     显示对象
        * @param effectType  0：没有动画 1:从中间缩小消失 2：  3：从左向右 4：从右向左 5、从上到下 6、从下到上
        */
        public static async removePopUp(display:fairygui.GObject, effectType:number=0) { 

            if(PopUpUtils._darkSprite && PopUpUtils._darkSprite.parent){
                egret.Tween.get(PopUpUtils._darkSprite).to({alpha:0},100).call(()=>{
                    if (PopUpUtils._darkSprite) {
                        PopUpUtils._darkSprite.removeFromParent();
                    }
                }, this);      
            }

            //以下是弹窗动画
            switch(effectType){
                case 0:
                    break;
                case 1:
                    egret.Tween.get(display).to({alpha:0,scaleX:0,scaleY:0,x:display.x + display.width/2,y:display.y + display.height/2},300); 
                    break;
                case 2:
                    break;
                case 3:
                    egret.Tween.get(display).to({x:display.width},500,egret.Ease.cubicOut); 
                    break;
                case 4:
                    egret.Tween.get(display).to({x:-display.width},500,egret.Ease.cubicOut);        
                    break;
                case 5:
                    egret.Tween.get(display).to({y:display.height},500,egret.Ease.cubicOut);             
                    break;
                case 6:
                    egret.Tween.get(display).to({y:-display.height},500,egret.Ease.cubicOut);              
                    break;
                case 7:
                    egret.Tween.get(display).to({scaleX:0, scaleY:0}, 300, egret.Ease.backIn);
                    break;
                default:
                    break;
            }        
            
            let waitTime = 500;
            if(effectType == 0){
                waitTime = 0;
            }

            await new Promise<void>(resolve=>{
                fairygui.GTimers.inst.callDelay(waitTime, ()=>{
                    display.removeFromParent();
                    resolve();
                }, this);
            })   
        } 

    }

}