module Core {

    export class UIConstructor {
        private __constructor: () => IBaseView;

        public constructor(func: () => IBaseView) {
            this.__constructor = func;
        }

        public call(): IBaseView {
            return this.__constructor();
        }
    }

    export class ViewManager {
        private static _inst: ViewManager;

        /**
         * 已注册的UI
         */
        private _views: Collection.Dictionary<string, IBaseView>;

        /**
         * 开启中UI
         */
        private _opens: Collection.Set<string>;

        /**
         * 注册的UI构造函数
         */
        private _viewConstructors: Collection.Dictionary<string, UIConstructor>;
        private _viewPreload: Collection.Dictionary<string, () => Promise<any>>;

        private _opening: Collection.Dictionary<string, Promise<void>>;
        private _closing: Collection.Dictionary<string, Promise<void>>;
        private _registerViews:Array<string>;

        public constructor() {
            this._views = new Collection.Dictionary<string, IBaseView>();
            this._opens = new Collection.Set<string>();
            this._opening = new Collection.Dictionary<string, Promise<void>>();
            this._closing = new Collection.Dictionary<string, Promise<void>>();

            this._viewConstructors = new Collection.Dictionary<string, UIConstructor>();
            this._viewPreload = new Collection.Dictionary<string, () => Promise<any>>();
            this._registerViews = [];
        }

        public static get inst(): ViewManager {
            if (!ViewManager._inst) {
                ViewManager._inst = new ViewManager();
            }
            return ViewManager._inst;
        }

        /**
         * 面板注册
         * @param name 面板名字，唯一标识
         * @param view 面板
         */
        public register(name:string, view:IBaseView):void {
            if (view == null) {
                console.log("UI_" + name + " is null!");
                return;
            }
            if (this._views.getValue(name)) {
                console.log("UI_" + name + " is registered!");
                return;
            }
            view.name = name;
            this._views.setValue(name, view);
        }

        /**
         * 面板解除注册
         * @param name
         */
        public unregister(name:string):void {
            this._views.remove(name);
        }

        /**
         * 注册面板构造函数
         */
        public registerConstructor(name: string, func: () => IBaseView, preload: () => Promise<any> = null) {
            if (this._viewConstructors.containsKey(name)) {
                this._viewConstructors.remove(name);
            }
            if (this._viewPreload.containsKey(name)) {
                this._viewPreload.remove(name);
            }
            this._viewConstructors.setValue(name, new UIConstructor(func));
            this._viewPreload.setValue(name, preload);
            this._registerViews.push(name);
        }

        public registerView(name:string, func: () => IBaseView) {
            if (Core.DeviceUtils.isWXGame()) {
                this.registerConstructor(name, func);
            } else {
                this.register(name, func());
            }
        }

        /**
         * 销毁一个面板
         * @param name 唯一标识
         */
        public destroy(name:string):void {
            let view:IBaseView = this.getView(name);
            if (view) {
                this.unregister(name);
                view.destroy();
                view = null;
            }
        }

        public createAllView() {
            this._registerViews.forEach((value, index, arr) => {
                this.tryCreateView(value);
            });
        }

        public async tryCreateView(name:string) {
            if (this._views.getValue(name)) return;
            let view:IBaseView = null;
            let constructor = this._viewConstructors.getValue(name);
            // console.log(`create view ${name}`);
            let preload = this._viewPreload.getValue(name);
            if (constructor == null) {
                console.log("UI_" + name + " not exist");
                return;
            } else {
                if (preload) await preload();
                try {
                    view = constructor.call();
                    view.setVisible(false);
                    view.initUI();
                    this.register(name, view);
                } catch (e) {
                    console.error("create view error", name, e);
                }
            }
        }

        /**
         * 开启面板
         * @param name 面板唯一标识
         * @param param 参数
         *
         */
        public async open(name:string, ...param:any[]) {
            await this.tryCreateView(name);
            let view:IBaseView = this.getView(name);
            if (view == null) return;
            /*
            if (view.isShow()) {
                //await view.open.apply(view, param);
                return;
            }
            */
            let openPromise = this._opening.getValue(name);
            if (openPromise) {
                await openPromise;
                return
            }

            view.setVisible(true);
            if (view.isInit()) {
                view.addToParent();
                let openPromise = view.open.apply(view, param);
                this._opening.setValue(name, openPromise);
                await openPromise;
                this._opening.remove(name);
            } else {
                view.addToParent();
                view.initUI();
                let openPromise = (<Promise<void>>view.open.apply(view, param));
                this._opening.setValue(name, openPromise);
                await openPromise;
                this._opening.remove(name);
            }

            this._opens.add(name);
            EventCenter.inst.dispatchEventWith(Event.OpenViewEvt, false, name);
        }

        /**
         * 开启面板，如果是窗口类，则以popup的形式打开
         * @param name 面板唯一标识
         * @param param 参数
         *
         */
        public async openPopup(name:string, ...param:any[]) {
            await this.tryCreateView(name);
            let view:IBaseView = this.getView(name);
            if (view == null) return;

            let openPromise = this._opening.getValue(name);
            if (openPromise) {
                await openPromise;
                return
            }
            view.setVisible(true);
            if (view instanceof Core.BaseWindow) {
                let wnd = <Core.BaseWindow>view;
                if (wnd.isInit()) {
                    let openPromise = wnd.open.apply(wnd, param);
                    this._opening.setValue(name, openPromise);
                    await openPromise;
                    this._opening.remove(name);
                } else {
                    wnd.initUI();
                    let openPromise = (<Promise<void>>wnd.open.apply(wnd, param));
                    this._opening.setValue(name, openPromise);
                    await openPromise;
                    this._opening.remove(name);
                }
                let x = wnd.x;
                let y = wnd.y;
                fairygui.GRoot.inst.showPopup(wnd);
                wnd.x = x;
                wnd.y = y;
                // wnd.center();
                this._opens.add(name);
                EventCenter.inst.dispatchEventWith(Event.OpenViewEvt, false, name);
            } else {
                await this.open(name, ...param);
            }
        }

        /**
         * 关闭面板
         * @param name 面板唯一标识
         * @param param 参数
         *
         */
        public async close(name:string, ...param:any[]) {
            try {

                //console.log(`close ${name}`);
                if (!this.isShow(name)) {
                    return;
                }

                let view:IBaseView = this.getView(name);
                if (view == null) {
                    return;
                }

                let closePromise = this._closing.getValue(name);
                if (closePromise) {
                    await closePromise;
                    return;
                }
                //console.log(`close ${name}`);
                closePromise = new Promise<void>(reslove => {
                    (<Promise<void>>view.close.apply(view, param)).then(()=>{
                        view.removeFromParent();
                        reslove();
                    }).catch(e => {
                        console.error("close view 1111 ", name, " ", e);
                        view.removeFromParent();
                        reslove();
                    });
                });

                this._closing.setValue(name, closePromise);
                await closePromise;
                this._closing.remove(name);
                this._opens.remove(name);
                if (this._viewConstructors.containsKey(name)) {
                    //this.destroy(name);
                }
                EventCenter.inst.dispatchEventWith(Event.CloseViewEvt, false, name);

            } catch(e) {
                console.error("close view ", name, " ", e);
            }
        }

        public async openView(view:IBaseView, ...param:any[]) {
            await this.open(view.name, ...param);
        }

        /**
         * 关闭面板
         * @param view
         * @param param
         */
        public async closeView(view:IBaseView, ...param:any[]) {
            await this.close(view.name, ...param);
        }

        /**
         * 根据唯一标识获取一个UI对象
         * @param key
         * @returns {any}
         */
        public getView(name:string):IBaseView {
            //this.tryCreateView(name);
            return this._views.getValue(name);
        }

        /**
         * 关闭所有开启中的UI
         */
        public async closeAll() {
            let ps = [];
            this._opens.toArray().forEach(name => {
                ps.push( this.close(name) );
            })
            await Promise.all(ps);
            this._opens = new Collection.Set<string>();
            this._opening = new Collection.Dictionary<string, Promise<void>>();
            this._closing = new Collection.Dictionary<string, Promise<void>>();
        }

        /**
         * 检测一个UI是否开启中
         * @param name
         * @returns {boolean}
         */
        public isShow(name:string):boolean {
            return this._opens.contains(name);
        }
    }

}
