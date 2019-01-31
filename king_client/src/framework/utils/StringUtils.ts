///<reference path="../window.ts" />

module Core {

    class TextToken {
        protected stream:string[] = [];
        protected _isDone:boolean = true;
        protected _isHead: boolean = true;
        private _id:number;

        constructor(_id:number) {
            this._id = _id;
        }

        get id() {
            return this._id;
        }

        get isDone() {
            return this._isDone;
        }
        set isDone(_isDone:boolean) {
            this._isDone = _isDone;
        }

        get isHead() {
            return this._isHead;
        }

        public toTextElement(): egret.ITextElement {
            return {text:this.stream.join("")};
        }

        public addChar(c:string) {
            this.stream.push(c);
        }

        public getBaseText(): string {
            return this.stream.join("");
        }
    }

    class ColorTextToken extends TextToken {
        private _color:string;
        private _rgbColor:number;

        constructor(_id:number, color:string, rgbColor:number, isHead:boolean) {
            super(_id);
            this._color = color;
            this._rgbColor = rgbColor;
            this._isHead = isHead;
            this._isDone = false;
        }

        get color() {
            return this._color;
        }
        get rgbColor() {
            return this._rgbColor;
        }

        public toTextElement(): egret.ITextElement {
            let baseTxt = this.stream.join("");
            if (!this._isDone) {
                if (this._isHead) {
                    return {text:"#c" + this._color + baseTxt};
                } else {
                    return {text:baseTxt};
                }
            } else {
                return {text:baseTxt, style: {"textColor": this.rgbColor}};
            }
        }

        public static getRgbColor(colorCode:string): number {
            if (colorCode.length == 1) {
                return ColorsCode[colorCode];
            }
            return parseInt(colorCode, 16);
        }
    }

    declare interface TextGameData {
        get(id:number): any
    }

    export class StringUtils {
        public static textGameData: TextGameData;
        public static textGameData2: TextGameData;

        public static TEXT(id:number):string {
            if (!StringUtils.textGameData) {
                return "";
            }
            let txtLocaleInfo = StringUtils.textGameData.get(id);
            if (!txtLocaleInfo) {
                if (StringUtils.textGameData2) {
                    txtLocaleInfo = StringUtils.textGameData2.get(id);
                    if (!txtLocaleInfo) {
                        return "";
                    }
                } else {
                    return "";
                }
            }
            let txt: string = txtLocaleInfo[LanguageMgr.inst.cur];
            if (txt) {
                // return txt.replace("我是大军师", window.gameGlobal.gameName || "隆中对");
                if (txt.indexOf("$GAME_NAME") >= 0) {
                    return txt.replace("$GAME_NAME", Home.getGameName());
                } else {
                    return txt;
                }
            } else {
                return "";
            }
        }

        public static parseColorText(str:string): Array<egret.ITextElement> {
            let ret: Array<egret.ITextElement> = [];
            let panding: Array<TextToken> = [];
            let complete: Array<TextToken> = [];

            let tokenId = 0;
            let curToken: TextToken;
            let strLen = str.length;
            let curStatus = 0;  // 0.raw  1.parsing color
            for (let i=0; i<strLen;) {
                let c = str[i];
                if (curStatus == 0) {
                    if (c == "#") {
                        if (str[i+1] == "c") {
                            let colorCode = str[i+2];
                            let rgb = ColorTextToken.getRgbColor(colorCode);
                            if (!rgb) {
                                colorCode = str.slice(i+2, i+8);
                                rgb = ColorTextToken.getRgbColor(colorCode);
                            }

                            if (rgb) {
                                // begin parse color
                                if (curToken != null) {
                                    complete.push(curToken);
                                }
                                curToken = new ColorTextToken(tokenId, colorCode, rgb, true)
                                tokenId += 1;
                                i += colorCode.length + 2;
                                curStatus = 1;
                                continue;
                            }
                        }
                    }

                    // raw text
                    i += 1;
                    if (curToken == null) {
                        curToken = new TextToken(tokenId);
                        tokenId += 1;
                    }
                    curToken.addChar(c);
                } else {
                    if (c == "#") {
                        if (str[i+1] == "n") {
                            // parse color done
                            i += 2;
                            curToken.isDone = true;
                            complete.push(curToken);
                            if (!curToken.isHead) {
                                while(panding.length > 0) {
                                    curToken = panding.pop();
                                    curToken.isDone = true;
                                    complete.push(curToken);
                                    if (curToken.isHead) {
                                        break;
                                    }
                                }
                            }

                            if (panding.length > 0) {
                                let lastPandingToken = panding[panding.length-1] as ColorTextToken;
                                curToken = new ColorTextToken(tokenId, lastPandingToken.color, lastPandingToken.rgbColor, false);
                                tokenId += 1;
                            } else {
                                curToken = null;
                                curStatus = 0;
                            }
                            continue;
                        } else if (str[i+1] == "c") {
                            let colorCode = str[i+2];
                            let rgb = ColorTextToken.getRgbColor(colorCode);
                            if (!rgb) {
                                colorCode = str.slice(i+2, i+8);
                                rgb = ColorTextToken.getRgbColor(colorCode);
                            }

                            if (rgb) {
                                // 嵌套color
                                panding.push(curToken);
                                curToken = new ColorTextToken(tokenId, str[i+2], ColorsCode[str[i+2]], true)
                                tokenId += 1;
                                i += 3;
                                curStatus = 1;
                                continue;
                            }
                        }
                    }

                    // color text
                    i += 1;
                    curToken.addChar(c);
                }
            }

            if (curToken != null) {
                complete.push(curToken);
            }

            panding.forEach(t => {
                complete.push(t);
            })

            complete.sort(function(a:TextToken, b:TextToken):number{
                if (a.id > b.id) {
                    return 1;
                } else {
                    return -1;
                }
            })

            complete.forEach(t => {
                ret.push(t.toTextElement());
            })

            return ret;
        }

        public static parseFuncText(textObj: fairygui.GTextField, exitsElements?: Array<egret.ITextElement>): Array<egret.ITextElement> {
            // #fev,val(text)#e
            let baseTxt = textObj.text;
            let ret: Array<egret.ITextElement> = [];
            if (!exitsElements) {
                exitsElements = StringUtils.parseColorText(baseTxt);
            }

            function copyStyle(style: egret.ITextStyle): egret.ITextStyle {
                if (style) {
                    return <egret.ITextStyle>JSON.parse(JSON.stringify(style));
                } else {
                    return {};
                }
            }

            let needEventListener: boolean = false;

            exitsElements.forEach(element => {
                let text = element.text;
                let style = null;
                if (element.style) {
                    style = element.style;
                }
                let funcElements: Array<egret.ITextElement> = [];
                let startIdx = text.indexOf("#f");
                while (startIdx >= 0) {
                    // console.log("======== 1 ", startIdx);
                    let prefixTxt = text.substr(0, startIdx);
                    funcElements.push({
                        text: prefixTxt,
                        style: copyStyle(style)
                    });
                    // cut #f
                    text = text.substr(startIdx + 2, text.length - startIdx - 2);
                    // console.log("2", text);
                    let endIdx = text.indexOf("#e");
                    // console.log("3", endIdx);
                    if (endIdx < 0) {
                        break;
                    }
                    // current data to handle
                    let curTxt = text.substr(0, endIdx);
                    // console.log("4", curTxt);
                    // next data to handle
                    text = text.substr(endIdx + 2, text.length - endIdx - 2);
                    // console.log("5", text);
                    let fplaceHold = "(";
                    let tplaceHold = ")";
                    curTxt = curTxt.replace("（", fplaceHold);
                    curTxt = curTxt.replace("）", tplaceHold);
                    let fidx = curTxt.indexOf(fplaceHold);
                    let tidx = curTxt.indexOf(tplaceHold);
                    if (fidx < 0 && tidx < 0) {
                        break;
                    }
                    let contentTxt = curTxt.substr(fidx + fplaceHold.length, tidx - fidx - fplaceHold.length);
                    let contentElement = StringUtils._assembleEventElement(textObj, curTxt.substr(0, fidx), contentTxt, style)
                    if (contentElement) {
                        funcElements.push(contentElement);
                        if (contentElement.style && contentElement.style.href) {
                            needEventListener = true;
                        }
                    }
                    startIdx = text.indexOf("#f");
                }
                // console.log("8", text);
                // console.log("9", funcElements);
                funcElements.forEach(el => {
                    ret.push(el);
                });
                if (text.length > 0) {
                    element.text = text;
                    ret.push(element);
                }
            });
            if (needEventListener) {
                textObj.touchable = true;
                textObj.addEventListener(egret.TextEvent.LINK, StringUtils._handleFuncEvent, textObj.displayObject);
            }
            // console.log("10", ret);
            return ret;
        }

        private static _assembleEventElement(textObj: fairygui.GTextField, eventStr: string, contentStr: string, fromStyle: egret.ITextStyle): egret.ITextElement {
            if (!fromStyle) {
                fromStyle = <egret.ITextStyle>{};
            }
            let eventStyle = <egret.ITextStyle>JSON.parse(JSON.stringify(fromStyle));
            eventStr = eventStr.replace("，", ",");
            let eventStrings = eventStr.split(",");
            if (eventStrings.length < 2) {
                return null;
            }
            let eventType = eventStrings[0];
            if (eventType == "img") {
                // #fimg,url(w,h)#e
                contentStr = contentStr.replace("，", ",");
                let sizeStrings = contentStr.split(",");
                if (sizeStrings.length < 2) {
                    return null;
                }
                let w = parseInt(sizeStrings[0]);
                let h = parseInt(sizeStrings[1]);
                if (!w || !h) {
                    return null;
                }
                let url = eventStrings[1];
                let fontSize = Math.max(w, h);
                // let fontSize = 10;
                eventStyle.size = fontSize;
                eventStyle.drawParam = `img,${url},${w},${h}`;
                eventStyle.drawThis = textObj;
                eventStyle.drawCallback = Core.StringUtils._handleTextDraw;
                contentStr = "    ";
                // let measureStyle = {
                //     italic: false,
                //     bold: false,
                //     size: fontSize,
                //     fontFamily: egret.TextField.default_fontFamily
                // }
                // while (egret.measureTextWidth(contentStr, null, measureStyle) < Math.max(w, h)) {
                //     measureStyle.size = measureStyle.size + 1;
                // }
                // eventStyle.size = measureStyle.size;
            }else if(eventType == "com"){
                //#fitem,video(w,h)#e
                contentStr = contentStr.replace("，", ",");
                let sizeStrings = contentStr.split(",");
                if (sizeStrings.length < 2) {
                    return null;
                }
                let w = parseInt(sizeStrings[0]);
                let h = parseInt(sizeStrings[1]);
                if(!w||!h)
                {
                    return null;
                }
                let videoid = eventStrings[1];
                let fontSize = Math.max(w, h);
                eventStyle.size = fontSize;
                eventStyle.drawParam = `com,${videoid},${w},${h}`;
                eventStyle.drawThis = textObj;
                eventStyle.drawCallback = Core.StringUtils._handleTextDraw;
                contentStr = "   ";
            }
             else {
                eventStyle.href = `event:${eventStr}`;
                eventStyle.underline = true;
                eventStyle.bold = true;
            }
            return {text: contentStr, style: eventStyle};
        }

        private static async _handleTextDraw(textObj: egret.TextField, x: number, y: number, param: any, thisObj: any) {
            let paramStrings = (<string>param).split(",");
            let drawType = paramStrings[0];
            if (drawType == "img") {
                let url = paramStrings[1];
                let w = parseInt(paramStrings[2]);
                let h = parseInt(paramStrings[3]);
                let parent = <fairygui.GTextField>thisObj;
                let loader = new fairygui.GLoader();
                loader.url = url;
                loader.width = w;
                loader.height = h;
                loader.autoSize = false;
                loader.fill = fairygui.LoaderFillType.ScaleFree;
                loader.x = x + parent.x;
                loader.y = y + parent.y - h / 2;
                parent.parent.addChild(loader);
                parent.addAppendChild(loader);
            }
            else if(drawType == "com") {
                let videoId = paramStrings[1];
                let w = parseInt(paramStrings[2]);
                let h = parseInt(paramStrings[3]);
                let parent = <fairygui.GTextField>thisObj;
                let com = fairygui.UIPackage.createObject(PkgName.pvp, "videoItem",Pvp.VideoShareItemCom).asCom as Pvp.VideoShareItemCom;
                let videoID = Core.StringUtils.stringToLong(videoId);
                let video = await Pvp.VideoCenter.inst.getVideoById(videoID);
                com.setVideo(video,null);
                com.x = x + parent.x;
                com.y = y + parent.y - h / 2 - 10;
                parent.parent.addChild(com);
                parent.addAppendChild(com);
            }
        }

        private static async _handleFuncEvent(ev: egret.TextEvent) {
            let text = ev.text;
            console.log("!!!!!!! ", text);
            let placehold = ",";
            if (text.indexOf(placehold) < 0) {
                placehold = "，";
            }
            let eventInfos = text.split(placehold);
            if (eventInfos.length < 2) {
                return;
            }
            let eventType = eventInfos[0];
            let eventValue = eventInfos[1];
            if (eventType == "video") {
                let videoId = Core.StringUtils.stringToLong(eventValue);
                Pvp.VideoCenter.inst.playVideoById(videoId);
            }else if (eventType == "user") {
                let uid = Core.StringUtils.stringToLong(eventValue);
                let playerInfo = await Social.FriendMgr.inst.fetchPlayerInfo(uid);
				if (playerInfo) {
					Core.ViewManager.inst.open(ViewName.friendInfo, uid, playerInfo);
				}
            } else if (eventType == "card") {
                let cardId = parseInt(eventValue);
                if (cardId) {
                    let data = Data.pool.get(cardId);
					let cardObj = new CardPool.Card(data);
					cardObj.level = data.level;
					Core.ViewManager.inst.open(ViewName.cardInfoOther, cardObj);
                }
            } else if (eventType == "desc") {
                let descStr = <string>eventValue;
                Core.ViewManager.inst.openPopup(ViewName.descTipsWnd, descStr);
            }
        }

        public static getZhNumber(num: number): string {
            if (window.gameGlobal.isMultiLan) {
                if (!LanguageMgr.inst.isChineseLocale()) {
                    return num.toString();
                }
            }
            switch (num) {
                case 0:
                    return Core.StringUtils.TEXT(60016);
                case 1:
                    return Core.StringUtils.TEXT(60001);
                case 2:
                    return Core.StringUtils.TEXT(60005);
                case 3:
                    return Core.StringUtils.TEXT(60003);
                case 4:
                    return Core.StringUtils.TEXT(60009);
                case 5:
                    return Core.StringUtils.TEXT(60006);
                case 6:
                    return Core.StringUtils.TEXT(60014);
                case 7:
                    return Core.StringUtils.TEXT(60002);
                case 8:
                    return Core.StringUtils.TEXT(60013);
                case 9:
                    return Core.StringUtils.TEXT(60010);
                default:
                    // TODO: Implemente default case
                    console.debug("default case");
            }
        }

        public static secToString(sec: number, fmt: string): string {
            let hours = Math.round((sec - 30 * 60) / (60 * 60));
            let minutes = Math.round((sec - 30) / 60) % 60;
            let seconds = sec % 60;
            if (fmt.toLowerCase() == "hms") {
                if (hours > 0) {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60128), hours, minutes, seconds);
                } else if (minutes > 0) {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60070), minutes, seconds);
                } else {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60021), seconds);
                }
            } else if (fmt.toLowerCase() == "h") {
                if (hours > 0) {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60058), hours);
                } else {
                    let m = Math.max(1, minutes);
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60055), m);
                }
            } else if (fmt.toLowerCase() == "hm") {
                if (hours > 0) {
                    if (minutes > 0) {
                        return Core.StringUtils.format(Core.StringUtils.TEXT(60112), hours, minutes);
                    } else {
                        return Core.StringUtils.format(Core.StringUtils.TEXT(60058), hours);
                    }
                } else {
                    if (minutes <= 0) {
                        return Core.StringUtils.format(Core.StringUtils.TEXT(60021), seconds);
                    } else if (seconds > 0) {
                        return Core.StringUtils.format(Core.StringUtils.TEXT(60070), minutes, seconds);
                    } else {
                        return Core.StringUtils.format(Core.StringUtils.TEXT(60055), minutes);
                    }

                }
            } else if (fmt.toLowerCase() == "dhm") {
                let hours = Math.round((sec - 30 * 60) / (60 * 60));
                let days = Math.floor(hours/24);
                let minutes = Math.round((sec - 30) / 60) % 60;
                if (days > 0) {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60032), days);
                } else if (hours > 0) {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60058), hours);
                } else if (minutes > 0) {
                    return Core.StringUtils.format(Core.StringUtils.TEXT(60055), minutes);
                } else {
                    return Core.StringUtils.TEXT(60042);
                }
            } else if (fmt.toLowerCase() == "dhms") {
                let hours = Math.round((sec - 30 * 60) / (60 * 60));
                let days = Math.floor(hours/24);
                hours = hours % 24;
                let minutes = Math.round((sec - 30) / 60) % 60;
                let seconds = sec % 60;
                return Core.StringUtils.format(Core.StringUtils.TEXT(70124), days, hours, minutes);
            } else {
                return Core.StringUtils.format(Core.StringUtils.TEXT(60021), seconds);
            }
        }

        public static secToDate(sec: number, fmt: string): string {
            let date = new Date(sec * 1000);
            let year = date.getFullYear();
            let month = date.getMonth() + 1;
            let day = date.getDate();
            let hour = date.getHours();
            let minutes = date.getMinutes();
            let seconds = date.getSeconds();
            if (fmt.toLowerCase() == "ymdhms") {
                return Core.StringUtils.format(Core.StringUtils.TEXT(60206), year, month, day, hour, minutes, seconds);
            } else if (fmt.toLowerCase() == "ymd") {
                return Core.StringUtils.format(Core.StringUtils.TEXT(60115), year, month, day);
            } else if (fmt.toLowerCase() == "mdh") {
                return Core.StringUtils.format(Core.StringUtils.TEXT(60121), month, day, hour);
            } else {
                return Core.StringUtils.format(Core.StringUtils.TEXT(60183), month, day, hour, minutes, seconds);
            }
        }

        public static stringToLong(str: string): Long {
            let bits = protobuf.Writer.create().uint64(str).finish();
			return protobuf.Reader.create(bits).uint64();
        }

        public static utf8ArrayToString(array: Uint8Array): string {
            var out, i, len, c;
            var char2, char3;

            out = "";
            len = array.length;
            i = 0;
            while(i < len) {
                c = array[i++];
                switch(c >> 4)
                {
                    case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
                        // 0xxxxxxx
                        out += String.fromCharCode(c);
                        break;
                    case 12: case 13:
                        // 110x xxxx   10xx xxxx
                        char2 = array[i++];
                        out += String.fromCharCode(((c & 0x1F) << 6) | (char2 & 0x3F));
                        break;
                        case 14:
                        // 1110 xxxx  10xx xxxx  10xx xxxx
                        char2 = array[i++];
                        char3 = array[i++];
                        out += String.fromCharCode(((c & 0x0F) << 12) |
                                    ((char2 & 0x3F) << 6) |
                                    ((char3 & 0x3F) << 0));
                        break;
                }
            }

            return out;
        }

        public static format(formatter: string, ...param: any[]): string {
            return formatter.replace(/{(\d+)}/g, (match, number) => {
                return typeof(param[number]) != "undefined" ?
                    param[number] : match;
            });
        }

        public static utf8Length(str: string): number {
            let byteLen = 0, len = str.length;
            if(!str) return 0;
            for( var i=0; i<len; i++ ) {
                byteLen += str.charCodeAt(i) > 255 ? 2 : 1;
            }
            return byteLen;
        }
    }

}
