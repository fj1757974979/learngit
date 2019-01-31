module Net {

    let rpcHandlersMap = new Collection.Dictionary<number, RpcHandler>();
    let rpcPending = new Collection.Dictionary<number, RpcCaller>();
    let maxSeq = 0;

    class RpcHandler {
        private msgId:number
        private f:Function;

        constructor(msgId:number, f:Function) {
            this.msgId = msgId;
            this.f = f;
        }

        public handle(identity:number, payload:Uint8Array): void {
            this.f(new RemoteProxy(identity), payload);
        }
    }

    class RpcCaller {
        private seq:number;
        private callback:Function;
        constructor(seq:number, callback:Function) {
            this.seq = seq;
            this.callback = callback;
        }

        public done(errcode:number, payload:Uint8Array): void {
            this.callback(new RpcResult(errcode, payload));
        }
    }

    export class RemoteProxy {
        private seq:number;

        constructor(seq:number) {
            this.seq = seq;
        }

        public response(payload:protobuf.Writer): void {
            let pkt = new Packet();
            pkt.msgType = MessageType.MsgReply;
            pkt.seq = this.seq;
            if (payload != null) {
                pkt.payload = new egret.ByteArray(payload.finish());
            }
            
            SConn.inst.writePacket(pkt);
        }

        public errResponse(errcode:number): void {
            let pkt = new Packet();
            pkt.msgType = MessageType.MsgErr;
            pkt.seq = this.seq;
            pkt.errcode = errcode;
            SConn.inst.writePacket(pkt);
        }

        public okResponse(): void {
            this.errResponse(0);
        }
    }

    export class RpcResult {
        private _errcode:number;
        private _payload:Uint8Array;

        get errcode() {
            return this._errcode;
        }
        get payload() {
            return this._payload;
        }

        constructor(errcode:number, payload:any) {
            this._errcode = errcode;
            this._payload = payload;
        }
    }

    function handleRequest(msgId:number, seq:number, payload:Uint8Array) {
        let handler = rpcHandlersMap.getValue(msgId);
        if (handler == null) {
            console.debug("handleRequest no handler, msgId=%d", msgId);
            return;
        }

        handler.handle(seq, payload);
    }

    function handleResponse(errcode:number, seq:number, payload:Uint8Array) {
        if (errcode != 0) {
            console.debug("errcode = " + errcode);
        }

        let caller = rpcPending.remove(seq);
        if (caller == null) {
            console.debug("late response " + seq);
            return
        }

        caller.done(errcode, payload);
    }

    export function onSocketData(pkt:Packet) {
        console.debug(Core.StringUtils.format("onSocketData msgType={0}, msgID={1}, seq={2}, errcode={3}", pkt.msgType, pkt.msgID, pkt.seq, pkt.errcode));
        
        let uint8Payload: Uint8Array;
        if (pkt.payload) {
            uint8Payload = pkt.payload.bytes;
        } else {
            uint8Payload = new Uint8Array(0);
        }
        if (pkt.msgType == MessageType.MsgReq || pkt.msgType == MessageType.MsgPush) {
            handleRequest(pkt.msgID, pkt.seq, uint8Payload);
        } else {
            handleResponse(pkt.errcode, pkt.seq, uint8Payload);
        }
    }

    export function registerRpcHandler(msgId:number, f:Function) {
        rpcHandlersMap.setValue(msgId, new RpcHandler(msgId, f));
    }

    export function rpcCall(msgId:number, arg:protobuf.Writer, needMask:boolean=true, needErrTips:boolean=true): Promise<RpcResult> {
        if (needMask) {
            Core.MaskUtils.showNetMask();
        }

        maxSeq += 1;
        let pkt = new Packet();
        pkt.seq = maxSeq;
        pkt.msgID = msgId;
        pkt.msgType = MessageType.MsgReq;

        console.debug(Core.StringUtils.format("rpcCall msgId = {0} seq = {1}", pkt.msgID, pkt.seq));
        
        if (arg != null) {
            pkt.payload = new egret.ByteArray(arg.finish());
        }
        return new Promise<RpcResult>(resolve => {
            let caller = new RpcCaller(pkt.seq, result => {
                if (needMask) {
                    Core.MaskUtils.hideNetMask();
                }
                if (result.errcode != 0 && window.gameGlobal.debug && needErrTips) {
                    Core.TipsUtils.showTipsFromCenter(`#cr${msgId} code ${result.errcode}#n`);
                }
                resolve(result);
            });
            rpcPending.setValue(pkt.seq, caller);
            SConn.inst.writePacket(pkt);
        })
    }

    export function rpcPush(msgId:number, arg:protobuf.Writer): void {
        let pkt = new Packet();
        pkt.msgID = msgId;
        pkt.msgType = MessageType.MsgPush;
        if (arg != null) {
            pkt.payload = new egret.ByteArray(arg.finish());
        }
        SConn.inst.writePacket(pkt);
    }
    
}