module Net {

    export enum MessageType {
        MsgReq = 1,
        MsgReply,
        MsgPush, // no reply
        MsgErr,  // error reply
        MsgPing,
        MsgPong,
    }

    export class Packet {
        public msgID: number;
        public msgType: MessageType;
        public seq: number;
	    public errcode: number;
	    public payload: egret.ByteArray;

        constructor() {
            this.msgID = 0;
            this.msgType = 0;
            this.seq = 0;
            this.errcode = 0;
        }
    }
}