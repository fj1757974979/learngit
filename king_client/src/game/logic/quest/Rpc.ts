module Quest {

    async function rpc_UpdateTreasure(_:Net.RemoteProxy, payload:Uint8Array) {
        let treasure = pb.MissionTreasure.decode(payload);
        QuestMgr.inst.setTreasureData(treasure);
        QuestMgr.inst.updateQuestBtn();
        if(Core.ViewManager.inst.isShow(ViewName.questView)) {
            QuestMgr.inst.updateTreasure();
        }        
    }
    async function rpc_ShowRedDot(_:Net.RemoteProxy, payload:Uint8Array) {
        QuestMgr.inst.showRedDot();
    }
    async function rpc_UpdateQuestList(_:Net.RemoteProxy, payload:Uint8Array) {
        let reply = pb.MissionInfo.decode(payload);
        QuestMgr.inst.setQuestList(reply);
        QuestMgr.inst.updateQuestBtn();
        if (Core.ViewManager.inst.isShow(ViewName.questView)) {
            QuestMgr.inst.updateView();
        }
    }
    async function rpc_UpdateQuest(_:Net.RemoteProxy, payload:Uint8Array) {
        let reply = pb.UpdateMissionProcessArg.decode(payload);
        reply.Missions.forEach(_miss => {
            let questData = new QuestData(_miss);
            QuestMgr.inst.setQuest(questData);
        })
    }

    export function initRpc() {
        // Net.registerRpcHandler(pb.MessageID.C2S_OPEN_MISSION_TREASURE,rpc_OpenTreasure);
        Net.registerRpcHandler(pb.MessageID.S2C_MISSION_SHOW_RED_DOT,rpc_ShowRedDot);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MISSION_INFO,rpc_UpdateQuestList);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MISSION_PROCESS,rpc_UpdateQuest);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MISSION_TREASURE_PROCESS,rpc_UpdateTreasure);
        
    }
}