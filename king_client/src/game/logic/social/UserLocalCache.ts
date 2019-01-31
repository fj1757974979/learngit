module Social {

	export class UserLocalCache {

		private static _inst: UserLocalCache;

		public static get inst(): UserLocalCache {
			if (!UserLocalCache._inst) {
				UserLocalCache._inst = new UserLocalCache();
			}
			return UserLocalCache._inst;
		}

		private _cacheData: any;
		private _cacheKey: string = "userLocalCache";

		public constructor() {
			this._loadData();
		}

		private _loadData() {
			let dataStr = egret.localStorage.getItem(this._cacheKey);
			if (!dataStr || dataStr == "") {
				this._cacheData = {};
			} else {
				let data = JSON.parse(dataStr);
				this._cacheData = data;
			}
		}

		private _saveData() {
			egret.localStorage.setItem(this._cacheKey, JSON.stringify(this._cacheData));
		}

		public setUserCountry(uid: Long, country: string) {
			let key = `${uid}`;
			let info = this._cacheData[key];
			if (!info) {
				info = {};
				info["country"] = country;
				this._cacheData[key] = info;
				this._saveData();
			}
			else {
				if (info["country"] != country) {
					info["country"] = country;
					this._saveData();
				}
			}
		}

		public getUserCountry(uid: Long): string {
			if (uid == Player.inst.uid) {
				return LanguageMgr.inst.countryCode;
			}
			let key = `${uid}`;
			let info = this._cacheData[key];
			if (info) {
				return info["country"];
			} else {
				return null;
			}
		}
	}
}