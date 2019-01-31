const fileutil = require('./file-util');
const path = fileutil.path;
const fs = fileutil.fs;
const WXFS = wx.getFileSystemManager();

class BinaryProcessor {

    onLoadStart(host, resource) {

        const {
            root,
            url
        } = resource;

        return new Promise((resolve, reject) => {

            let xhrURL = url.indexOf('://') >= 0 ? url : root + url;
            if (RES['getVirtualUrl']) {
                xhrURL = RES['getVirtualUrl'](xhrURL);
            }
            if (path.isRemotePath(xhrURL)) {
                if (needCache(xhrURL)) {
                    const targetFilename = path.getLocalFilePath(url);
					          const ver = path.getFileVersion(url);
                    if (fs.existsSync(targetFilename, ver)) {
                        //缓存命中
						            //console.log('缓存命中:', url, ver);
                        let data = WXFS.readFileSync(path.getWxUserPath(targetFilename));
                        resolve(data);
                    } else {
                        //console.log("BinaryProcessor onLoadStart root:", root, "url:", url, "imageSrc:", xhrURL, " --> ", targetFilename, " version:", ver);
                        loadBinary(xhrURL).then((content) => {
                            const dirname = path.dirname(targetFilename);
                            fs.mkdirsSync(dirname);
                            fs.writeSync(targetFilename, content);
                            let needRead = needReadFile();
                            if (needRead) {
                                content = WXFS.readFileSync(path.getWxUserPath(targetFilename));
                            }
                            if (ver != undefined) {
                              let vp = path.getWxUserPath(targetFilename) + ".ver";
                              WXFS.writeFileSync(vp, ver);
                              //console.log("download done, write ", ver, " to file ", vp);
                            }
                            resolve(content);
                        }).catch((e) => {
                            reject(e);
                        });
                    }

                } else {
                    loadBinary(xhrURL).then((content) => {
                        resolve(content);
                    }).catch((e) => {
                        reject(e);
                    });
                }
            } else {
                const content = WXFS.readFileSync(xhrURL);
                resolve(content);
            }
        });
    }

    onRemoveStart(host, resource) {
        return Promise.resolve();
    }
}

let wxSystemInfo;

function needReadFile() {
    if (!wxSystemInfo) {
        wxSystemInfo = wx.getSystemInfoSync();
    }
    let sdkVersion = wxSystemInfo.SDKVersion;
    let platform = wxSystemInfo.system.split(" ").shift();
    return (sdkVersion <= '2.2.3') && (platform == 'iOS');
}

function loadBinary(xhrURL) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.responseType = "arraybuffer"
        xhr.onload = () => {
            resolve(xhr.response);
        }
        xhr.onerror = (e) => {
            const error = new RES.ResourceManagerError(1001, xhrURL);
            console.error(e);
            reject(error);
        }
        xhr.open("get", xhrURL);
        xhr.send();
    });

}

/**
 * 由于微信小游戏限制只有50M的资源可以本地存储，
 * 所以开发者应根据URL进行判断，将特定资源进行本地缓存
 */
function needCache(url) {
	return true;
}



const processor = new BinaryProcessor();
RES.processor.map("bin", processor);
