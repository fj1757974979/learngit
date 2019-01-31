module Core {

    export function init() {
        fairygui.UIConfig.modalLayerAlpha = 0.7;
        fairygui.UIConfig.modalLayerColor = Core.TextColors.black;
        //let modalLayer = fairygui.GRoot.inst.modalLayer;
        //if (modalLayer) {
        //    modalLayer.clearGraphics();
        //    modalLayer.drawRect(0, 0, 0, fairygui.UIConfig.modalLayerColor, fairygui.UIConfig.modalLayerAlpha);
        //}
        LayerManager.inst;
    }

    export function loadTD() {
        
        if (window.gameGlobal.debug) {
            return;
        }
        
        if (!window.gameGlobal.tdAppid) {
            return;
        }

        if (Core.DeviceUtils.isWXGame()) {
            return;
        }
        

        let channel = window.gameGlobal.tdChannel || window.gameGlobal.channel;
        let appid = window.gameGlobal.tdAppid;
        //appid = "DA82D687626F4F3185D914C449302546";
        let newSearch = window.location.search;
        if (newSearch) {
            newSearch += "&td_channelid=" + channel;
        } else {
            newSearch = "?td_channelid=" + channel;
        }
        window.history.pushState('','uselessTitle',newSearch);
        window["sequenceNumber"] = appid;
        window["appDisplayName"] = "";
        window["DTGAbaseUrl"] ='https://h5.talkingdata.com/websdk';
        window["DTGARequestUrl"] ='https://h5.udrig.com/g/v1';
        let src = window["DTGAbaseUrl"] + '/js/sdk_release.js?v=1.0.5';

        var s = document.createElement('script');
        s.async = false;
        s.src = src;
        s.type = 'text/javascript';
        s.addEventListener('load', function () {
            s.parentNode.removeChild(s);
            //s.removeEventListener('load', arguments.callee, false);
        }, false);
        document.body.appendChild(s);
    }

}
