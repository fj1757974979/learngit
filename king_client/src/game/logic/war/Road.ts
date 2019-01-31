module War {

	export class RoadType {
		public static LAND = 1;
		public static WATER = 2;
	}

	export class PathPoint {
		private _x: number;
		private _y: number;
		private _isDayPoint: boolean;
		private _nextDayPoint: PathPoint;

		public constructor(x: number, y: number) {
			this._x = x;
			this._y = y;
			this._isDayPoint = false;
			this._nextDayPoint = null;
		}

		public get x(): number {
			return this._x;
		}

		public get y(): number {
			return this._y;
		}

		public get isDayPoint(): boolean {
			return this._isDayPoint;
		}

		public set isDayPoint(b: boolean) {
			this._isDayPoint = b;
		}

		public get nextDayPoint(): PathPoint {
			return this._nextDayPoint;
		}

		public set nextDayPoint(p: PathPoint) {
			this._nextDayPoint = p;
		}

		public toString(): string {
			return `(${this._x}, ${this._y})`;
		}
	}

	export class Road {

		private _id: number;
		private _fromCityId: number;
		private _toCityId: number;
		private _distance: number;
		private _coords: Array<PathPoint>;
		private _dayno2Coords: Collection.Dictionary<number, Array<PathPoint>>;
		private _conf: any;
		private _playAni: boolean;

		// <fromCityId,<toCityId,roadId>>
		private static _cityRoadInfos: Collection.Dictionary<number, Collection.Dictionary<number, number>> = null;
		public static genRoadsByCity(cityId: number): Array<Road> {
			if (!Road._cityRoadInfos) {
				Road._cityRoadInfos = new Collection.Dictionary<number, Collection.Dictionary<number, number>>();
				let roadIds = Data.road.keys;
				for (let roadId of roadIds) {
					let roadData = Data.road.get(roadId);
					let city1 = <number>roadData.city1;
					let city2 = <number>roadData.city2;
					if (!Road._cityRoadInfos.containsKey(city1)) {
						let info = new Collection.Dictionary<number, number>();
						Road._cityRoadInfos.setValue(city1, info);
					}
					Road._cityRoadInfos.getValue(city1).setValue(city2, roadId);
					if (!Road._cityRoadInfos.containsKey(city2)) {
						let info = new Collection.Dictionary<number, number>();
						Road._cityRoadInfos.setValue(city2, info);
					}
					Road._cityRoadInfos.getValue(city2).setValue(city1, roadId);
				}
			}
			let info = Road._cityRoadInfos.getValue(cityId);
			if (!info) {
				return [];
			} else {
				let toCityIds = info.keys();
				let ret = new Array<Road>();
				for (let toCityId of toCityIds) {
					let road = new Road(info.getValue(toCityId), cityId, toCityId);
					ret.push(road);
				}
				return ret;
			}
		}

		public constructor(id: number, from: number, to: number) {
			this._id = id;
			this._fromCityId = from;
			this._toCityId = to;
			this._conf = Data.road.get(id);
			this._distance = <number>this._conf.distance;
			// this._pointComs = null;
			this._playAni = false;
			this._initPathCoords();
		}

		public get id(): number {
			return this._id;
		}

		public get fromCityId(): number {
			return this._fromCityId;
		}

		public get toCityId(): number {
			return this._toCityId;
		}

		public get dayno(): number {
			return this._distance;
		}

		// public get dispatchDayno(): number {
		// 	return this._dispatchDayno;
		// }

		//足印
		// public async showRoadPointAnimation(b: boolean) {
		// 	if (!this._pointComs) {
		// 		let campInfo = CampignInfoMgr.inst.currentCampignInfo;
		// 		let city = campInfo.getCity(this._fromCityId);
		// 		let idx = city.renderIdx - 1;
		// 		let parent = city.parent;
		// 		this._pointComs = new Array<RoadPointCom>();
		// 		for (let i = 1; i < this._coords.length - 1; ++ i) {
		// 			let coord = this._coords[i];
		// 			if (!coord.isDayPoint) {
		// 				let pointCom = fairygui.UIPackage.createObject(PkgName.campign, "pathPointCom", RoadPointCom).asCom as RoadPointCom;
		// 				parent.addChild(pointCom);
		// 				pointCom.x = coord.x;
		// 				pointCom.y = coord.y;
		// 				parent.setChildIndex(pointCom, idx);
		// 				let nextCoord = this._coords[i + 1];
		// 				let fx = coord.x;
		// 				let fy = coord.y;
		// 				let tx = nextCoord.x;
		// 				let ty = nextCoord.y;
		// 				let angel = (Math.atan2(ty - fy, tx - fx) + 2*Math.PI) % (2*Math.PI);
		// 				pointCom.rotation = angel * (180/Math.PI);
		// 				pointCom.scaleX = 0.5;
		// 				pointCom.scaleY = 0.5;
		// 				pointCom.visible = false;
		// 				this._pointComs.push(pointCom);
		// 			}
		// 		}
		// 	}
		// }

		private _initPathCoords() {
			let coords = new Collection.List<PathPoint>();
			let confCoords = <Array<string>>this._conf.coord;
			for (let i = 0; i < confCoords.length; i ++) {
				let coordStr = confCoords[i];
				let coordStrs = coordStr.split(",");
				let point = new PathPoint(parseInt(coordStrs[0]), parseInt(coordStrs[1]));
				coords.push(point);
			}
			if (this._fromCityId > this._toCityId) {
				coords.reverse();
			}

			// // 起点
			let fromCity = CityMgr.inst.getCity(this._fromCityId);
			let startPoint = new PathPoint(fromCity.cityPoint.x, fromCity.cityPoint.y);
			coords.pushFront(startPoint);
			// 终点
			let toCity = CityMgr.inst.getCity(this._toCityId);
			let endPoint = new PathPoint(toCity.cityPoint.x, toCity.cityPoint.y);
			coords.push(endPoint);

			// let startPoint = coords.getFront();
			// let endPoint = coords.getBack();

			// 计算分段长度和总长度
			let totalLen = 0;
			let sectionLens = new Array<number>();
			coords.forEach((point: PathPoint) => {
				let prevPoint = coords.getPrev(point);
				if (prevPoint) {
					let len = Math.sqrt(Math.pow(prevPoint.x - point.x, 2) + Math.pow(prevPoint.y - point.y, 2));
					totalLen += len;
					sectionLens.push(len);
				}
			});
			// 计算daypoint
			this._dayno2Coords = new Collection.Dictionary<number, Array<PathPoint>>();
			let dayno = this._distance;
			if (dayno > 1) {
				let dayLen = totalLen / dayno;
				let point = coords.getFront();
				let cursorPoint = point;
				let nextPoint = coords.getNext(point);
				let i = 0;
				let dCnt = 1;
				let curLen = sectionLens[i];
				while (true) {
					if (!nextPoint) {
						break;
					}
					if (dCnt >= dayno) {
						endPoint.isDayPoint = true;
						break;
					} else if (curLen > dayLen * dCnt) {
						let angel = Math.atan2(nextPoint.y - point.y, nextPoint.x - point.x);
						angel = (2*Math.PI + angel) % (2*Math.PI);
						let r = sectionLens[i] - (curLen - dayLen * dCnt);
						let x = point.x + r * Math.cos(angel);
						let y = point.y + r * Math.sin(angel);
						let dayPoint = new PathPoint(x, y);
						dayPoint.isDayPoint = true;
						coords.push(dayPoint, cursorPoint);
						cursorPoint = dayPoint;
						dCnt ++;
					} else {
						i ++;
						point = nextPoint;
						nextPoint = coords.getNext(point);
						cursorPoint = point;
						if (sectionLens[i]) {
							curLen += sectionLens[i];
						}
					}
				}
				this._coords = new Array<PathPoint>();
				let daynoCoords = new Array<PathPoint>();
				let curDayno = 1;
				coords.forEach((point: PathPoint) => {
					this._coords.push(point);
					daynoCoords.push(point);
					if (point.isDayPoint) {
						this._dayno2Coords.setValue(curDayno, daynoCoords);
						curDayno ++;
						daynoCoords = new Array<PathPoint>();
						// 后一天的起点
						daynoCoords.push(point);
					}
				});
			} else if (dayno == 1) {
				endPoint.isDayPoint = true;
				this._dayno2Coords.setValue(1, this._coords);
			} else {
				console.debug(`error road dayno from city${this._fromCityId} to city${this._toCityId}`);
			}
		} // end _initPathCoords

		public getPathCoordsByDayno(dayno: number): Array<PathPoint> {
			// console.debug(`${this._dayno2Coords.toString()}`);
			return this._dayno2Coords.getValue(dayno);
		}

		public getPathPointByDayno(dayno: number): PathPoint {
			if (dayno == 0) {
				let city = CityMgr.inst.getCity(this._fromCityId);
				return new PathPoint(city.cityPoint.x, city.cityPoint.y);
			} else {
				let pathCoords = this.getPathCoordsByDayno(dayno);
				if (pathCoords) {
					return pathCoords[pathCoords.length - 1];
				} else {
					return null;
				}
			}
		}

		public getRestPathCoordsAfterDayno(dayno: number): Array<PathPoint> {
			let ret: Array<PathPoint> = [];
			for (let i = dayno; i <= this._distance; ++ i) {
				ret.concat(this.getPathCoordsByDayno(i));
			}
			return ret;
		}

		public get roadType(): RoadType {
			let terrain = this._conf.terrain;
			if (terrain == 6) {
				return RoadType.WATER;
			} else {
				return RoadType.LAND;
			}
		}

		public static countCityPathDistance(path: Array<number>) {
			let distance = 0;
			for (let i = 1; i < path.length; i++) {
				let from = path[i - 1];
				let to = path[i];
				let formCity = CityMgr.inst.getCity(from);
				distance += formCity.getAdjCityDayno(CityMgr.inst.getCity(to));
			}
			return distance;
		}

		// public static calcTotalDayno(path: Array<number>) {
		// 	let campInfo = CampignInfoMgr.inst.currentCampignInfo;
		// 	let dayno = 0;
		// 	for (let i = 1; i < path.length; i ++) {
		// 		let from = path[i - 1];
		// 		let to = path[i];
		// 		let fcity = campInfo.getCity(from);
		// 		dayno += fcity.getAdjCityDayno(campInfo.getCity(to));
		// 	}
		// 	return dayno;
		// }

		// public static calcTotalDispatchDayno(path: Array<number>) {
		// 	let campInfo = CampignInfoMgr.inst.currentCampignInfo;
		// 	let dayno = 0;
		// 	for (let i = 1; i < path.length; i ++) {
		// 		let from = path[i - 1];
		// 		let to = path[i];
		// 		let fcity = campInfo.getCity(from);
		// 		dayno += fcity.getAdjCityDispatchDayno(campInfo.getCity(to));
		// 	}
		// 	return dayno;
		// }
	}
}