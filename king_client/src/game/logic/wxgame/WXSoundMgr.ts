module WXGame {
	export class WXSoundMgr {

		private static _inst: WXSoundMgr;
		private _musicAudio: InnerAudioContext;
		private _soundAudioPool: Array<InnerAudioContext>;
		private _soundPoolIdx: number;
		private _SOUND_POOL_SIZE: number;

		public static get inst(): WXSoundMgr {
			if (WXSoundMgr._inst == null) {
				WXSoundMgr._inst = new WXSoundMgr();
			}
			return WXSoundMgr._inst;
		}

		public constructor() {
			this._musicAudio = wx.createInnerAudioContext();
			this._SOUND_POOL_SIZE = 10;
			this._soundAudioPool = [];
			for (let i = 0; i < this._SOUND_POOL_SIZE; ++ i) {
				this._soundAudioPool.push(wx.createInnerAudioContext());
			}
			this._soundPoolIdx = 0;
			// wx.onShow(() => {
			// 	this._musicAudio.play();
			// });
			// wx.onHide(() => {
			// 	this._musicAudio.pause();
			// });
		}

		private _genSoundPoolIdx(): number {
			this._soundPoolIdx = (this._soundPoolIdx + 1) % this._SOUND_POOL_SIZE;
			return this._soundPoolIdx;
		}

		public playSound(resName: string, volume: number) {
			let src = RES.getRes(resName);
			if (src) {
				let audio = wx.createInnerAudioContext(); //this._soundAudioPool[this._genSoundPoolIdx()];
				// audio.stop();
				audio.src = src;
				audio.volume = volume;
				audio.onCanplay(() => {
					audio.play();
				});
				audio.onStop(() => {
					audio.destroy();
				})
				// audio.autoplay = true;
				console.log("WXSoundMgr playSound", resName, src, volume);
			} else {
				RES.getResAsync(resName);
			}
		}

		public async playSoundAsync(resName: string, volume: number) {
			RES.getResAsync(resName).then(src => {
				console.log("WXSoundMgr playSoundAsync", resName, src, volume);
				let audio = wx.createInnerAudioContext(); //this._soundAudioPool[this._genSoundPoolIdx()];
				// audio.stop();
				audio.src = src;
				audio.volume = volume;
				audio.onCanplay(() => {
					audio.play();
				});
				audio.onStop(() => {
					audio.destroy();
				})
				// audio.autoplay = true;
			})
		}

		public playMusic(music: string, volume: number) {
			RES.getResAsync(music).then(src => {
				this._musicAudio.stop();
				this._musicAudio.src = src;
				this._musicAudio.loop = true;
				this._musicAudio.volume = volume;
				this._musicAudio.onCanplay(() => {
					this._musicAudio.play();
				})
				// this._musicAudio.autoplay = true;
				console.log("WXSoundMgr playMusic", music, src, volume);
			});
		}

		public setMusicVolume(volume: number) {
			this._musicAudio.volume = volume;
		}

		public stopMusic() {
			this._musicAudio.stop();
		}
	}
}