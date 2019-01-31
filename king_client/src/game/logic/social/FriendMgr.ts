module Social {

	let _APPLY_NUM_KEY = "apl";

	export class FriendMgr {

		private static _inst: FriendMgr = null;
		private _friends: Array<Friend>;
		private _applyNum: number;

		public static get inst(): FriendMgr {
			if (!FriendMgr._inst) {
				FriendMgr._inst = new FriendMgr();
			}
			return FriendMgr._inst;
		}

		public constructor() {
			Core.EventCenter.inst.addEventListener(GameEvent.InviteBattleResEv, this._onInviteResult, this);
			this._friends = null;
			this._applyNum = 0;
		}

		public get friends():Array<Friend> {
			return this._friends;
		}

		public get applyNum(): number {
			return this._applyNum;
		}

		public set applyNum(num: number) {
			this._applyNum = num;
			Core.EventCenter.inst.dispatchEventWith(GameEvent.ApplyFriendHintEv);
		}

		public async fetchFriendList(): Promise<{lastOpp: Friend, friends: Array<Friend>}> {
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_FRIEND_LIST, null);
			if (result.errcode == 0) {
				let reply = pb.FriendList.decode(result.payload);
				let lastOpp = null;
				if (reply.LastOpponent) {
					lastOpp = new Friend(<pb.FriendItem>(reply.LastOpponent));
				}
				let friends: Array<Friend> = [];
				// console.debug(JSON.stringify(reply.Friends));
				reply.Friends.forEach(data => {
					friends.push(new Friend(<pb.FriendItem>data));
				});
				friends.sort((f1: Friend, f2: Friend): number => {
					if (f1.isOnline && !f2.isOnline) {
						return -1;
					} else if (!f1.isOnline && f2.isOnline) {
						return 1;
					} else {
						if (f1.rebornCnt > f2.rebornCnt) {
							return -1;
						} else if (f1.rebornCnt < f2.rebornCnt) {
							return 1;
						} else {
							if (f1.score > f2.score) {
								return -1;
							} else {
								return 1;
							}
						}
					}
				});
				this._friends = friends;
				return {
					lastOpp: lastOpp,
					friends: friends,
				}
			} else {
				this._friends = null;
				return null;
			}
		}

		public async fetchPlayerInfo(uid: Long): Promise<pb.PlayerInfo> {
			let args = {Uid: uid};
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_PLAYER_INFO, pb.TargetPlayer.encode(args));
			if (result.errcode == 0) {
				let reply = pb.PlayerInfo.decode(result.payload)
				return reply;
			} else {
				return null;
			}
		}

		public async applyAddFriend(uid: Long): Promise<boolean> {
			let args = {Uid: uid};
			let result = await Net.rpcCall(pb.MessageID.C2S_ADD_FRIEND_APPLY, pb.TargetPlayer.encode(args));
			return result.errcode == 0;
		}

		public async fetchAddFriendApplies(silent: boolean = false): Promise<pb.FriendApplyList> {
			let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_FRIEND_APPLY_LIST, null, !silent);
			if (result.errcode == 0) {
				let ret = pb.FriendApplyList.decode(result.payload);
				this.applyNum = ret.FriendApplys.length;
				return ret;
			} else {
				Core.TipsUtils.alert("fetch add friend applies error");
				return null;
			}
		}

		public async replyAddFriendApply(uid: Long, agree: boolean): Promise<boolean> {
			let args = {Uid: uid, IsAgree: agree};
			let result = await Net.rpcCall(pb.MessageID.C2S_REPLY_AFRIEND_APPLY, pb.ReplyFriendApplyArg.encode(args));
			return result.errcode == 0;
		}

		public async delFriend(uid: Long): Promise<boolean> {
			let args = {Uid: uid};
			let result = await Net.rpcCall(pb.MessageID.C2S_DEL_FRIEND, pb.TargetPlayer.encode(args));
			return result.errcode == 0;
		}

		public async inviteBattle(uid: Long): Promise<boolean> {
			let args = {Uid: uid};
			let result = await Net.rpcCall(pb.MessageID.C2S_INVITE_BATTLE, pb.TargetPlayer.encode(args));
			return result.errcode == 0;
		}

		public async cancelInviteBattle(): Promise<boolean> {
			let result = await Net.rpcCall(pb.MessageID.C2S_CANCEL_INVITE_BATTLE, null);
			return result.errcode == 0;
		}

		private async _onInviteResult(evt: egret.Event) {
			let result = <number>evt.data;
			let view = <InviteWaitingWnd>(Core.ViewManager.inst.getView(ViewName.inviteWaiting));
			if (result == pb.InviteBattleResult.InviteResult.Agree) {
				if (view) {
					await view.readyFight();
				}
			} else if (result == pb.InviteBattleResult.InviteResult.Refuse) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60177));
				if (view) {
					await view.cancelFight();
				}
			} else if (result == pb.InviteBattleResult.InviteResult.Timeout) {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60228));
				if (view) {
					await view.cancelFight();
				}
			} else {
				Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60077));
				if (view) {
					await view.cancelFight();
				}
			}
		}
	}
}
