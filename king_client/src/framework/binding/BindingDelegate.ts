module Core {

	class BindingItem {
		public _callback: (value: any) => void;
		public _thisArg: any;
		public _watch: Core.Watcher;
	}

	export class BindingDelegate {
		private _watchers: Collection.Dictionary<string, Collection.Dictionary<BindingItem, boolean>>;

		public constructor() {
			this._watchers = new Collection.Dictionary<string, Collection.Dictionary<BindingItem, boolean>>();
		}

		public watchProp(prop: string, callback: (value: any) => void, thisArg: any) {
			if (!this._watchers.containsKey(prop)) {
				this._watchers.setValue(prop, new Collection.Dictionary<BindingItem, boolean>());
			}
			let items = this._watchers.getValue(prop);
			let item = new BindingItem();
			item._callback = callback;
			item._thisArg = thisArg;
			item._watch = Core.Binding.bindHandler(this, [prop], callback, thisArg);
			items.setValue(item, true);
		}

		public unwatchProp(prop: string, callback: (value: any) => void, thisArg: any) {
			if (!this._watchers.containsKey(prop)) {
				return;
			}
			let items = this._watchers.getValue(prop);
			let dels = new Array<BindingItem>();
			items.forEach((item, _) => {
				if (item._callback == callback && item._thisArg == thisArg) {
					item._watch.unwatch();
					dels.push(item);
				}
			});
			dels.forEach(item => {
				items.remove(item);
			});
		}
	}
}