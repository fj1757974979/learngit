
function genPlatformProxy() {
    if (window.gameGlobal.channel == "ctc_fire2333") {
        window.platform = Fire2333Platform.inst;
    } else if (window.gameGlobal.channel == "lzd_pkgsdk") {
        window.platform = PkgSDKPlatform.inst;
    } else if (window.gameGlobal.channel == "lzd_handjoy") {
        if (window.gameGlobal.isFbAdvert) {
            window.platform = FacebookJsPlatform.inst;
        } else {
            window.platform = PkgSDKPlatform.inst;
            window.sharePlatform = FacebookSharePlatform.inst;
        }
    }
}

function genAdsPlatformProxy() {
    if (Core.DeviceUtils.isWXGame()){
        window.adsPlatform = WXGame.WXAdsPlatform.inst;
    } else if (window.gameGlobal.channel == "lzd_pkgsdk") {
        window.adsPlatform = PkgAdsPlatform.inst;
    }
}



