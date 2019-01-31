module War {

	export class WarStatusBase {
		private _time: number;

		public constructor(host: any) {
			this._time = -1;
		}

		public get remainTime(): number {
			return this._time;
		}

		public set remainTime(t: number) {
			this._time = t;
		}

		public async enter(...param: any[]) {
			// to be implemented
		}

		public async leave() {
			// to be implemented
		}

		public async updateStatus(...param: any[]) {
			// to be implemented
		}

		public get name(): number {
			return -1;
		}

		public get isWarOver(): boolean {
			return false;
		}

		protected startHeartbeat() {
			if (this._time > 0) {
				fairygui.GTimers.inst.add(1000, this._time, this.heartbeat, this);
			}
		}

		protected stopHeartbeat() {
			fairygui.GTimers.inst.remove(this.heartbeat, this);
		}

		protected heartbeat() {

		}
	}

	export class NoneStatus extends WarStatusBase {
		public get name(): number {
			return ST_NONE;
		}
	}

	export class WarStatusDelegateBase extends Core.BindingDelegate {
		protected _statusObjs: Collection.Dictionary<number, WarStatusBase>;
		protected _curStatusObj: WarStatusBase;
		protected _host: any;

		public constructor() {
			super();
			this._statusObjs = new Collection.Dictionary<number, WarStatusBase>();
			this._curStatusObj = new NoneStatus(null);
		}

		protected setDelegateHost(host: any) {
			this._host = host;
			this.initStatus();
		}

		public get host(): any {
			return this._host;
		}

		public inStatus(stName: number): boolean {
			return this._curStatusObj.name == stName;
		}

		protected initStatus() {
			console.error("initStatus not implemented");
		}

		public async changeStatus(stName: number, time: number = -1, ...param: any[]) {
			if (this.inStatus(stName)) {
				this._curStatusObj.updateStatus(...param);
				return;
			}
			await this._curStatusObj.leave();
			let statusObj = this._statusObjs.getValue(stName);
			if (statusObj) {
				this._curStatusObj = statusObj;
				this._curStatusObj.remainTime = time;
				await this._curStatusObj.enter(...param);
			} else {
				this._curStatusObj = new NoneStatus(this._host);
			}
		}

		public async updateCurStatus(stName: number, ...param: any[]) {
			if (this.inStatus(stName)) {
				this._curStatusObj.updateStatus(...param);
			} else {
				return false;
			}
		}

		public getCurStatusRemainTime(): number {
			return this._curStatusObj.remainTime;
		}

		public resetToNoneStatus() {
			this._curStatusObj = new NoneStatus(null);
		}
	}
}