// TypeScript file
module WXGame {

    export class WXFileSystem {
        private static _inst: WXFileSystem = null;
        private _fs: FileSystemManager;
        private _dirCache: Collection.Dictionary<string, boolean>;
        private _fsRoot: string;
        private _fsCacheFile: string;
        private _fsCacheVersionInfo: any;
        private _NO_VERSION: string = "n";
        private _dirty: boolean;
        private _saving: boolean;
        private _mkdirPromise: Collection.Dictionary<string, Promise<any>>;
        private _isNewDownloader: boolean;

        private _downloadFailRetryCnt: number = 30;

        public static get inst(): WXFileSystem {
            if (!WXFileSystem._inst) {
                WXFileSystem._inst = new WXFileSystem();
            }
            return WXFileSystem._inst;
        }

        public constructor() {
            this._fs = wx.getFileSystemManager();
            this._dirCache = new Collection.Dictionary<string, boolean>();
            this._fsRoot = (<any>wx).env.USER_DATA_PATH + "/";
            this._fsCacheFile = "cached_file_version2.info";
            this._fsCacheVersionInfo = {};
            this._dirty = false;
            this._saving = false;
            this._mkdirPromise = new Collection.Dictionary<string, Promise<any>>();
            this._isNewDownloader = false;

            fairygui.GTimers.inst.add(60 * 1000, -1, this._saveVersionFile, this);
        }

        private async _saveVersionFile() {
            if (this._dirty && !this._saving) {
                this._dirty = false;
                this._saving = true;
                let str = JSON.stringify(this._fsCacheVersionInfo);
                await this.writeFile(this._fsCacheFile, str);
                console.log("saving version file, size = ", str.length);
                this._saving = false;
            }
        }

        public async initFileVersionInfos() {
            if (!await this.access(this._fsCacheFile)) {
                this._isNewDownloader = true;
                if (!await this.writeFile(this._fsCacheFile, "{}")) {
                    console.error("can't init file version info");
                }
            }
            let infoStr = await this.readFile(this._fsCacheFile, "utf8");
            if (!infoStr) {
                console.error("can't read file version info");
            } else {
                this._fsCacheVersionInfo = JSON.parse(<string>infoStr);
            }
        }

        public get isNewDownloader(): boolean {
            //return true;
            return this._isNewDownloader;
        }

        public getFileLocalVersion(p: string) {
            return this._fsCacheVersionInfo[p];
        }

        public setFileLocalVersion(p: string, ver: string) {
            if (ver == null) {
                ver = this._NO_VERSION;
            }
            this._dirty = true;
            this._fsCacheVersionInfo[p] = ver;
            // console.log(`set ${p} local version ${ver}`);
        }

        public get fsRoot(): string {
            return this._fsRoot;
        }

        public isRemotePath(p: string) {
            return p.indexOf("http://") == 0 || p.indexOf("https://") == 0;
        }

        public getLocalFilePath(p: string) {
            return p.split("?")[0];
        }

        public getWXFilePath(p: string) {
            return this._fsRoot + p;
        }

        public getFileName(p: string) {
            if (p.indexOf("/") < 0) {
                return p;
            } else {
                let idx = p.lastIndexOf("/");
                return p.substr(idx + 1, p.length);
            }
        }

        public getFileVersion(p: string) {
            let arr = p.split("?");
            if (arr.length >= 2) {
                return arr[1];
            } else {
                return null;
            }
        }

        public async fileExists(p: string, v: string = null) {
            let localVer = this.getFileLocalVersion(p);
            if (localVer == null) {
                if (v == null) {
                    if (await this.access(p)) {
                        this.setFileLocalVersion(p, this._NO_VERSION);
                        return true;
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            } else if (localVer == this._NO_VERSION && v == null) {
                return true;
            } else {
                return v == localVer;
            }
        }

        public async dirExists(dir: string) {
            if (this._dirCache.getValue(dir)) {
                // console.log("dirExists in cache", dir);
                return true;
            } else {
                // try {
                //     this._fs.accessSync(dir);
                //     return true;
                // } catch (e) {
                //     return false;
                // }
                return await this.access(dir);
            }
        }

        public async readFile(p: string, encoding?: string) {
            return await new Promise((resolve) => {
                this._fs.readFile({
                    filePath: this._fsRoot + p,
                    encoding: encoding,
                    success: (res) => {
                        resolve(res.data);
                    },
                    fail: (res) => {
                        console.error(res);
                        resolve(null);
                    },
                    complete: (res) => {

                    }
                });
            })
        }
        
        public async writeFile(p: string, data: any, encoding: string = "utf8") {
            return await new Promise((resolve) => {
                this._fs.writeFile({
                    filePath: this._fsRoot + p,
                    data: data,
                    encoding: encoding,
                    success: (res) => {
                        resolve(true);
                    },
                    fail: (res) => {
                        console.error(res);
                        resolve(false);
                    },
                    complete: (res) => {

                    }
                })
            });
        }

        public async access(p: string): Promise<boolean> {
            return await new Promise<boolean>((resolve) => {
                this._fs.access({
                    path: this._fsRoot + p,
                    success: (res) => {
                        resolve(true);
                    },
                    fail: (res) => {
                        // console.error(res);
                        resolve(false);
                    },
                    complete: (res) => {

                    }
                })
            });
        }

        public async unlink(p: string) {
            return await new Promise((resolve) => {
                this._fs.unlink({
                    filePath: this._fsRoot + p,
                    success: (res) => {
                        delete this._fsCacheVersionInfo[p];
                        resolve(true);
                    },
                    fail: (res) => {
                        console.error(res);
                        resolve(false);
                    },
                    complete: (res) => {

                    }
                })
            });
        }

        public async unzip(p: string, t: string):Promise<boolean> {
            return await new Promise<boolean>((resolve) => {
                this._fs.unzip({
                    zipFilePath: this._fsRoot + p,
                    targetPath: this._fsRoot + t,
                    success: (res) => {
                        resolve(true);
                    },
                    fail: (res) => {
                        console.error(res);
                        resolve(false);
                    },
                    complete: (res) => {

                    }
                })
            });
        }

        public dirname(dir: string): string {
            let arr = dir.split("/");
            arr.pop();
            return arr.join("/");
        }

        public async mkdir(p: string) {
            // try {
            //     this._fs.mkdirSync(this._fsRoot + p);
            // } catch (e) {
                
            // }

            let promise = this._mkdirPromise.getValue(p);
            if (promise) {
                return await promise;
            }

            let ret = new Promise((resolve) => {
                this._fs.mkdir({
                    dirPath: this._fsRoot + p,
                    success: (res) => {
                        // console.log("mkdir: ", this._fsRoot + p);
                        this._mkdirPromise.remove(p);
                        resolve(true);
                    },
                    fail: (res) => {
                        console.error(res);
                        this._mkdirPromise.remove(p);
                        resolve(false);
                    },
                    complete: (res) => {

                    }
                })
            });

            this._mkdirPromise.setValue(p, ret);
            return await ret;
        }

        public async mkdirs(p: string) {
            if (p == "") {
                return;
            }
            if (!await this.dirExists(p)) {
                let dirs = p.split("/");
                // console.log("mkdirs: ", JSON.stringify(dirs));
                let current = "";
                for (let i = 0; i < dirs.length; ++ i) {
                    let dir = dirs[i];
                    current += dir + "/";
                    if (!await this.dirExists(current)) {
                        await this.mkdir(current);
                        this._dirCache.setValue(current, true);
                    }
                }
            } else {
                // console.log(`dir ${p} exists already`);
                return;
            }
        }

        private async _downloadFile(url: string, fileTarget: string, retryCnt: number, progressCb?: (res) => void): Promise<any> {
            let p = new Promise((resolve, reject) => {
                let task = wx.downloadFile({
                    url: url,
                    filePath: fileTarget,
                    success: (v) => {
                        if (v.statusCode >= 400) {
                            try {
                                wx.getFileSystemManager().accessSync(fileTarget);
                                wx.getFileSystemManager().unlinkSync(fileTarget);
                            } catch(e) {
                                console.error("_downloadFile fail, status error: ", url, fileTarget, e);
                            }
                            if (retryCnt <= 0) {
                                reject(`加载失败：${url}`);
                            } else {
                                resolve(null);
                            }
                        } else {
                            resolve(fileTarget);
                        }
                    },
                    fail: (e) => {
                        console.log("_downloadFile fail: ", url, fileTarget, e);
                        if (retryCnt <= 0) {
                            let error = new RES.ResourceManagerError(1001, url);
                            reject(error);
                        } else {
                            resolve(null);
                        }
                    },
                    complete: (res) => {

                    }
                });
                if (progressCb) {
                    task.onProgressUpdate((res) => {
                        progressCb(res);
                    })
                }
            });
            if (retryCnt <= 0) {
                throw new RES.ResourceManagerError(1001, url);
            } else {
                let ret = await p;
                if (ret) {
                    return ret;
                } else {
                    console.debug("download", url, "fail, retry cnt", retryCnt);
                    return await this._downloadFile(url, fileTarget, retryCnt - 1, progressCb);
                }
            }
        }

        public async download(srcUrl: string, target: string, progressCb?: (res) => void) {
            let dirname = this.dirname(target);
            // console.log("======== ", dirname);
            await this.mkdirs(dirname);
            let fileTarget = this._fsRoot + target;
            return await new Promise((resolve, reject) => {
                this._downloadFile(srcUrl, fileTarget, this._downloadFailRetryCnt, progressCb).catch(error => {
                    reject(error);
                }).then((filePath) => {
                    let version = this.getFileVersion(srcUrl);
                    this.setFileLocalVersion(target, version);
                    
                    resolve(fileTarget);
                }, (error) => {
                    reject(error);
                });
            });
        }

        private async _xhrLoad(xhrURL: string, target: string, type?: string, isText?: boolean) {
            let content = await new Promise((resolve, reject) => {
                let xhr = new XMLHttpRequest();
                if (type) {
                    (<any>xhr).responseType = type;
                }
                xhr.onload = () => {
                    if (xhr.status >= 400) {
                        let message = `加载失败：${xhrURL}`;
                        console.error(message);
                        // reject(message);
                        resolve(null);
                    } else {
                        if (isText) {
                            resolve(xhr.responseText);
                        } else {
                            resolve(xhr.response);
                        }
                    }
                }
                xhr.onerror = () => {
                    let error = new RES.ResourceManagerError(1001, xhrURL);
                    console.error("xhrLoad error: ", error);
                    // reject(error);
                    resolve(null);
                }
                xhr.open("get", xhrURL);
                xhr.send();
            });

            // let dirname = this.dirname(target);
            // await this.mkdirs(dirname);
            // await this.writeFile(target, content);

            // let version = this.getFileVersion(xhrURL);
            // this.setFileLocalVersion(target, version);

            return content;
        }

        public async xhrLoad(xhrURL: string, target: string, type?: string, isText?: boolean) {
            let retryCnt = this._downloadFailRetryCnt;
            while (retryCnt --  > 0) {
                let content = await this._xhrLoad(xhrURL, target, type, isText);
                if (content) {
                    let dirname = this.dirname(target);
                    await this.mkdirs(dirname);
                    await this.writeFile(target, content);

                    let version = this.getFileVersion(xhrURL);
                    this.setFileLocalVersion(target, version);
                    return content;
                }
                console.error("xhrLoad ", xhrURL, "fail, retry ", retryCnt);
            }
            throw new RES.ResourceManagerError(1001, xhrURL);
            // return await this._xhrLoad(xhrURL, target, type, isText);
        }

    }

    export class WXGroupLoader {
        private static _inst: WXGroupLoader = null;

        public static get inst(): WXGroupLoader {
            if (WXGroupLoader._inst == null) {
                WXGroupLoader._inst = new WXGroupLoader();
            }
            return WXGroupLoader._inst;
        }

        public get isNewbieLoader(): boolean {
            return WXFileSystem.inst.isNewDownloader;
        }

        public async loadZip(name:string, reporter?:RES.PromiseTaskReporter, version:boolean = false)  {
            let url = `${WXGame.WXGameMgr.getWebClientHost()}/resource/${name}?v=${version ? window.gameGlobal.version: 1003}`;
            console.log(`${url}`);
            await WXFileSystem.inst.download(url, name, (res) => {
                if (reporter) {
                    reporter.onProgress(res.totalBytesWritten, res.totalBytesExpectedToWrite, null);
                }
            }).catch(error => {
                console.error("loadZip ", error);
            });
            let dir = "";
            if (!await WXFileSystem.inst.dirExists(dir)) {
                await WXFileSystem.inst.mkdir(dir);
            }
            if (!await WXFileSystem.inst.unzip(name, dir)) {
                console.error("can't unzip group ", name);
            }
            let exist = await WXFileSystem.inst.fileExists("default.res.json");
            let exist2 = await WXFileSystem.inst.dirExists("king_ui");
            console.log(`default.res.json exist ${exist} king_ui exist ${exist2}`);
            WXFileSystem.inst.unlink(name);
        }

        public async loadGroup(name: string, reporter?: RES.PromiseTaskReporter, reporter2?: RES.PromiseTaskReporter, isTempLoad: boolean = false) {
            let target =  `${name}.zip`;
            let url = `${WXGame.WXGameMgr.getWebClientHost()}/resource/${target}?v=${window.gameGlobal.version}`;
            await WXFileSystem.inst.download(url, target, (res) => {
                if (reporter) {
                    reporter.onProgress(res.totalBytesWritten, res.totalBytesExpectedToWrite, null);
                }
            });
            let dir = "";
            if (!await WXFileSystem.inst.dirExists(dir)) {
                await WXFileSystem.inst.mkdir(dir);
            }
            if (!await WXFileSystem.inst.unzip(target, dir)) {
                console.error("can't unzip group ", name);
            }
            await WXFileSystem.inst.unlink(target);
            if (name == "sound") {
                await RES.loadGroup(name, 0, reporter2, true);
            } else {
                await RES.loadGroup(name, 0, reporter2);
            }
        }
    }

    class WXGameLoaderBase {

        public constructor () {
        }

        protected _shouldCache(fullname: string): boolean {
            return true;
        }

        public async prepareNewbieLoads(resource: RES.ResourceInfo): Promise<boolean> {
            if (!WXGroupLoader.inst.isNewbieLoader) {
                return false;
            }
            if (resource.groupNames && resource.groupNames.length > 0) {
                // 属于某个组的资源，已经下载过了
                let url = resource.url;
                let version = WXFileSystem.inst.getFileVersion(url);
                let fullname = WXFileSystem.inst.getLocalFilePath(url);
                let localversion = WXFileSystem.inst.getFileLocalVersion(fullname);
                if (await WXFileSystem.inst.fileExists(fullname)) {
                    WXFileSystem.inst.setFileLocalVersion(fullname, version);
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }

        protected async fileExists(fullname: string, v: string = null) {
            return await WXFileSystem.inst.fileExists(fullname, v);
        }

        protected getWXFilePath(fullname: string) {
            return WXFileSystem.inst.getWXFilePath(fullname);
        }
    }

    export class WXImageProcessor extends WXGameLoaderBase implements RES.processor.Processor {
        public async onLoadStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let root = resource.root;
            let url = resource.url;
            let scale9Grid = null;

            if (resource.scale9grid) {
                let list = resource.scale9grid.split(",");
                scale9Grid = new egret.Rectangle(parseInt(list[0]), parseInt(list[1]), parseInt(list[2]), parseInt(list[3]));
            }

            let imageSrc = root + url;
            if (RES["getVirtualUrl"]) {
                imageSrc = RES["getVirtualUrl"](imageSrc);
            }
            //console.log(`root=${root} ${url} ${imageSrc}`);
            if (WXFileSystem.inst.isRemotePath(imageSrc)) {
                await this.prepareNewbieLoads(resource);
                let fullname = WXFileSystem.inst.getLocalFilePath(url);
                // console.log(`start load image, root = ${root}, url = ${url}, fullname = ${fullname}`);
                let ver = WXFileSystem.inst.getFileVersion(url);
                if (this._shouldCache(fullname) && await this.fileExists(fullname, ver)) {
                    // console.log("cache hit for ", root, fullname, ver);
                    return await this._loadImage(this.getWXFilePath(fullname), scale9Grid);
                } else {
                    return await new Promise<any>((resolve, reject) => {
                        WXFileSystem.inst.download(imageSrc, fullname).then(
                            (filePath) => {
                                // console.log(`download ${imageSrc} success => ${filePath}`);
                                this._loadImage(<string>filePath, scale9Grid).then(
                                    (texture) =>{
                                        resolve(texture);
                                    }, 
                                    (error1) => {
                                        console.error("_loadImage ", error1);
                                        reject(error1);
                                    }
                                );
                            },

                            (error2) => {
                                console.error("download ", error2);
                                reject(error2);
                            }
                        );
                    });
                }
            } else {
                return await this._loadImage(imageSrc, scale9Grid);
            }
        }

        public onRemoveStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let texture = host.get(resource);
            if (texture) {
                texture.dispose();
            }
            return Promise.resolve();
        }

        public static async loadWXLocalImage(imageUrl): Promise<egret.Texture> {
            let texture: egret.Texture = await new Promise<egret.Texture>((resolve, reject) => {
                let image = wx.createImage();
                image.onload = () => {
                    image.onload = null;
                    image.onerror = null;
                    let bitmapdata = new egret.BitmapData(image);
                    image = null;
                    let texture = new egret.Texture();
                    texture._setBitmapData(bitmapdata);
                    
                    setTimeout(() => {
                        resolve(texture);
                    }, 0);
                }
                image.onerror = (e) => {
                    console.error(e);
                    resolve(null);
                }
                image.src = imageUrl;
            });
            return texture;
        }

        private async _loadImage(imageUrl: string, scale9grid: any) {
            return new Promise((resolve, reject) => {
                let image = wx.createImage();
                image.onload = () => {
                    image.onload = null;
                    image.onerror = null;
                    let bitmapdata = new egret.BitmapData(image);
                    image = null;
                    let texture = new egret.Texture();
                    texture._setBitmapData(bitmapdata);
                    if (scale9grid) {
                        texture["scale9Grid"] = scale9grid;
                    }
                    setTimeout(() => {
                        resolve(texture);
                    }, 0);
                }
                image.onerror = (e) => {
                    console.error(e);
                    let error = new RES.ResourceManagerError(1001, imageUrl);
                    reject(error);
                }
                image.src = imageUrl;
            });

            // 
            // let bitmapdata = new egret.BitmapData(image);
            // bitmapdata.hasSourceLoaded = false;
                
            // let texture = new egret.Texture();
            // texture._setBitmapData(bitmapdata);
            // if (scale9grid) {
            //     texture["scale9Grid"] = scale9grid;
            // }
            // bitmapdata.delayLoadCallback = async (image) => {
            //     return new Promise<boolean>(resolve => {
            //         image.onload = () => {
            //             image.onload = null;
            //             image.onerror = null;
            //             bitmapdata.setSource(image);
            //             texture._setBitmapData(bitmapdata);
            //             resolve(true);
            //         }
            //         image.onerror = (e) => {
            //             console.error(e);
            //             resolve(false);
            //         }
            //         image.src = imageUrl;
            //     });
            // };
            // return texture;
        }
    }

    class WXSoundProcessor extends WXGameLoaderBase implements RES.processor.Processor {

        public async onLoadStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let root = resource.root;
            let url = resource.url;
            let soundSrc = root + url;
            if (RES["getVirtualUrl"]) {
                soundSrc = RES["getVirtualUrl"](soundSrc);
            }
            if (WXFileSystem.inst.isRemotePath(soundSrc)) {
                await this.prepareNewbieLoads(resource);
                let fullname = WXFileSystem.inst.getLocalFilePath(url);
                let ver = WXFileSystem.inst.getFileVersion(url);
                // console.log(`start load sound, root = ${root}, url = ${url}, fullname = ${fullname}`);
                if (this._shouldCache(fullname) && await this.fileExists(fullname, ver)) {
                    // console.log("cache hit for ", root, fullname, ver);
                    return await this._loadSound(this.getWXFilePath(fullname));
                } else {
                    return await new Promise<any>((resolve, reject) => {
                        WXFileSystem.inst.download(soundSrc, fullname).then(
                            (filePath) => {
                                // console.log(`download ${soundSrc} success => ${filePath}`);
                                this._loadSound(<string>filePath).then(
                                    (sound)=>{
                                        resolve(sound);
                                    }, 
                                    (error1) => {
                                        console.error("_loadSound ", error1);
                                        reject(error1);
                                    }
                                );
                            },

                            (error2) => {
                                console.error("download ", error2);
                                reject(error2);
                            }
                        );
                    });
                }
            } else {
                return await this._loadSound(soundSrc);
            }
        }

        public onRemoveStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let sound = host.get(resource);
            if (sound) {
                sound.close();
            }
            return Promise.resolve();
        }

        public onTempLoadDone(host: RES.ProcessHost, sound: egret.Sound, resource: RES.ResourceInfo) {
            sound.close();
            // console.log("temp load done, close sound ", resource.url);
        }

        private async _loadSound(soundUrl: string) {
            return new Promise((resolve, reject) => {
                let sound = new egret.Sound();
                sound.load(soundUrl);
                let onSuccess = () => {
                    sound.removeEventListener(egret.Event.COMPLETE, onSuccess, this);
                    sound.removeEventListener(egret.IOErrorEvent.IO_ERROR, onError, this);
                    resolve(sound);
                }

                let onError = () => {
                    sound.removeEventListener(egret.Event.COMPLETE, onSuccess, this);
                    sound.removeEventListener(egret.IOErrorEvent.IO_ERROR, onError, this);
                    let error = new RES.ResourceManagerError(1001, soundUrl);
                    reject(error);
                }

                sound.addEventListener(egret.Event.COMPLETE, onSuccess, this);
                sound.addEventListener(egret.IOErrorEvent.IO_ERROR, onError, this);
            });
        }
    }

    class WXBinaryProcessor extends WXGameLoaderBase implements RES.processor.Processor {

        private _wxSystemInfo: SystemInfo;
        private _needReadFileFlag;

        public constructor() {
            super();
            this._wxSystemInfo = null;
        }

        public async onLoadStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let root = resource.root;
            let url = resource.url;
            let xhrURL = url.indexOf('://') >= 0 ? url : root + url;
            if (RES["getVirtualUrl"]) {
                xhrURL = RES["getVirtualUrl"](xhrURL);
            }
            if (WXFileSystem.inst.isRemotePath(xhrURL)) {
                await this.prepareNewbieLoads(resource);
                let fullname = WXFileSystem.inst.getLocalFilePath(url);
                let ver = WXFileSystem.inst.getFileVersion(url);
                // console.log(`start load binary, root = ${root}, url = ${url}, fullname = ${fullname}`);
                if (this._shouldCache(fullname) && await this.fileExists(fullname, ver)) {
                    // console.log("cache hit for ", root, fullname, ver);
                    return await WXFileSystem.inst.readFile(fullname);
                } else {
                    let content = await WXFileSystem.inst.xhrLoad(xhrURL, fullname, "arraybuffer");
                    // console.log(`download ${xhrURL} success => ${this.getWXFilePath(fullname)}`);
                    if (this._needReadFile()) {
                        content = WXFileSystem.inst.readFile(fullname);
                    }
                    return content;
                }
            } else {
                return await WXFileSystem.inst.readFile(xhrURL);
            }
        }

        public onRemoveStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            return Promise.resolve();
        }

        private _needReadFile(): boolean {
            if (!this._wxSystemInfo) {
                this._wxSystemInfo = wx.getSystemInfoSync();
                let sdkVersion = this._wxSystemInfo.SDKVersion;
                let platform = this._wxSystemInfo.system.split(" ").shift();
                this._needReadFileFlag = ((sdkVersion <= '2.2.3') && (platform == "iOS"));
            }
            return this._needReadFileFlag;
        }
    }

    class WXJsonProcessor extends WXGameLoaderBase implements RES.processor.Processor {

        public async onLoadStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let root = resource.root;
            let url = resource.url;
            let xhrURL = url.indexOf('://') >= 0 ? url : root + url;
            if (RES["getVirtualUrl"]) {
                xhrURL = RES["getVirtualUrl"](xhrURL);
            }
            if (WXFileSystem.inst.isRemotePath(xhrURL)) {
                await this.prepareNewbieLoads(resource);
                let fullname = WXFileSystem.inst.getLocalFilePath(url);
                let ver = WXFileSystem.inst.getFileVersion(url);
                //console.log(`${fullname} ${url} ${ver}`);
                // console.log(`start load json, root = ${root}, url = ${url}, fullname = ${fullname}`);
                if (this._useLocal(fullname) || (this._shouldCache(fullname) && await this.fileExists(fullname, ver))) {
                    //console.log("cache hit for ", root, fullname, ver);
                    let data = await WXFileSystem.inst.readFile(fullname, "utf8");
                    let json = JSON.parse(<string>data);
                    //console.log(`${<string>data}`);
                    return json;
                } else {
                    let content = <string> await WXFileSystem.inst.xhrLoad(xhrURL, fullname, null, true);
                    // console.log(`download ${xhrURL} success => ${this.getWXFilePath(fullname)}`);
                    return JSON.parse(content);
                }
            } else {
                let data = await WXFileSystem.inst.readFile(xhrURL, "utf8");
                return JSON.parse(<string>data);
            }
        }

        public onRemoveStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            return Promise.resolve();
        }

        protected _useLocal(fullname:string):boolean {
            // 这两个文件就用本地的.
            let keywords = ["serverlist", "wxconfig"];
            for (let i = 0; i < keywords.length; ++ i) {
                if (fullname.indexOf(keywords[i]) >= 0) {
                    return true;
                }
            }
            return false;
        }

        protected _shouldCache(fullname: string): boolean {
            //let keywords = ["serverlist", "wxconfig"];
            let keywords = [];
            for (let i = 0; i < keywords.length; ++ i) {
                if (fullname.indexOf(keywords[i]) >= 0) {
                    return false;
                }
            }
            return true;
        }
    }

    class WXTextProcessor extends WXGameLoaderBase implements RES.processor.Processor {

        public async onLoadStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            let root = resource.root;
            let url = resource.url;
            let xhrURL = url.indexOf('://') >= 0 ? url : root + url;
            if (RES["getVirtualUrl"]) {
                xhrURL = RES["getVirtualUrl"](xhrURL);
            }
            if (WXFileSystem.inst.isRemotePath(xhrURL)) {
                await this.prepareNewbieLoads(resource);
                let fullname = WXFileSystem.inst.getLocalFilePath(url);
                let ver = WXFileSystem.inst.getFileVersion(url);
                // console.log(`start load text, root = ${root}, url = ${url}, fullname = ${fullname}`);
                if (this._shouldCache(fullname) && await this.fileExists(fullname, ver)) {
                    // console.log("cache hit for ", root, fullname, ver);
                    return await WXFileSystem.inst.readFile(fullname, "utf8");
                } else {
                    // console.log(`download ${xhrURL} success => ${this.getWXFilePath(fullname)}`);
                    return await WXFileSystem.inst.xhrLoad(xhrURL, fullname, null, true);
                }
            } else {
                return await WXFileSystem.inst.readFile(xhrURL, "utf8");
            }
        }

        public onRemoveStart(host: RES.ProcessHost, resource: RES.ResourceInfo) {
            return Promise.resolve();
        }
    }

    export function getFSRoot() {
        return WXFileSystem.inst.fsRoot;
    }
    export async function initLoaders() {
        RES.processor.map("image", new WXImageProcessor());
        RES.processor.map("bin", new WXBinaryProcessor());
        RES.processor.map("sound", new WXSoundProcessor());
        RES.processor.map("json", new WXJsonProcessor());
        RES.processor.map("text", new WXTextProcessor());
        await WXFileSystem.inst.initFileVersionInfos();
    }
}