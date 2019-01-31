module Net {

    export enum NetPacketConsts {
        _RECV_PAYLOAD_LENGTH = 1,
        _RECV_PAYLOAD = 2,

        SeqSize     = 4,
        MsgIDSize   = 4,
        MsgTypeSize = 1,
        ErrcodeSize = 4,
        PktSizeSize = 4,
    }

    class RereadData {
        public data: egret.ByteArray;
        public next: RereadData;

        constructor(data:egret.ByteArray, next:RereadData) {
            this.data = data;
            this.next = next;
        }
    }

    class Rereader {
        private _head: RereadData;
        private _tail: RereadData;
        public count: number;

        constructor() {
            this.count = 0;
            this._head = null;
            this._tail = null;
        }

        public pull(buf:egret.ByteArray):number {
            let n = 0;
            if (this._head) {
                let b = this._head.data;
                n += b.readAvailable;
                b.readBytes(buf, buf.readAvailable);
                this._head = this._head.next
                if (this._head == null) {
                    this._tail = null
                }
                this.count -= n
            }
            return n;
        }

        public async reread(socket: WebSocket, n: number) {
            let buf = new egret.ByteArray();
            await socket.readFull(buf, n);
            let data = new RereadData(buf, null);
            if (!this._head) {
                this._head = data
            } else {
                this._tail.next = data
            }
            this._tail = data
            this.count += buf.readAvailable;
        }
    }

    class Rewriter {
        private _data: egret.ByteArray;
        private _head: number;
        private _length: number;

        constructor() {
            this._data = new egret.ByteArray(new ArrayBuffer(100 * 1024));
            this._head = 0;
            this._length = 0;
        }

        public get length(): number {
            return this._length;
        }

        public push(b: egret.ByteArray) {
            if (b.readAvailable >= this._data.buffer.byteLength) {
                b.position = b.readAvailable - this._data.buffer.byteLength;
                b.readBytes(this._data, 0, this._data.buffer.byteLength);
                this._head = 0;
                this._length = this._data.buffer.byteLength;
                return;
            }

            let size = this._data.buffer.byteLength - this._head;
            size = size > b.readAvailable ? b.readAvailable : size;
            b.readBytes(this._data, this._head, size);

            if (b.readAvailable == 0) {
                this._head += size;
                if (this._head == this._data.buffer.byteLength) {
                    this._head = 0;
                }

                if (this._length != this._data.buffer.byteLength) {
                    this._length += size;
                }
            } else {
                this._head = b.readAvailable;
                b.readBytes(this._data, 0);
                if (this._length != this._data.buffer.byteLength) {
                    this._length = this._data.buffer.byteLength;
                }
            }
        }

        public rewrite(socket: WebSocket, writeCount:number, readCount:number):boolean {
            let n = writeCount - readCount;
            if (n == 0) {
                return true;
            } else if (n < 0 || n > this._length) {
                return false;
            } else if (n <= this._head) {
                socket.writeBytes(new egret.ByteArray(this._data.buffer.slice(this._head-n, this._head)));
                return true;
            }

            let offset = this._head - n + this._data.buffer.byteLength;
            socket.writeBytes(new egret.ByteArray(this._data.buffer.slice(offset)));
            socket.writeBytes(new egret.ByteArray(this._data.buffer.slice(0, this._head)));
            return true;
        }
    }

    declare interface ServerInfo {
        host: string;
        port: number;
        wssport: number;
    }

    class Serverlist {
        private _curServerIndex: number;
        private _curOldServerIndex: number;
        private _servers: Array<ServerInfo>;
        private _oldServers: Array<ServerInfo>;
        private _status: number;
        private _message: string;
    
        constructor() {
            this._curServerIndex = 0;
            this._curOldServerIndex = 0;
            this._servers = null;
            this._oldServers = null;
            this._message = "";
            this._status = 1;
        }

        private _initLists() {
            let serverlistData = RES.getRes("serverlist_json");
            if (serverlistData) {
                this._servers = serverlistData.servers;
                this._oldServers = serverlistData.oldServers;
                this._status = serverlistData.status;
                this._message = serverlistData.message;
            } else {
                this._servers = [];
                this._oldServers = [];
            }
        }

        private get list(): Array<ServerInfo> {
            if (this._servers) {
                return this._servers;
            }

            this._initLists();

            return this._servers;
        }

        private get oldList(): Array<ServerInfo> {
            if (this._oldServers) {
                return this._oldServers;
            }

            this._initLists();

            return this._oldServers;
        }

        public isMaintain(): [boolean, string] {
            let l = this.list;
            let maintain = !l || l.length == 0 || this._status != 0;
            return [maintain, this._message];
        }

        public refresh(oldServer: boolean = false) {
            if (oldServer) {
                this._curOldServerIndex = Core.RandomUtils.randInt(this.oldList.length);
            } else {
                this._curServerIndex = Core.RandomUtils.randInt(this.list.length);        
            }
        }

        public getCurServer(oldServer: boolean = false): ServerInfo {
            if (oldServer) {
                let _list = this.oldList;
                return _list[this._curOldServerIndex % _list.length];
            } else {
                let _list = this.list;
                return _list[this._curServerIndex % _list.length];
            }
        }

        public getNextServer(oldServer: boolean = false): ServerInfo {
            if (oldServer) {
                this._curOldServerIndex ++;
                let _list = this.oldList;
                return _list[this._curOldServerIndex % _list.length];
            } else {
                this._curServerIndex++;
                let _list = this.list;
                return _list[this._curServerIndex % _list.length];
            }
        }
    }

    export class SConn {
        private static _inst: SConn;

        private _webSocket: WebSocket;
        private _host: string;
        private _port: number;
        private _wsshost: string;
        private _wssport: number;
        private _reconnectTimes: number;
        private _connID: number;
        private _readCount: number;
	    private _writeCount: number;
        private _rereader: Rereader;
        private _rewriter: Rewriter;
        private _closed: boolean;
        private _connecting: Promise<void>;
        private _recvBuf: egret.ByteArray;
        private _recvStatus: NetPacketConsts;
        private _recvPayloadLen: number;
        private _sendBuf: egret.ByteArray;
        private _serverlist: Serverlist;
        private _connectOldServer: boolean;

        constructor() {
            this._closed = true;
            this._connectOldServer = false;
            this._init();
        }

        public static get inst(): SConn {
            if (!SConn._inst) {
                SConn._inst = new SConn();
            }
            return SConn._inst;
        }

        private _init() {
            this._reconnectTimes = 0;
            this._readCount = 0;
            this._writeCount = 0;
            this._rereader = new Rereader();
            this._rewriter = new Rewriter();
            this._recvBuf = new egret.ByteArray();
            this._recvStatus = NetPacketConsts._RECV_PAYLOAD_LENGTH;
            this._recvPayloadLen = 0;
            this._sendBuf = new egret.ByteArray(new ArrayBuffer(1024*1024));
            this._sendBuf.position = NetPacketConsts.PktSizeSize;
            this._serverlist = new Serverlist();
        }

        public isMaintain(): [boolean, string] {
            return this._serverlist.isMaintain();
        }

        public setConnectOldServerFlag(b: boolean) {
            this._connectOldServer = b;
        }

        public isConnectingOldServer(): boolean {
            return this._connectOldServer;
        }

        public setAddress(host: string, port: number): void {
            if (this._host) {
                return;
            }
            this._host = host;
            this._port = port;
        }

        public setWssAddress(host: string, port: number): void {
            if (this._wsshost) {
                return;
            }
            this._wsshost = host;
            this._wssport = port;
        }

        public async connect() {
            this._serverlist.refresh(this._connectOldServer);
            while(true) {
                if (this._webSocket) {
                    this._webSocket.close();
                    this._webSocket = null;
                }

                try {
                    console.log("fuck ", this._serverlist.getNextServer(this._connectOldServer));
                    //LoadingView.inst.setText("connect dial " + this._serverlist.getNextServer());
                    await this.dial(this._serverlist.getNextServer(this._connectOldServer));
                } catch(e) {
                    console.error("connect dial ", e);
                    //LoadingView.inst.setText("connect dial " + e + this);
                    await fairygui.GTimers.inst.waitTime(700);
                    continue
                }
                
                let buf = new egret.ByteArray(new ArrayBuffer(12));
                buf.writeUnsignedInt(0);
                buf.writeUnsignedInt(0);
                buf.writeUnsignedInt(0);
                this._webSocket.writeBytes(buf);
                buf.clear();

                try {
                    await this._webSocket.readFull(buf, 4);
                } catch(e) {
                    console.error("connect read ", e);
                    continue
                }
                this._connID = buf.readUnsignedInt();
                break;
            }
        }

        public close() {
            if (this._closed) {
                return;
            }
            this._closed = true;
            if (this._webSocket) {
                this._webSocket.close();
                this._webSocket = null;
            }
            let newInst = new SConn();
            newInst.setAddress(this._host, this._port);
            SConn._inst= newInst;
        }

        public closeWebSocket() {
            if (this._webSocket) {
                this._webSocket.close();
            }
        }

        public async start() {
            if (!this._closed) {
                return;
            }
            this._closed = false;
            await this.connect();
            this.readLoop();
        }

        public async connectServer() {
            Net.SConn.inst.setAddress(window.gameGlobal.serverHost, window.gameGlobal.serverPort);
            // Net.SConn.inst.setAddress("192.168.1.168", 9100);
            Net.SConn.inst.setWssAddress(window.gameGlobal.serverHost, window.gameGlobal.serverWssPort);
            // Net.SConn.inst.setWssAddress("192.168.1.168", 9100);
            await Net.SConn.inst.start();
        }

        private async readLoop() {
            while(!this._closed) {
                let n = this._rereader.pull(this._recvBuf);
                if (n > 0) {
                    this._readCount += n;
                    this._tryReceivePacket();
                    continue;
                }

                if (this._connecting) {
                    await this._connecting; 
                }

                if (this._closed) {
                    return;
                }

                try {
                    n = await this._webSocket.read(this._recvBuf);
                } catch(e) {
                    console.error("readLoop ", e);
                    await this._tryReconn();
                    continue;
                }

                if (this._closed) {
                    return;
                }

                this._readCount += n;
                this._tryReceivePacket();
            }
        }

        private _tryReceivePacket() {
            if (this._recvStatus == NetPacketConsts._RECV_PAYLOAD_LENGTH) {
                if (this._recvBuf.readAvailable < NetPacketConsts.PktSizeSize) {
                    return;
                }
                this._recvPayloadLen = this._recvBuf.readUnsignedInt();
                console.debug("package size %d", this._recvPayloadLen)
                this._recvStatus = NetPacketConsts._RECV_PAYLOAD;
            }

            let dataLength = this._recvBuf.readAvailable;
            console.debug("package size %d, now data size %d", this._recvPayloadLen, dataLength);
            if (dataLength < this._recvPayloadLen) {
                // payload not enough
                return;
            }

            // 足够了，返回包数据
            let payload = new egret.ByteArray();
            this._recvBuf.readBytes(payload, 0, this._recvPayloadLen);
            if (this._recvPayloadLen == dataLength) {
                this._recvBuf.clear();
            } else {
                let rest = new egret.ByteArray();
                this._recvBuf.readBytes(rest, 0);
                this._recvBuf = rest;
            }
            // 恢复到接收长度状态
            this._recvStatus = NetPacketConsts._RECV_PAYLOAD_LENGTH
            this._recvPayloadLen = 0;
            this._onReceivePacket(payload);
            this._tryReceivePacket();
        }

        private _onReceivePacket(payload:egret.ByteArray) {
            let msgType = payload.readByte();
            console.debug("msgType %d", msgType);
            if (msgType == MessageType.MsgPong || msgType == MessageType.MsgPing) {
                return;
            }

            let pkt = new Packet();
            pkt.msgType = msgType;
            if (msgType == MessageType.MsgErr) {
                pkt.errcode = payload.readInt();
                pkt.seq = payload.readUnsignedInt();
                onSocketData(pkt);
                return;
            }
            
            if (msgType == MessageType.MsgPush || msgType == MessageType.MsgReq) {
                pkt.msgID = payload.readInt();
                if (msgType == MessageType.MsgReq) {
                    pkt.seq = payload.readUnsignedInt();
                }
            } else if (msgType == MessageType.MsgReply) {
                pkt.seq = payload.readUnsignedInt();
            } else {
                console.debug("error msgType %d", msgType);
                return;
            }

            if (payload.readAvailable > 0) {
                pkt.payload = new egret.ByteArray();
                payload.readBytes(pkt.payload, 0, payload.readAvailable);
            }
            onSocketData(pkt);
        }

        private async _sendPacket() {
            let payloadLen = this._sendBuf.position - NetPacketConsts.PktSizeSize;
            let packetLen = this._sendBuf.position;
            this._sendBuf.dataView.setUint32(0, payloadLen, false);

            this._rewriter.push(new egret.ByteArray( this._sendBuf.buffer.slice(0, packetLen) ));
            this._writeCount += packetLen;

            if (!this._webSocket.write(this._sendBuf, 0, packetLen)) {
                if (this._closed) {
                    return;
                }
                await this._tryReconn();
                return;
            }

            this._sendBuf.clear();
            this._sendBuf.position = NetPacketConsts.PktSizeSize;
        }

        public async writePacket(pkt: Packet) {
            let connID = this._connID;
            if (this._connecting) {
                await this._connecting;
                if (connID != this._connID) {
                    return;
                }
            }

            if (this._closed) {
                return;
            }

            this._sendBuf.writeByte(pkt.msgType);
            if (pkt.msgType == MessageType.MsgPing || pkt.msgType == MessageType.MsgPong) {
                this._sendPacket();
                return;
            }

            if (pkt.msgType == MessageType.MsgErr) {
                this._sendBuf.writeInt(pkt.errcode);
                this._sendBuf.writeUnsignedShort(pkt.seq);
                this._sendPacket();
                return;
            }

            if (pkt.msgType == MessageType.MsgPush || pkt.msgType == MessageType.MsgReq) {
                this._sendBuf.writeInt(pkt.msgID);
                if (pkt.msgType == MessageType.MsgReq) {
                    this._sendBuf.writeUnsignedInt(pkt.seq);
                }
            } else {
                this._sendBuf.writeUnsignedInt(pkt.seq);
            }

            if (pkt.payload != null) {
                this._sendBuf.writeBytes(pkt.payload, 0, pkt.payload.readAvailable);
            }
            this._sendPacket();
        }

        private async _tryReconn() {
            if (this._closed) {
                return;
            }
            if (this._connecting) {
                await this._connecting;
                return;
            }
            this._connecting = this._doReconn();
            await this._connecting;
            this._connecting = null;
        }

        private async _relogin() {
            if (this._closed) {
                return;
            }
            
            await this.connect();
            if (this._closed) {
                return;
            }
            this._init();
            Core.EventCenter.inst.dispatchEventWith(Core.Event.ReLoginEv);
        }

        private async _doReconn() {
            Core.MaskUtils.showNetMask();
            let buf = new egret.ByteArray(new ArrayBuffer(12));
            buf.writeUnsignedInt(this._connID);
            buf.writeUnsignedInt(this._writeCount);
            buf.writeUnsignedInt(this._readCount + this._rereader.count);

            this._reconnectTimes = 0;
            while(!this._closed) {
                this._reconnectTimes++;
                if (this._reconnectTimes >= 2) {
                    await this._relogin();
                    break;
                }

                if (this._webSocket) {
                    this._webSocket.close();
                    this._webSocket = null;
                }

                try {
                    await this.dial(this._serverlist.getCurServer(this._connectOldServer));
                } catch(e) {
                    console.error("_tryReconn dial ", e);
                    await fairygui.GTimers.inst.waitTime(1000);
                    // 建立连接失败，不算次数
                    this._reconnectTimes--;
                    continue;
                }

                if (this._closed) {
                    break;
                }

                let ok = this._webSocket.write(buf);
                if (!ok) {
                    console.error("_tryReconn write 1");
                    await fairygui.GTimers.inst.waitTime(1000);
                    continue;
                }

                let buf2 = new egret.ByteArray();
                try {
                    await this._webSocket.readFull(buf2, 8);
                } catch(e) {
                    console.error("_tryReconn read1 ", e);
                    await fairygui.GTimers.inst.waitTime(1000);
                    continue;
                }

                if (this._closed) {
                    break;
                }

                //if (buff2 == "fuck") {
                    // re login
                //    await this._relogin();
                //    break;
                //}

                let writeCount = buf2.readUnsignedInt();
                let readCount = buf2.readUnsignedInt();
                ok = await this._handleReconn(writeCount, readCount);
                if (ok) {
                    fairygui.GTimers.inst.callLater(()=>{
                        Core.EventCenter.inst.dispatchEventWith(Core.Event.ReConnectEv);
                    }, this);
                    break;
                } else {
                    await this._relogin();
                    break;
                }
            }

            Core.MaskUtils.hideNetMask();
        }

        private async _handleReconn(writeCount:number, readCount:number): Promise<boolean> {
            if (writeCount < this._readCount) {
                console.error("writeCount < c.readCount")
                return false;
            }

            if (this._writeCount < readCount) {
                console.error("c.writeCount < readCount")
                return false;
            }

            if ((this._writeCount-readCount) > this._rewriter.length) {
                console.error("c.writeCount - readCount > len(c.rewriter.data)")
                return false;
            }

            let p1: Promise<void>;
            if (writeCount != this._readCount) {
                p1 = this._rereader.reread(this._webSocket, writeCount - this._readCount);
            }

            if (this._writeCount != readCount) {
                if (!this._rewriter.rewrite(this._webSocket, this._writeCount, readCount)) {
                    console.error("rewrite failed")
                    return false;
                }
            }

            if (p1) {
                try {
                    await p1;
                } catch(e) {
                    console.error("reread failed ", e);
                    return false;
                }
            }

            return true;
        }

        private async dial(svrInfo: ServerInfo) {
            let webSocket = await dialWebSocket(svrInfo.host, svrInfo.port, svrInfo.host, svrInfo.wssport);
            this._webSocket = webSocket;
        }

        public ping() {
            let pkt = new Packet();
            pkt.msgType = MessageType.MsgPing;
            this.writePacket(pkt);
        }
    }

}
