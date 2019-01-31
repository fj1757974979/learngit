module Campign {
    export enum CampaignType {

    }
}

module TD {

    export function initNativeTD() {
        let nativeApi = {
            Account: function(param) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ACCOUNT, param);
            },
            /*
            onPageLeave: function() {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONPAGELEAVE);
            },*/
            onMissionBegin: function(mission) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONMISSIONBEGIN, {
                    mission:mission
                });
            },
            onMissionCompleted: function(mission) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONMISSIONCOMPLETED, {
                    mission:mission
                });
            },
            onMissionFailed: function(mission,reason) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONMISSIONFAILED, {
                    mission:mission,
                    reason:reason
                });
            }, 
            onItemPurchase: function(param) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONITEMPURCHASE, param);
            },
            onItemUse: function(param) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONITEMUSE, param);
            },
            onEvent: function(name, data) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_ONEVENT, {
                    name:name,
                    data:data
                });
            },
            setLevel: function(level) {
                Core.NativeMsgCenter.inst.callNative(Core.NativeMessage.TD_SETLEVEL, {
                    level:level
                });
            },
            onPageLeave: function() {
                
            }
        }

        window["TDGA"] = nativeApi;
    }

    export function Account() {
        if (!window["TDGA"]) {
            return;
        }
        if (!Player.inst.uid) {
            return;
        }

        // console.log(`tdChannel=${window.gameGlobal.tdChannel}`);
        window["TDGA"].Account({
            accountId :  (window.gameGlobal.tdChannel || window.gameGlobal.channel) + "_" + Player.inst.uid.toString(),
            gameServer : Player.inst.serverID,
            accountType : 1,
            accountName : Player.inst.name,
            level: Pvp.PvpMgr.inst.getPvpLevel(),
            loginChannel: GameAccount.inst.loginChannel
        });
    }

    export function onPageLeave() {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onPageLeave();
    }

    export function onLevelBegin(levelID:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionBegin("1-" + levelID);
    }

    export function onLevelCompleted(levelID:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionCompleted("1-" + levelID);
    }

    export function onLevelFailed(levelID:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionFailed("1-" + levelID, "");
    }

    export function onCampaignBegin(type:Campign.CampaignType, level:number, fieldCnt:number) {
        if (!window["TDGA"]) {
            return;
        }
        let strField = "";
        if (fieldCnt >= 0) {
            strField = fieldCnt.toString();
        }
        window['TDGA'].onMissionBegin(`2-${type}-${level}-${strField}`);
    }

    export function onCampaignCompleted(type:Campign.CampaignType, level:number, fieldCnt:number) {
        if (!window["TDGA"]) {
            return;
        }
        let strField = "";
        if (fieldCnt >= 0) {
            strField = fieldCnt.toString();
        }
        window['TDGA'].onMissionCompleted(`2-${type}-${level}-${strField}`);
    }

    export function onCampaignFailed(type:Campign.CampaignType, level:number, fieldCnt:number) {
        if (!window["TDGA"]) {
            return;
        }
        let strField = "";
        if (fieldCnt >= 0) {
            strField = fieldCnt.toString();
        }
        window['TDGA'].onMissionFailed(`2-${type}-${level}-${strField}`, "");
    }

    export function onCampaignDefBegin(type:Campign.CampaignType, level:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionBegin(`3-${type}-${level}`);
    }

    export function onCampaignDefCompleted(type:Campign.CampaignType, level:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionCompleted(`3-${type}-${level}`);
    }

    export function onCampaignDefFailed(type:Campign.CampaignType, level:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionFailed(`3-${type}-${level}`, "");
    }

    export function onResAdd(resType:ResType, amount:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onItemPurchase({
            item : resType.toString(),
            itemNumber : amount,
            priceInVirtualCurrency: 0
        });
    }

    export function onResSub(resType:ResType, amount:number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onItemUse({
            item : resType.toString(),
            itemNumber : amount
        });
    }

    function getPvpEventData(battle:Battle.Battle): any {
        let ownFighter = battle.getOwnFighter();
        let campKey = `camp${ownFighter.camp}`;
        let eventData = {
            "uid": ownFighter.uid.toString(),
            "name": ownFighter.name,
        };
        eventData[campKey] = 1;

        for (let card of ownFighter.initHandCard) {
            if (card) {
                let name = card.name;
                if (name.slice(0, 2) == "#c") {
                    name = name.slice(3, name.length - 2);
                }
                eventData[name + "_" + card.cardId] = 1;
            }
        }
        return eventData;
    }

    export function onPvpBegin(battle:Battle.Battle) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionBegin("4");
        window['TDGA'].onEvent("pvpBegin", getPvpEventData(battle));
    }

    export function onPvpCompleted(battle:Battle.Battle) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionCompleted("4");

        let eventData = getPvpEventData(battle);
        if (battle.isFirstHand) {
            eventData["firstWin"] = 1;
        }
        window['TDGA'].onEvent("pvpWin", eventData);
    }

    export function onPvpFailed(battle:Battle.Battle) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionFailed("4", "");
        window['TDGA'].onEvent("pvpLose", getPvpEventData(battle));
    }

    function onPvpLevelChange() {
        if (!window["TDGA"] || !window["TDGA"]["Account"]) {
            return;
        }
        if (window["TDGA"]["Account"].setLevel) {
            window["TDGA"]["Account"].setLevel(Pvp.PvpMgr.inst.getPvpLevel());
        } else if (window["TDGA"].setLevel) {
            window["TDGA"].setLevel(Pvp.PvpMgr.inst.getPvpLevel());
        }
    }

    export function onGuideBegin(guideId: number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionBegin(`guide-${guideId}`);
    }

    export function onGuideFinish(guideId: number) {
        if (!window["TDGA"]) {
            return;
        }
        window['TDGA'].onMissionCompleted(`guide-${guideId}`);
    }

    export function init() {
        Core.EventCenter.inst.addEventListener(GameEvent.PvpLevelChangeEv, onPvpLevelChange, null);
    }

}
