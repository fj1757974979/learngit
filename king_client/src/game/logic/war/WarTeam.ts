module War {

    export class WarTeam extends TeamStatusDelegate {

        private _teamID: number;
        private _countryID: number;
        private _cityPath: Array<number>;   // 行走路径
        private _playerName: string;
        private _trip: number;  //已经走了多少
		private _teamCntWithSameDirAndRoad: number;

        private _char: Char;
        private _fromCity: number;
        private _toCity: number;
        private _totalDayno: number;    //路线总长度
        private _road: Road = null; // 在哪条路上
		private _roadDayno: number; // 在当前路上的第几天的位置
		private _roadPath: Array<PathPoint>; // 在这条路上该走的路线
		private _speed: number;
		private _destroyed: boolean;

		private _amount: number; // 与自己同路同方向的队伍的数量

        public constructor(teamData: pb.TeamData, initStatus: boolean = true) {
			super();
			this.setDelegateHost(this);
            this._teamID = teamData.ID;
            this._countryID = teamData.CountryID;
            this._cityPath = teamData.CityPath;
            this._trip = teamData.Trip;
			this._teamCntWithSameDirAndRoad = teamData.TeamAmount;
			this._char = null;
			this._roadPath = [];
			this._destroyed = false;
			this._amount = teamData.TeamAmount;

			if (this._cityPath && this._cityPath.length > 0) {
				this._fromCity = this._cityPath[0];
            	this._toCity = this._cityPath[this._cityPath.length - 1];
         		this._totalDayno = Road.countCityPathDistance(this._cityPath);
				 this._updateCurrentRoad();
			} else {
				this._fromCity = null;
				this._toCity = null;
				this._totalDayno = null;
			}

			this._amount = 0;

			if (initStatus) {
				// 初始化队伍状态
				this.changeStatus(teamData.State);
			}
        }

		public isMyTeam(): boolean {
			if (!WarTeamMgr.inst.myTeam) {
				return false;
			}
			return WarTeamMgr.inst.myTeam.teamID == this._teamID;
		}

		public set amount(amount: number) {
			this._amount = amount;
			this.updateCharAmount();
		}

		public get amount(): number {
			return this._amount;
		}

		public get road(): Road {
			return this._road;
		}

        private _updateCurrentRoad() {
			if (this._trip >= this._totalDayno) {
				// 已经到达目的地
				let fcityId = this._cityPath[this._cityPath.length - 2];
				let tcityId = this._cityPath[this._cityPath.length - 1];
				let fcity = CityMgr.inst.getCity(fcityId);
				let tcity = CityMgr.inst.getCity(tcityId);
				this._road = fcity.getRoad(tcity);
				let dn = this._road.dayno;
				let rest = 0;
				let point = null;
				while (rest < 30) {
					// 回溯30个像素
					let path = this._road.getPathCoordsByDayno(dn);
					for (let i = 1; i < path.length; i ++) {
						let p = path[i];
						let prevP = path[i - 1];
						rest += Math.sqrt(Math.pow(p.x - prevP.x, 2) + Math.pow(p.y - prevP.y, 2));
						if (rest >= 30) {
							point = prevP;
							break;
						}
					}
					if (point) {
						break;
					} else {
						dn --;
					}
				}
				if (point) {
					this._roadPath = [point];
				} else {
					let roadPath = this._road.getPathCoordsByDayno(this._road.dayno);
					// 路径只有目的城的前面一个路点
					this._roadPath = [roadPath[roadPath.length - 2]];
				}
				
			} else {
				this._trip ++;
				let path = this._cityPath;
				let dayno = this._trip;
				this._road = null;
				this._roadPath = [];
				for (let i = 0; i < path.length - 1; i ++) {
					let cityId = path[i];
					let nextCityId = path[i + 1];
					let from = CityMgr.inst.getCity(cityId);
					let to = CityMgr.inst.getCity(nextCityId);
					let road = from.getRoad(to);
					if (!road) {
						console.error(`ERROR! there is NO road between ${cityId} and ${nextCityId}`);
						break;
					}
					let dn = road.dayno;
					if (dayno <= dn) {
						this._road = road;
						this._roadDayno = dayno;
						// this._roadPath = this._road.getRestPathCoordsAfterDayno(this._roadDayno);
						this._roadPath = this._road.getPathCoordsByDayno(this._roadDayno);
						if (this._trip >= this._totalDayno) {
							// 在城池的前一个点停下
							this._roadPath = this._roadPath.slice(0, this._roadPath.length - 1);
						}
						break;
					} else {
						dayno -= dn;
					}
				}
			}
		}

		private _marchLog() {
			// console.log(`队伍[${this._teamID}]从[${CityMgr.inst.getCity(this._fromCity).cityName}]出发前往[${CityMgr.inst.getCity(this._toCity).cityName}], 总距离${this._totalDayno},现在走了${this._trip}`);
		}

		// public async run() {
		// 	this._updateCurrentRoad();
		// 	await this.forwardDayno();
		// }

		private async _run() {
			while (this._trip < this._totalDayno && !this._destroyed) {
				if (this._char) {
					await this._char.moveAlongPath(this._roadPath);
					this._marchLog();
					this._updateCurrentRoad();
					this._char.updateCharType(Char.roadType2CharType(this._road.roadType));
					let countryId = this._countryID;
					let country = CountryMgr.inst.getCountry(countryId);
					if (country) {
						this._char.updateCountry(country);
					}
				} else {
					break;
				}
			}
		}

		public async resumeRun(b: boolean) {
			if (!this._char) {
				return;
			}
			if (b) {
				if (!this._char.isMoving) {
					let path = this._roadPath;
					// 总长度
					let totalLen = 0;
					for (let i = 1; i < path.length; i ++) {
						let p = path[i];
						let prevP = path[i - 1];
						totalLen += Math.sqrt(Math.pow(p.x - prevP.x, 2) + Math.pow(p.y - prevP.y, 2));
					}
					let time = Data.parameter.get("march_speed").para_value[0] * 1000;
					let speed = (totalLen - 30 / this._totalDayno) / time; //配置表行军速度*1000毫秒
					// speed = speed - 30 / totalLen / time; // 比服务器走的稍微慢点
					// speed = speed * (1 - (3 / this._totalDayno));
					this._char.speed = speed;
					this._run();
				} else {
					this._char.resume();
				}
			} else {
				this._char.pause();
			}
		}

		// public get trip(): number {
		// 	return this._trip;
		// }

		// public set trip(trip: number) {
		// 	this._trip = trip;
		// 	this._updateCurrentRoad();
		// }

        // public async forwardDayno(set?: number) {
		// 	if (set) {
		// 		this.trip = set;
		// 	} else {
		// 		this.trip = this.trip + 1;
		// 	}
		// 	if (this._char) {
		// 		let path = this._roadPath;
		// 		// 总长度
		// 		let totalLen = 0;
		// 		for (let i = 0; i < path.length; i ++) {
		// 			if (i > 0) {
		// 				let p = path[i];
		// 				let prevP = path[i - 1];
		// 				totalLen += Math.sqrt(Math.pow(p.x - prevP.x, 2) + Math.pow(p.y - prevP.y, 2));
		// 			}
		// 		}
        //         let speed = totalLen / (Data.parameter.get("march_speed").para_value[0] * 1000); //配置表行军速度*1000毫秒
		// 		this._char.speed = speed;
		// 		await this._char.moveAlongPath(this._roadPath);
		// 	}
		// }

		public genCharCom() {
			if (!this._char) {
				console.log("genCharCom for team ", this._teamID);
				let road = this._road;
				if (road) {
					let charType = Char.roadType2CharType(road.roadType);
					this._char = new Char(WarMgr.inst.warView.map, charType);
					let countryId = this._countryID;
					let country = CountryMgr.inst.getCountry(countryId);
					if (country) {
						this._char.updateCountry(country);
					}
					this._setCharPos();
					// 初始化方向
					if (this._roadPath && this._roadPath.length > 1) {
						let from = {x: this._char.x, y: this._char.y};
						let to = {x: this._roadPath[1].x, y: this._roadPath[1].y};
						this._char.dir = this._char.calcDir(from, to);
					} else {
						if (this._cityPath && this._cityPath.length > 0) {
							let toCityId = this._cityPath[this._cityPath.length - 1];
							let toCity = CityMgr.inst.getCity(toCityId);
							if (toCity) {
								let from = {x: this._char.x, y: this._char.y};
								let to = {x: toCity.cityPoint.x, y: toCity.cityPoint.y};
								this._char.dir = this._char.calcDir(from, to);
							}
						}
					}
					this.updateCharAmount();
					if (this.isMyTeam()) {
						this.showMyHead(true);
					} else {
						this.showMyHead(false);
					}
				}
			}
		}

		public updateCharAmount() {
			if (!this._char) {
				return;
			}
			//if (!this.isMyTeam()) {
			this._char.updateAmount(this._amount);
			//} else {
			//	this._char.updateAmount(0);
			//}
		}

		public showMyHead(b: boolean) {
			if (this._char) {
				this._char.showMyHead(b);
				let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
				if (city) {
					city.setHead(!b);
				}
			}
		}

		public destroyCharCom() {
			if (this._char) {
				this._char.onDestroy();
				this._char.removeFromParent();
				this._char = null;
			}
		}

		private _setCharPos() {
			if (this._road && this._char) {
				let point = this._roadPath[0]; //this._road.getPathPointByDayno(this._roadDayno);
				this._char.x = point.x;
				this._char.y = point.y;
			}
		}

        public get teamID(): number {
            return this._teamID;
        }
		
		public get char(): Char {
			return this._char;
		}
		public get toCityID(): number {
			return this._toCity;
		}

		public destroyed(): boolean {
			return this._destroyed;
		}

		public onDestroy() {
			if (!this._destroyed) {
				this.destroyCharCom();
				this._cityPath = [];
				this._roadPath = [];
				this.resetToNoneStatus();
				this._destroyed = true;
				console.log("team.onDestroy ", this._teamID);
				if (this.isMyTeam) {
					let city = CityMgr.inst.getCity(MyWarPlayer.inst.locationCityID);
					if (city) {
						city.setHead(true);
					}
				}
			}
		}

		public static showTeamDisappearTipsByPayload(payload: any, moveMapToCity: boolean = false) {
			let data = pb.MyTeamDisappear.decode(payload);
			this.showTeamDisappearTips(data, moveMapToCity);
		}

		public static showTeamDisappearTips(data: pb.IMyTeamDisappear, moveMapToCity: boolean = false) {
            let cityData = data.Arg;
            let city: City = null;
            if (cityData) {
                let targetCity = pb.TargetCity.decode(cityData);
                city = CityMgr.inst.getCity(targetCity.CityID);
            }
            switch (data.Reason) {
                case <number>pb.MyTeamDisappear.ReasonEnum.CityBeOccupy:
                    if (city) {
						Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70342), city.cityName));
                    }
                    break;
                case <number>pb.MyTeamDisappear.ReasonEnum.OccupyCity:
                    if (city) {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70343), city.cityName));
						if (moveMapToCity) {
							WarMgr.inst.warView.map.moveCenter(city);
						}
                    }
                    break;
                case <number>pb.MyTeamDisappear.ReasonEnum.EnterCity:
                    if (city) {
                        Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format(Core.StringUtils.TEXT(70344), city.cityName));
						if (moveMapToCity) {
							WarMgr.inst.warView.map.moveCenter(city);
						}
                    }
                    break;
                case <number>pb.MyTeamDisappear.ReasonEnum.NoForage:
                    // Core.TipsUtils.showTipsFromCenter("粮草已耗尽");
                    break;
                case <number>pb.MyTeamDisappear.ReasonEnum.CountryDestory:
                    Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(70345));
                    break;
                default:
                    break;
            }
		}
    }
}