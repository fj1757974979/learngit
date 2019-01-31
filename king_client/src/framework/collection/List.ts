///<reference path="Util.ts" />

module Collection {

	// 链表项
	class Entry<T> {
		public prev: Entry<T>;
		public next: Entry<T>;
		public obj: T;

		public constructor() {
			this.prev = null;
			this.next = null;
			this.obj = null;
		}
	}

	// 双向链表
	export class List<T> {
		private _objMap: Dictionary<T, Entry<T>>;
		private _head: Entry<T>;

		public constructor() {
			this._head = new Entry<T>();
			this._head.prev = this._head;
			this._head.next = this._head;
			this._objMap = new Dictionary<T, Entry<T>>();
		}

		private _insert(obj: T, prev: Entry<T>, next: Entry<T>) {
			let elem = new Entry<T>();
			elem.obj = obj;
			this._objMap.setValue(obj, elem);
			elem.prev = prev;
			elem.next = next;
			next.prev = elem;
			prev.next = elem;
		}

		private _remove(elem: Entry<T>) {
			elem.next.prev = elem.prev;
			elem.prev.next = elem.next;
			this._objMap.remove(elem.obj);
		}

		public push(obj: T, after?: T) {
			let entry: Entry<T> = null;
			if (after) {
				entry = this._objMap.getValue(after);
			}
			if (!entry) {
				entry = this._head.prev;
			}
			this._insert(obj, entry, entry.next);
		}

		public pushFront(obj: T, before?: T) {
			let entry: Entry<T> = null;
			if (before) {
				entry = this._objMap.getValue(before);
			}
			if (!entry) {
				entry = this._head.next;
			}
			this._insert(obj, entry.prev, entry);
		}

		public isEmpty(): boolean {
			return this._head.next == this._head || this._head.prev == this._head;
		}

		public getFront(): T {
			if (this.isEmpty()) {
				return null;
			}
			return this._head.next.obj;
		}

		public popFront(): T {
			if (this.isEmpty()) {
				return null;
			}
			let elem = this._head.next;
			this._remove(elem);
			return elem.obj;
		}

		public getBack(): T {
			if (this.isEmpty()) {
				return null;
			}
			return this._head.prev.obj;
		}

		public popBack(): T {
			if (this.isEmpty()) {
				return null;
			}
			let elem = this._head.prev;
			this._remove(elem);
			return elem.obj;
		}

		public getNext(obj: T): T {
			let elem = this._objMap.getValue(obj);
			return elem.next.obj;
		}

		public getPrev(obj: T): T {
			let elem = this._objMap.getValue(obj);
			return elem.prev.obj;
		}

		public reverse() {
			for (let entry = this._head.next; entry != this._head;) {
				let n = entry.next;
				entry.next = entry.prev;
				entry.prev = n;
				entry = n;
			}
			let headNext = this._head.next;
			let headPrev = this._head.prev;
			this._head.next = headPrev;
			this._head.prev = headNext;
			//this._head.prev, this._head.next = this._head.next, this._head.prev;
		}

		public remove(obj: T) {
			let elem = this._objMap.getValue(obj);
			if (elem) {
				this._remove(elem);
			}
		}

		public forEach(func: (obj:T) => void, reverse: boolean = false) {
			if (reverse) {
				for (let entry = this._head.prev; entry != this._head; entry = entry.prev) {
					func(entry.obj);
				}
			} else {
				for (let entry = this._head.next; entry != this._head; entry = entry.next) {
					func(entry.obj);
				}
			}
		}

		public get length(): number {
			return this._objMap.keys.length;
		}

		public clear() {
			this._head.next = this._head;
			this._head.prev = this._head;
			this._objMap.clear();
		}
	}
}