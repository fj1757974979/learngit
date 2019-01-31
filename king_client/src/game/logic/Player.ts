
class Player extends egret.EventDispatcher {
    private static _inst: Player;

    public static ResUpdateEvt = "ResUpdateEvt";
    public static PvpScoreChangeEvt = "PvpScoreChangeEvt";
    public static PvpMaxScoreChangeEvt = "PvpMaxScoreChangeEvt";
    public static LoginEvt = "LoginEvt";
    public static LogoutEvt = "LogoutEvt";

    private _uid: Long;
    private _resources: Collection.Dictionary<ResType, number>;
    private _name: string;
    private _serverID: string;
    private _avatarUrl: string;
    private _frameID: string;
    private _guideCamp: Camp;
    private _accountType: number;
    private _cumulativePay: number;
    private _isIOSShared: boolean;
    // private _isVip: boolean;
    private _vipTime: number;
    private _miniVipTime: number;
    private _hasGetVipExperience: boolean = false;
    private _skins: Collection.Dictionary<string, string>;
    private _privileges: Array<number>;
    // private _isSeasonPvpChooseCard: boolean;
    private _winDiff: number;
    private _rebornCnt: number;

    private _oldFlag: number;
    private _isOldAccount: boolean = false;

    constructor() {
        super();
        this._resources = new Collection.Dictionary<ResType, number>();
        this._skins = new Collection.Dictionary<string, string>();
        Core.EventCenter.inst.addEventListener(GameEvent.ModifyNameEv, (evt:egret.Event)=>{
            this._name = evt.data;
        }, this);
        this._vipTime = 0;
        this._miniVipTime = 0;
    }

    public static get inst(): Player {
        if (!Player._inst) {
            Player._inst = new Player();
        }
        return Player._inst;
    }

    public get name(): string {
        return this._name;
    }

    public set name(n: string) {
        this._name = n;
    }

    public get nameWithNoColor(): string {
        if (this._name.indexOf("#") == 0) {
            return this._name.substr(8, this._name.length - 10);
        } else {
            return this.name;
        }
    }

    public set accountType(t: number) {
        this._accountType = t;
    }


    public get avatarUrl(): string {
        // if (!this._avatarUrl || this._avatarUrl == "") {
        //     return "society_headicon1_png";
        // }
        return this._avatarUrl;
    }

    public set avatarUrl(url: string) {
        this._avatarUrl = url;
        // if (!Core.DeviceUtils.isWXGame()) {
            Core.EventCenter.inst.dispatchEventWith(GameEvent.ModifyAvatarEv, false, url);
        // }
    }

    public saveAvatarUrl(url: string) {
        Net.rpcCall(pb.MessageID.C2S_UPDATE_HEADIMG, pb.UpdateHeadImgArg.encode({"HeadImg":url}));
        this.avatarUrl = url;
    }
    public set frameID(ID: string) {
        this._frameID = ID;
        Core.EventCenter.inst.dispatchEventWith(GameEvent.ModifyFrameEv, false, ID);
    }
    public get frameID(): string {
        if (!this._frameID || this._frameID == "") {
            this._frameID = "1";
        }
        return this._frameID;
    }
    public get frameUrl(): string {
        if (!this._frameID || this._frameID == "") {
            this._frameID = "1";
        }
        return `headframe_${this._frameID}_png`;
    }


    public async saveFrameUrl(frameID: string) {
       Net.rpcCall(pb.MessageID.C2S_UPDATE_HEAD_FRAME, pb.UpdateHeadFrameArg.encode({"HeadFrame": frameID}));
       this.frameID = frameID;
    }

    public get guideCamp(): Camp {
        return this._guideCamp;
    }
    public set guideCamp(camp:Camp) {
        this._guideCamp = camp;
    }

    public get uid(): Long {
        return this._uid;
    }

    public get serverID(): string {
        return this._serverID;
    }

    public get isIOSShared(): boolean {
        return this._isIOSShared;
    }

    public set isIOSShared(b: boolean) {
        this._isIOSShared = b;
    }


    public get privileges() {
        return this._privileges;
    }

    // public set isVip(b: boolean) {
    //     this._isVip = b;
    // }

    public get isVip(): boolean {
        // return this._isVip;
        return this._vipTime > 0 || this._vipTime == -1;
    }
    public get isMiniVip(): boolean {
        return this._miniVipTime > 0;
    }
    public set vipTime(time: number) {
        this._vipTime = time;
    }
    public get vipTime(): number {
        return this._vipTime;
    }
    public set miniVipTime(time: number) {
        this._miniVipTime = time;
    }
    public get miniVipTime(): number {
        return this._miniVipTime;
    }
    public get hasGetVipExperience(): boolean {
        return this._hasGetVipExperience;
    }
    public set hasGetVipExperience(bool: boolean) {
        this._hasGetVipExperience = bool;
    }
    public get winDiff(): number {
        return this._winDiff;
    }
    public set winDiff(diff: number) {
        this._winDiff = diff;
    }
    public get oldFlag(): number {
        return this._oldFlag;
    }
    public set oldFlag(flag: number) {
        this._oldFlag = flag;
    }
    public get rebornCnt(): number {
        return this._rebornCnt;
    }
    public set rebornCnt(r: number) {
        this._rebornCnt = r;
    }

    public async login(data:pb.LoginReply, name:string) {
        this._uid = data.Uid as Long;
        this._serverID = data.ServerID;
        this._name = data.Name;
        this._guideCamp = data.GuideCamp;
        this._avatarUrl = data.HeadImg;
        this._frameID = data.HeadFrame;
        this._cumulativePay = data.CumulativePay;
        this._isIOSShared = data.IsIosShared;
        // this._isVip = data.IsVip;
        this._vipTime = data.VipRemainTime;
        this._rebornCnt = data.RebornCnt;
        this._privileges = data.Privileges;
        this._isOldAccount = Net.SConn.inst.isConnectingOldServer();
        this.updateResource(data.Res);
        // await Equip.EquipMgr.inst.fetchEquip();

        CardPool.CardPoolMgr.inst.onLogin(data.Cards);
        CardPool.CardSkinMgr.inst.updateMySkins(data.CardSkins);
        //season
        Season.SeasonMgr.inst.updateSeasonInfo(data.SeasonPvpLimitTime, data.IsSeasonPvpChooseCard);

        Huodong.HuodongMgr.inst.initHuodong(data.Huodongs);

        //Diy.DiyMgr.inst.onLogin(data.DiyCards);
        await Level.LevelMgr.inst.fetchLevelData(false);
        // await Social.EmojiMgr.inst.initEmojis();
        //await Campign.CampignMgr.inst.fetchCampignData(false);
        this.dispatchEventWith(Player.LoginEvt);
        TD.Account();

        this._startHeartBeat();
    }

    public logout() {
        this._stopHeartBeat();
        this.dispatchEventWith(Player.LogoutEvt);
    }

    public getResource(resType:ResType): number {
        let amount = this._resources.getValue(resType);
        if (amount) {
            return amount;
        } else {
            return 0;
        }
    }

    public addResource(resType:ResType, cnt: number) {
        let old = this.getResource(resType);
        this._resources.setValue(resType, cnt + old);
    }

    public get cumulativePay(): number {
        return this._cumulativePay;
    }
    public isInGuide() {
        // console.log(this.getResource(ResType.T_GUIDE_PRO));
        return this.getResource(ResType.T_GUIDE_PRO) < Guide.MaxGuideProgress;
    }
    public hasEnoughGold(gold: number): boolean {
        return this.getResource(ResType.T_GOLD) >= gold;
    }

    public hasEnoughJade(jade: number): boolean {
        return this.getResource(ResType.T_JADE) >= jade;
    }

    public hasEnoughBowlder(bowlder: number, jadeSub: boolean = false): boolean {
        if (jadeSub) {
            return this.getResource(ResType.T_BOWLDER) + this.getResource(ResType.T_JADE) >= bowlder;
        } else {
            return this.getResource(ResType.T_BOWLDER) >= bowlder;
        }
    }

    public async askSubBowlder(bowlder: number, jadeSub: boolean = true): Promise<boolean> {
        if (this.hasEnoughBowlder(bowlder)) {
            return true;
        } else if (!jadeSub) {
            return false;
        } else {
            if (!this.hasEnoughBowlder(bowlder, true)) {
                return false;
            }
            return await new Promise<boolean>(resolve => {
                let diff = bowlder - this.getResource(ResType.T_BOWLDER);
                let msg = Core.StringUtils.format(Core.StringUtils.TEXT(60277), diff);
                Core.TipsUtils.confirm(msg, () => {
                    resolve(true);
                }, () => {
                    resolve(false);
                });
            });
        }
    }

    public hasEnoughFeat(feat: number): boolean {
        return this.getResource(ResType.T_FEAT) >= feat;
    }
    public hasEnoughFame(fame: number): boolean {
        return this.getResource(ResType.T_FAME) >= fame;
    }
    public hasEnoughEquipMoney(): boolean {
        return this.getResource(ResType.T_EQUIP) > 0;
    }

    public getSkipAdvertResType(): ResType {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            return ResType.T_BOWLDER;
        } else {
            return ResType.T_JADE;
        }
    }

    public getSkipAdvertResIcon(): string {
        return Utils.resType2Icon(this.getSkipAdvertResType());
    }

    public async askSubRes(t: ResType, cnt: number, withHint: boolean = true): Promise<boolean> {
        if (t == ResType.T_JADE) {
			if (Player.inst.hasEnoughJade(cnt)) {
				return true;
			} else {
				if (withHint) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60085));
				}
				return false;
			}
		} else {
			if (await Player.inst.askSubBowlder(cnt)) {
				return true;
			} else {
				if (withHint) {
					Core.TipsUtils.showTipsFromCenter(Core.StringUtils.TEXT(60278));
				}
			}
		}
    }

    public hasEnoughResToSkipAdvert(): boolean {
        if (this.isVip) {
            return true;
        }
        let resType: ResType = null;
        if (window.gameGlobal.channel == "lzd_handjoy") {
            return this.hasEnoughBowlder(3, true);
        } else {
            return this.hasEnoughJade(3);
        }
    }

    public async askSubSkipAdvertRes(withHint: boolean = true) {
        let resType = this.getSkipAdvertResType();
        return await this.askSubRes(resType, 3, withHint);
    }

    public addPrivilege(priv: number) {
        if (!this.hasPrivilege(priv)) {
            this._privileges.push(priv);
        }
    }

    public hasPrivilege(priv: number): boolean {
        return this._privileges.indexOf(priv) != -1;
    }

    /**
     * @param modify [{Type:resType, Amount:amount}, ...]
     */
    public updateResource(modify:Array<any>, needReport:boolean=false) {
        if (modify && modify.length > 0) {
            modify.forEach(info => {
                if (needReport) {
                    let old = this._resources.getValue(info.Type);
                    old = old ? old : 0;
                    let modify = info.Amount - old;
                    if (modify > 0) {
                        TD.onResAdd(info.Type, modify);
                    } else if (modify < 0) {
                        TD.onResSub(info.Type, - modify);
                    }
                }
                if (info.Type == ResType.SeasonWinDiff) {
                    let old = this._resources.getValue(info.Type);
                    if (old != null) {
                        this._oldFlag = old;
                    }
                }
                this._resources.setValue(info.Type, info.Amount);
                if (info.Type == ResType.T_SCORE) {
                    this.dispatchEventWith(Player.PvpScoreChangeEvt);
                    if (this._accountType == pb.AccountTypeEnum.Ios) {
                        this._scoreToGameCenter();
                    }
                } else if (info.Type == ResType.T_MAX_SCORE) {
                    this.dispatchEventWith(Player.PvpMaxScoreChangeEvt);
                }
            })
            this.dispatchEventWith(Player.ResUpdateEvt);
        }
    }

    public static getNewbieNamePrefix(): string {
        if (window.gameGlobal.isMultiLan) {
            return "guest";
        } else {
            return "新兵";
        }
    }

    public async getVipTime() {
            let result = await Net.rpcCall(pb.MessageID.C2S_FETCH_VIP_REMAIN_TIME, null);
            if (result.errcode == 0) {
                let reply = pb.VipRemainTime.decode(result.payload);
                this.vipTime = reply.RemainTime;
            }
            return this._vipTime;
    }

    public isNewbieName(name:string): boolean {
        //return name.slice(0, 2) == Core.StringUtils.TEXT(60036);
        return name.indexOf(Player.getNewbieNamePrefix()) == 0;
    }

    public exchangeRes(resType:ResType, amount:number) {
        Net.rpcPush(pb.MessageID.C2S_EXCHANGE_RESOURCE, pb.Resource.encode({"Type":resType, "Amount":amount}));
    }

    private _scoreToGameCenter() {
        if (this._accountType == pb.AccountTypeEnum.Ios) {
            Core.NativeMsgCenter.inst.callNative(
                Core.NativeMessage.SCORE_TO_GAME_CENTER,
                {score:this.getResource(ResType.T_SCORE)}
            );
        }
    }

    public getAdvertCnt() {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            if (!this.isVip) {
                return 0;
            }
        }
        if (this.isNewVersionPlayer()) {
            return this.getResource(ResType.T_ACC_TREASURE_CNT) - 10;
        }
        if (Core.DeviceUtils.isWXGame()) {
            return this.getResource(ResType.T_ACC_TREASURE_CNT) - 10;
        } else {
            return this.getResource(ResType.T_ACC_TREASURE_CNT);
        }
    }

    public getAccTreasureCnt(): number {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            if (!this.isVip) {
                return 0;
            }
        }
        if (this.isNewVersionPlayer()) {
            return this.getResource(ResType.T_ACC_TREASURE_CNT) - 10;
        }
        return this.getResource(ResType.T_ACC_TREASURE_CNT);
    }

    public getMaxAccTreasureCnt(): number {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            return 20;
        } else {
            if (this.isNewVersionPlayer()) {
                return 10;
            } else {
                return 20;
            }
        }
    }

    public canSkipAdvertForTreasure(): boolean {
        if (window.gameGlobal.channel == "lzd_handjoy") {
            return false;
        } else {
            if (this.isNewVersionPlayer()) {
                return false;
            } else {
                // return this.isVip;
                return true;
                // if (Core.DeviceUtils.isWXGame()) {
                //     return true;
                // } else {
                //     return this.isVip;
                // }
            }
        }
    }

    public isNewVersionPlayer(): boolean {
        return !this._isOldAccount;
    }

    public setOldVersionPlayer() {
        this._isOldAccount = true;
    }

    private _stopHeartBeat() {
        fairygui.GTimers.inst.remove(this._heartBeat, this);
    }

    private _startHeartBeat() {
        fairygui.GTimers.inst.add(1000, -1, this._heartBeat, this);
    }

    private _heartBeat() {
        // console.log("Player heartBeat");
        if (this._vipTime > 0) {
            this._vipTime = Math.max(0, this._vipTime - 1);
        }
        if (this._miniVipTime > 0) {
            this._miniVipTime = Math.max(0, this._miniVipTime - 1);
        }
        Huodong.HuodongMgr.inst.heartbeat();
    }
}
