// TypeScript file
module Huodong {

    function rpc_HuodongBegin(_:Net.RemoteProxy, payload: Uint8Array) {
        let data = pb.HuodongData.decode(payload);
        HuodongMgr.inst.onHuodongBegin(data);
    }

    function rpc_HuodongEnd(_:Net.RemoteProxy, payload: Uint8Array) {
        let data = pb.TargetHuodong.decode(payload);
        HuodongMgr.inst.onHuodongEnd(<number>data.Type);
    }

    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_HUODONG_BEGIN, rpc_HuodongBegin);
        Net.registerRpcHandler(pb.MessageID.S2C_HUODONG_END, rpc_HuodongEnd);
    }
}
