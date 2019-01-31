// TypeScript file
module Treasure {

    function rpc_GainTreasure(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.GainTreasure.decode(payload);
        TreasureMgr.inst().addTreasureWithData(arg.Treasure);
    }

    function rpc_UpdateDailyTreasure(_:Net.RemoteProxy, payload:Uint8Array) {
        let arg = pb.DailyTreasure.decode(payload);
        TreasureMgr.inst().updateDailyTreasureWithData(arg);
    }

    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_GAIN_TREASURE, rpc_GainTreasure);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_DAILY_TREASURE, rpc_UpdateDailyTreasure);
    }
}