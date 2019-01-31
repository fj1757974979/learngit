//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (c) 2014-present, Egret Technology.
//  All rights reserved.
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the Egret nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY EGRET AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL EGRET AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;LOSS OF USE, DATA,
//  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//////////////////////////////////////////////////////////////////////////////////////
class LoadingResource implements RES.ResourceItem {
    public name:string;
    public url:string;
    public type:string;
    public data:RES.ResourceInfo;
    public root:string;
    constructor(name) {
        this.name = name;
    };
}

class LoadingReporter implements RES.PromiseTaskReporter {

    private _name:string;
    private _parent:LoadingView;
    private _res:LoadingResource;

    constructor(parent:LoadingView, name:string) {
        this._name = name;
        this._parent = parent;
        this._parent.addRes(name);
        this._res = new LoadingResource(name);
    }

    public onProgress(current: number, total: number):void {
        this._parent.onProgress(current, total, this._res);
    }
}

class LoadingView extends Core.BaseView implements RES.PromiseTaskReporter {
    private _progressBar: UI.MaskProgressBar;
    private _bg:fairygui.GLoader;
    private _titleAdd: string = null;
    private _resDict:Collection.Dictionary<string,number>;


        static _inst:LoadingView;

        static get inst() : LoadingView {
            return LoadingView._inst;
        }

    public initUI() {
        LoadingView._inst = this;
        super.initUI();
        // if (!window.gameGlobal.isMultiLan) {
        //     this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
        // } else {
        //     this.adjust(this.getChild("bg"), Core.AdjustType.EXACT_FIT);        
        // }

        if (window.gameGlobal.isMultiLan) {
            this.getChild("isnbTxt").asTextField.visible = false;
            this.getChild("goodTxt").asTextField.visible = false;
            // logo
            let logo = new fairygui.GLoader();
            logo.url = "loading_logoName_png";
            logo.autoSize = false;
            logo.fill = fairygui.LoaderFillType.ScaleMatchWidth;
            logo.x = 0;
            logo.y = 58;
            logo.addRelation(this.getChild("bg"), fairygui.RelationType.Top_Top);
            this.addChild(logo);
            this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
            logo.width = Math.min(fairygui.GRoot.inst.getDesignStageWidth(), this.getChild("bg").width);
        } else {
            this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
            if (Core.DeviceUtils.isWXGame()) {
                this.getChild("isnbTxt").asTextField.visible = true;
            } else {
                this.getChild("goodTxt").asTextField.y = this.getChild("isnbTxt").asTextField.y;
            }
        }
        this._progressBar = this.getChild("progressBar") as UI.MaskProgressBar;
        this._bg = this.getChild("bg").asLoader;
        this._bg.url = (window.gameGlobal.logoUrl || "loading_logo_lzd_jpg").replace("png", "jpg");
        this._resDict = new Collection.Dictionary<string, number>();

        if (Core.DeviceUtils.isiOS() && 
            !Core.DeviceUtils.isWXGame() && 
            IOS_EXAMINE_VERSION &&
            !window.gameGlobal.isMultiLan) {
            this._progressBar.visible = false;
        }
        /*
        fairygui.GTimers.inst.callDelay(60 * 1000, function() {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_SHOW_LOADING);
        }, this)
        */

        
        
    }

    public addRes(name:string) {
        this._resDict.setValue(name,0);
    }

    public clear() {
        this._resDict.clear();
    }

    public set titleAddString(s: string) {
        this._titleAdd = s;
    }

    public onProgress(current: number, total: number, res:RES.ResourceItem): void {
        this._resDict.setValue(res.name, current/total);
        //console.log(`${res.name} ${current}/${total}`);

        Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SET_LOADING_PERCENT, {
            "percentStr": `(${current}/${total})`
        });

        let c = 0;
        let t = 0;
        this._resDict.forEach((key, value) => {
            t ++;
            c += value;
        });
        let percent = c/t;
        if (Core.DeviceUtils.isWXGame()) {
            this._progressBar.setProgress(c, t);
            percent = c/t;
        } else {
            this._progressBar.setProgress(current, total);
            percent = current/total;
        }
            
        //this._progressBar.getChild("head").x = current/total * this._progressBar.width - 52;
        if (this._titleAdd) {
            this._progressBar.getChild("title").text = "" + Math.floor(percent * 100) + "%" + " [" + this._titleAdd + "]";
        } else {
            this._progressBar.getChild("title").text = "" + Math.floor(percent * 100) + "%";
        }
        if (percent == 1) {
            Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.ON_SHOW_LOADING);
            this.close();
        }

    }

    public setText(str:string):void {

        this.getChild("isnbTxt").asTextField.visible = true;
        this.getChild("isnbTxt").text = str;
        //this._progressBar.getChild("title").text = str;
        //this._progressBar.getChild("title").visible = true;
    }

    public hideProgress(hide: boolean) {
        this._progressBar.visible = !hide;
        this.getChild("goodTxt").visible = !hide;
        this.getChild("isnbTxt").visible = !hide;
    }
}

class GroupLoadingReporter implements RES.PromiseTaskReporter {

    private _onComplete: () => void = null;

    public registerCompleteCallback(onComplete: () => void) {
        this._onComplete = onComplete;
    }

    public onProgress(current: number, total: number): void {

        // console.log("onProgress ", current, total);
        if (current >= total) {
            if (this._onComplete) {
                this._onComplete();
                this._onComplete = null;
            }
        }
    }
}
