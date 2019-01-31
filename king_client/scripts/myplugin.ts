/**
 * 示例自定义插件，您可以查阅 http://developer.egret.com/cn/2d/projectConfig/cmdExtensionPluginin/ 
 * 了解如何开发一个自定义插件
 */

import FS = require("fs");

export class CustomManifestPlugin implements plugins.Command {

    constructor() {
    }

    async onFile(file: plugins.File) {
        //if (file.extname == ".js") {
        //    console.log(file.relative, file.path);
            //file.path = file.path.replace("resource/", "resource_pc/");
        //}
        return file;
    }
    async onFinish(commandContext: plugins.CommandContext) {
	return;
        let manifestData = JSON.parse( FS.readFileSync("manifest.json", "utf-8") );
        let i = [];
        i.forEach
        i.length
        for(let i=0; i<manifestData.game.length; i++) {
            let filePath:string = manifestData.game[i];
            if (filePath.indexOf("bin-debug/device_modules") < 0 && filePath.indexOf("bin-debug/src") < 0) {
                filePath = filePath.replace("bin-debug", "bin-debug/src");
                manifestData.game[i] = filePath;
            }
        }
        commandContext.createFile("manifest.json", new Buffer( JSON.stringify(manifestData) ) );
    }
}

export class PublishResourcePlugin implements plugins.Command {

    constructor() {
    }

    async onFile(file: plugins.File) {
        if (file.relative.slice(0, 9) == "resource/") {
            return null;
        } else {
            return file;
        }
    }

    async onFinish(commandContext: plugins.CommandContext) {
    }
}
