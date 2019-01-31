
class SoundAction extends fairygui.ControllerAction {
	private _soundRes: string = null;
	private _isAsync: boolean = false;
	constructor(soundRes: string, isAsync: boolean) {
		super();
		this._soundRes = soundRes;
		this._isAsync = isAsync;
	}

	protected enter(controller: fairygui.Controller): void {
		if (!this._isAsync)
			SoundMgr.inst.playSound(this._soundRes);
		else
			SoundMgr.inst.playSoundAsync(this._soundRes);
	}
}

class NativeSoundApi {
	public static playSound(sound:string, volume:number) {
		Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.PLAY_SOUND, {"sound":sound.replace("_mp3", ""), "volume":volume});
	}

	public static playMusic(music:string, volume:number) {
		Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.PLAY_MUSIC, {"sound":music.replace("_mp3", ""), "volume":volume});
	}

	public static setMusicVolume(volume:number) {
		Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.SET_MUSIC_VOLUME, {"volume":volume});
	}

	public static stopMusic() {
		Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.STOP_MUSIC, {});
	}
}

class WXGameSoundApi {
	public static playSound(sound: string, volume: number) {
		WXGame.WXSoundMgr.inst.playSound(sound, volume);
	}

	public static playSoundAsync(sound: string, volume: number) {
		WXGame.WXSoundMgr.inst.playSoundAsync(sound, volume);
	}

	public static playMusic(music: string, volume: number) {
		WXGame.WXSoundMgr.inst.playMusic(music, volume);
	}

	public static setMusicVolume(volume: number) {
		WXGame.WXSoundMgr.inst.setMusicVolume(volume);
	}

	public static stopMusic() {
		WXGame.WXSoundMgr.inst.stopMusic();
	}
}

class SoundMgr {
	private static _inst: SoundMgr;

	public musicVolume: number;
	public soundVolume: number;
	private musicChannel: egret.SoundChannel;
	private _fadeMusicChannel: egret.SoundChannel;
	private soundTimer: { [key: string]: number } = {}; // 用于去除重复播放的音效
	private _soundLevel: number = 3;
	private _musicLevel: number = 3;
	public useNativeSound: boolean = false;

	public get soundLevel(): number { return this._soundLevel; }
	public get musicLevel(): number { return this._musicLevel; }

	public set soundLevel(val: number) {
		val = Math.floor(val);
		if (val < 0) val = 0;
		if (val > 3) val = 3;
		this._soundLevel = val;
		this.soundVolume = val / 3;
		//fairygui.UIConfig.buttonSoundVolumeScale = this.soundVolume;
		fairygui.GRoot.inst.volumeScale = this.soundVolume;
		egret.localStorage.setItem("soundLevel", val.toString());
	}

	public set musicLevel(val: number) {
		val = Math.floor(val);
		if (val < 0) val = 0;
		if (val > 3) val = 3;
		this._musicLevel = val;
		this.setMusicVolume(val / 3);
		egret.localStorage.setItem("musicLevel", val.toString());
	}

	public static get inst(): SoundMgr {
		if (!SoundMgr._inst) {
			SoundMgr._inst = new SoundMgr();
		}
		return SoundMgr._inst;
	}

	constructor() {
		let soundLevel: any = egret.localStorage.getItem("soundLevel");
		let musicLevel: any = egret.localStorage.getItem("musicLevel");


		if (!soundLevel) soundLevel = 3;
		else soundLevel = Number(soundLevel);

		if (!musicLevel) musicLevel = 3;
		else musicLevel = Number(musicLevel);

		this.soundLevel = soundLevel;
		this.musicLevel = musicLevel;
		//fairygui.UIConfig.buttonSound = "button_mp3";
	}

	private recordSoundTimer(resName: string) {
		this.soundTimer[resName] = egret.getTimer();
	}

	public cleanSoundTimerRecords() {
		this.soundTimer = {};
	}

	private checkSound(resName: string): boolean {
		let timer: number = this.soundTimer[resName];
		if (!timer) return true;

		if (egret.getTimer() - timer > 200) return true;

		return false;
	}

	public playSound(resName: string, volume?:number): egret.SoundChannel {
		if (!this.checkSound(resName)) return;
		if (volume == 0) return;
		else if (this.soundVolume == 0) return;

		this.recordSoundTimer(resName);
		if (window.support.nativeSound) {
			NativeSoundApi.playSound(resName, volume || this.soundVolume);
			return;
		}

		// if (Core.DeviceUtils.isWXGame()) {
		// 	WXGameSoundApi.playSound(resName, volume || this.soundVolume);
		// 	return;
		// }

		let sound = RES.getRes(resName);
		if (sound) {
			let channel: egret.SoundChannel = sound.play(0, 1);
			if (volume != undefined) {
				channel.volume = volume;
			} else {
				channel.volume = this.soundVolume;
			}
			return channel
		} 
	}

	public playSoundAction(resName: string, isAsync: boolean = false): SoundAction {
		return new SoundAction(resName, isAsync);
	}

	public playSoundAsync(resName: string, soundVolume?:number): void {
		try {
			if (!this.checkSound(resName)) return;

			if (!soundVolume) soundVolume = this.soundVolume;

			if (soundVolume == 0) return;

			// console.log("play sound async ", soundVolume);

			this.recordSoundTimer(resName);
			if (window.support.nativeSound) {
				NativeSoundApi.playSound(resName, soundVolume);
				return;
			}

			// if (Core.DeviceUtils.isWXGame()) {
			// 	WXGameSoundApi.playSoundAsync(resName, this.soundVolume);
			// 	return;
			// }

			RES.getResAsync(resName).then(sound => {
				let channel: egret.SoundChannel = sound.play(0, 1);
				channel.volume = soundVolume;
			});
		} catch (e) {
			console.error(e);
		}
	}

	public setSoundVolume(volume: number): void {
		this.soundVolume = volume;
	}

	private _setMusicVolume(volume: number): void {
		if (window.support.nativeSound) {
			NativeSoundApi.setMusicVolume(volume);
			return;
		}
		// if (Core.DeviceUtils.isWXGame()) {
		// 	WXGameSoundApi.setMusicVolume(volume);
		// 	return;
		// }
		if (this.musicChannel) {
			this.musicChannel.volume = volume;
			if (Core.DeviceUtils.isWXGame() && volume == 0) 
				this.stopBgMusic();
		}
	}

	public setMusicVolume(volume: number): void {
		this.musicVolume = volume;
		this._setMusicVolume(volume);
	}

	public muteMusic(b: boolean) {
		// console.log("muteMusic", b);
		if (b) {
			this._setMusicVolume(0);
		} else {
			this._setMusicVolume(this.musicVolume);
		}
	}

	public async fadeoutSound(channel: egret.SoundChannel) {
		this._fadeMusicChannel = channel;
		for (let i = 1; i >= 0; i -= 0.1) {
			if (!this._fadeMusicChannel) return;
			try {
				this._fadeMusicChannel.volume = this.musicVolume * i;
			} catch (e) {
				this._fadeMusicChannel = null;
				return
			}
			await fairygui.GTimers.inst.waitTime(100);
		}
		try {
			if (this._fadeMusicChannel) {
				this._fadeMusicChannel.stop();
			}
		} catch (e) {

		}
		this._fadeMusicChannel = null;
	}

	public stopBgMusic(fadeout: boolean = true): void {
		if (window.support.nativeSound) {
			NativeSoundApi.stopMusic();
			return;
		}
		// if (Core.DeviceUtils.isWXGame()) {
		// 	WXGameSoundApi.stopMusic();
		// 	return;
		// }
		fadeout = false;
		if (this.musicChannel) {
			if (fadeout) {
				this.fadeoutSound(this.musicChannel);
			} else {
				this.musicChannel.stop();
			}
			this.musicChannel = null;
		}
	}

	public playBgMusic(resName: string): void {
		if (this.musicVolume == 0) return;
		if (window.support.nativeSound) {
			NativeSoundApi.playMusic(resName, this.musicVolume);
			return;
		}
		// if (Core.DeviceUtils.isWXGame()) {
		// 	WXGameSoundApi.playMusic(resName, this.musicVolume);
		// 	return;
		// }
		try {
			RES.getResAsync(resName).then(music => {
				this.stopBgMusic();
				this.musicChannel = music.play();
				this.musicChannel.volume = this.musicVolume;
			}).catch(err => {
				console.log("err when loading music ", resName, err);
			});
		} catch (e) {
			console.error(e);
		}
	}
}
