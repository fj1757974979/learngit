module CardPool {

    function rpc_SyncCardInfo(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.CardDatas.decode(payload);
        CardPoolMgr.inst.updateCollectCards(arg.Cards);
        Diy.DiyMgr.inst.updateDiyCards(arg.DiyCards);
    }

    function rpc_AddCardSkin(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.AddCardSkinArg.decode(payload);
        CardSkinMgr.inst.addMySkin(arg.Skin);
    }
    function rpc_AddEquip(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.TargetEquip.decode(payload);
        Equip.EquipMgr.inst.addEquip(arg.EquipID);
    }
    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_SYNC_CARD_INFO, rpc_SyncCardInfo);
        Net.registerRpcHandler(pb.MessageID.S2C_ADD_CARD_SKIN, rpc_AddCardSkin);
        Net.registerRpcHandler(pb.MessageID.S2C_ADD_EQUIP, rpc_AddEquip);
    }

}