
function callNative(msg) {
    try {
        if (window.NativeCall != undefined && window.NativeCall.callNative != undefined) {
            window.NativeCall.callNative(msg);
        }
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.callObjectC) {
            window.webkit.messageHandlers.callObjectC.postMessage(msg);
        }
    } catch (err) {
        console.log(err.message);
    }
}

function loadWXFont(file, finish_cb) {
    var task = wx.downloadFile({
        url: file,
        file: "AaKaiTi.ttf",
        success: function (res) {
            console.log("download success " + res.statusCode);
            if (res.statusCode == 200) {
                console.log(res.tempFilePath);
                var ret = wx.loadFont(res.tempFilePath);
                console.log("load font result " + ret);
            }
        },
        fail: function () {
            console.log("download font fail");
        },
        complete: function () {
            console.log("complete");
            if (finish_cb) finish_cb();
        }

    });
}

//window.callNative = callNative;
//window.loadWXFont = loadWXFont;