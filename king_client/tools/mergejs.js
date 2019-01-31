/// <reference path="../lib/types.d.ts" />

var FileUtil = require("../lib/FileUtil");

var MergeJS = (function(){
    function MergeJS() {

    }

    MergeJS.prototype.execute = function (callback) {
        var manifestData = JSON.parse( FileUtil.read("manifest.json", true) );
        var v = FileUtil.read("version", true);
        var jsfiles = manifestData.initial.concat(manifestData.game);

        var mergeedJS = "";
        var mainjsPath = "";
        var mergeedJSPath = "src/merge.js";
        for(var i=0;i < jsfiles.length; i++){
            if (FileUtil.getFileName(jsfiles[i]) == "Main") {
                mainjsPath = jsfiles[i];
            } else {
                var jsCode = FileUtil.read(jsfiles[i], true);
                mergeedJS += '\n //' + jsfiles[i]+ '\n' + jsCode + '\n'; 
            }
        }

        FileUtil.save(mergeedJSPath, mergeedJS);
        mergeedJSPath += "?v=" + v;
        mainjsPath += "?v=" + v;
        manifestData.initial = [];
        manifestData.game = [mergeedJSPath, mainjsPath];
        FileUtil.save("manifest.json", JSON.stringify(manifestData, null, 4));
        console.log("merge js ok");

        if (callback) {
            callback(0);
        }
        return DontExitCode;
    };

    return MergeJS;
}());

module.exports = MergeJS;
