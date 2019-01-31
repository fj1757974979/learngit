module Core {

    export class EffectUtil {

        private static rotationSet:Collection.Set<number>;

        /**
         * 对象旋转特效
         * @param display   旋转对象
         * @param time  旋转一周用时，毫秒
         */
        public static rotationEffect(display:fairygui.GObject, time:number = 1000):void{
            if(this.rotationSet == null){
                this.rotationSet = new Collection.Set<number>();
            }
            if(this.rotationSet.contains(display.hashCode)) {
                return;
            }

            this.rotationSet.add(display.hashCode);
            let onComplete1:Function = function(){
                if(this.rotationSet.contains(display.hashCode)){
                    display.rotation = 0;
                    egret.Tween.get(display).to({rotation:360},time).call(onComplete1,this);   
                }
            };
            display.rotation = 0;
            egret.Tween.get(display).to({rotation:360},time).call(onComplete1,this);
        }

        /**
         * 取消对象旋转
         * @param display    旋转对象
         */
        public static removeRotationEffect(display:fairygui.GObject):void{
            if(this.rotationSet == null){
                this.rotationSet = new Collection.Set<number>();
            }
            this.rotationSet.remove(display.hashCode);
        }

        public static showLeftToRight(display:fairygui.GObject): Promise<void> {
            if(display.parent == null){
                LayerManager.inst.maskLayer.addChild( display );
            }

            display.alpha = 0;

            return new Promise<void>(resolve => {
                display.y = fairygui.GRoot.inst.height / 2 - display.height / 2;
                display.x = - display.width;

                egret.Tween.get(display).to({x:fairygui.GRoot.inst.width/2 - display.width/2 - 50,alpha:1},300,egret.Ease.sineInOut);
                
                fairygui.GTimers.inst.add(580, 1, ()=>{
                    egret.Tween.get(display).to({x:display.x + 100},800).to({x:fairygui.GRoot.inst.width},300,egret.Ease.sineIn).call(()=>{
                        if(display.parent != null){
                            display.parent.removeChild( display );
                        }
                        resolve();
                    }, this);
                }, this);

            }) 
        }

        public static showFromCenter(display:fairygui.GObject, showTime:number=350, stayTime:number=900, hideTime:number=400): Promise<void> {
            if(display.parent == null){
                LayerManager.inst.maskLayer.addChild( display );
                display.y = fairygui.GRoot.inst.height / 2;
                display.x = fairygui.GRoot.inst.width / 2; 
            }
            
            display.alpha = 0;
            display.setPivot(0.5, 0.5, true);
            display.setScale(0, 0);
            
            return new Promise<void>(resolve => {
                egret.Tween.get(display).to({scaleX:1,scaleY:1,alpha:1}, showTime).wait(stayTime).to({alpha:0},hideTime).call(()=>{
                    display.removeFromParent();
                    resolve();
                }, this); 
            });
        }

        public static async blink(display:fairygui.GComponent, color:number=Core.TextColors.white) {
            let mask = new fairygui.GGraph();
            mask.width = display.width;
            mask.height = display.height;
            mask.drawRect(0, color, 0, color, 0.8, [7]);
            display.addChild(mask);

            await new Promise<void>(resolve => {
                egret.Tween.get(mask).to({alpha:0.4}, 110).wait(35).call(()=>{
                    display.removeChild(mask);
                }, null).wait(263).call(()=>{
                    resolve();
                }, this);
            })
        }

    }

}