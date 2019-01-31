const fileutil = require('./file-util');
const path = fileutil.path;
const fs = fileutil.fs;
const WXFS = wx.getFileSystemManager();


/**
 * 重写的声音加载器，代替引擎默认的声音加载器
 * 该代码中包含了大量日志用于辅助开发者调试
 * 正式上线时请开发者手动删除这些注释
 */
class SoundProcessor {

    onLoadStart(host, resource) {

        const {
            root,
            url
        } = resource;
        let soundSrc = root + url;
        if (RES['getVirtualUrl']) {
            soundSrc = RES['getVirtualUrl'](soundSrc);
        }
        if (path.isRemotePath(soundSrc)) { //判断是本地加载还是网络加载
            if (!needCache(root, url)) {
                //无需缓存加载
                return loadSound(soundSrc);
            } else {
                //通过缓存机制加载
                const fullname = path.getLocalFilePath(url);
				const ver = path.getFileVersion(url);
                if (fs.existsSync(fullname, ver)) {
                    console.log('缓存命中:', url, ver);
                    return loadSound(path.getWxUserPath(fullname));
                } else {
					console.log("SoundProcessor onLoadStart root:", root, "url:", url, "soundSrc:", soundSrc, " --> ", fullname, " version:", ver);
                    return download(soundSrc, fullname)
                        .then((filePath) => {
                            fs.setFsCache(fullname, 1);
                            return loadSound(filePath);
                        },
                        (error) => {
                            console.error(error);
                            return;
                        });
                }
            }
        } else {
            //正常本地加载
            return loadSound(soundSrc);
        }
    }

    onRemoveStart(host, resource) {
		let sound = host.get(resource);
		if (sound) {
			sound.close();
		}
		console.log("removing sound ", resource.url);
        return Promise.resolve();
    }

	onTempLoadDone(host, sound, resource) {
		sound.close();
		console.log("temp load done, close sound ", resource.url);
	}
}



function loadSound(soundURL) {
    return new Promise((resolve, reject) => {
        let sound = new egret.Sound();
        sound.load(soundURL);
        let onSuccess = () => {
            resolve(sound);
        }

        let onError = () => {
            const e = new RES.ResourceManagerError(1001, soundURL);
            reject(e);
        }
        sound.addEventListener(egret.Event.COMPLETE, onSuccess, this);
        sound.addEventListener(egret.IOErrorEvent.IO_ERROR, onError, this);
    })
}


function download(url, target) {

    return new Promise((resolve, reject) => {
        const dirname = path.dirname(target);
        fs.mkdirsSync(dirname);
        const file_target = path.getWxUserPath(target);
        wx.downloadFile({
            url: url,
            filePath: file_target,
            success: (v) => {
                if (v.statusCode >= 400) {
                    try {
                        WXFS.accessSync(file_target);
                        WXFS.unlinkSync(file_target);
                    } catch (e) {

                    }
                    const message = `加载失败:${url}`;
                    reject(message);
                } else {
                    let version = path.getFileVersion(url);
                    if (version != undefined) {
                      let vp = file_target + ".ver";
                      WXFS.writeFileSync(vp, version);
                      //console.log("download done, write ", version, " to file ", vp);
                    }
                    resolve(file_target);
                }
            },
            fail: (e) => {
                const error = new RES.ResourceManagerError(1001, url);
                reject(error);
            }
        });
    });
}

/**
 * 由于微信小游戏限制只有50M的资源可以本地存储，
 * 所以开发者应根据URL进行判断，将特定资源进行本地缓存
 */
function needCache(root, url) {
	return true
}


const processor = new SoundProcessor();
RES.processor.map("sound", processor);
