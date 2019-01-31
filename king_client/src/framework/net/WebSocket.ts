module Net {

    enum WebSocketStateEnum {
        CONNECTING,
        CONNECTED,
        CLOSING,
        CLOSED
    }

    export async function dialWebSocket(host: string, port: number, wsshost:string, wssport:number): Promise<WebSocket> {
        let socket = new WebSocket();
        await socket.dial(host, port, wsshost, wssport);
        return socket;
    }

    export class WebSocket extends egret.WebSocket {

        private _state: WebSocketStateEnum = WebSocketStateEnum.CLOSED;
        private _conecting: Array<any>;
        private _reading: Array<any>;
        private _recvBuf: egret.ByteArray;

        public constructor() {
            super();
            this.type = egret.WebSocket.TYPE_BINARY;
            this._recvBuf = new egret.ByteArray();

            this.addEventListener(egret.Event.CONNECT, this._onConnected, this);
            this.addEventListener(egret.ProgressEvent.SOCKET_DATA, this._onSocketData, this);
            this.addEventListener(egret.IOErrorEvent.IO_ERROR, this._onIOError, this);
            this.addEventListener(egret.Event.CLOSE, this._onClosed, this);
        }

        private _onConnected(event: egret.Event): void {
            console.debug("WebSocket onConnected");
            this._state = WebSocketStateEnum.CONNECTED;
            if (this._conecting) {
                this._conecting[0]();
                this._conecting = null;
            }
        }

        private _onSocketData(event: egret.ProgressEvent): void {
            if (this._reading) {
                let buf = this._reading[2] as egret.ByteArray;
                let n1 = buf.readAvailable;
                if (this._recvBuf.readAvailable > 0) {
                    this._recvBuf.readBytes(buf, buf.readAvailable);
                }
                
                this.readBytes(buf, buf.readAvailable);
                
                this._reading[0](buf.readAvailable - n1);
                this._reading = null;
            } else {
                this.readBytes(this._recvBuf, this._recvBuf.readAvailable);
            }
        }

        private _onIOError(event: egret.IOErrorEvent): void {
            console.error("WebSocket onIOError");
            this._state = WebSocketStateEnum.CLOSED;
            if (this._conecting) {
                this._conecting[1]("_onIOError");
                this._conecting = null;
            }
            if (this._reading) {
                this._reading[1]("_onIOError");
                this._reading = null;
            }
        }

        private _onClosed(event: egret.Event): void {
            console.error("WebSocket onClosed");
            this._state = WebSocketStateEnum.CLOSED;
            if (this._conecting) {
                this._conecting[1]("_onClosed");
                this._conecting = null;
            }
            if (this._reading) {
                this._reading[1]("_onClosed");
                this._reading = null;
            }
        }

        public async dial(host:string, port:number, wsshost:string, wssport:number) {
            this._state = WebSocketStateEnum.CONNECTING;
            await new Promise<void>((resolve, reject)=>{
                this._conecting = [resolve, reject];
                ///this.connect(host, 9200);
                if (Core.DeviceUtils.isWXGame() || document.location.protocol == "https:") {
		           this.connectByUrl(`wss://${wsshost}:${wssport}`);
                } else {
                    this.connectByUrl(`ws://${host}:${port}`);
                }
            });
        }

        public async read(buf:egret.ByteArray): Promise<number> {
            if (this._recvBuf.readAvailable > 0) {
                let n = this._recvBuf.readAvailable;
                this._recvBuf.readBytes(buf, buf.readAvailable);
                this._recvBuf.clear();
                return n;
            }

            return await new Promise<number>((resolve, reject)=>{
                if (this._state != WebSocketStateEnum.CONNECTED) {
                    reject("read not CONNECTED");
                }
                this._reading = [resolve, reject, buf];
            });
        }

        public async readFull(buf:egret.ByteArray, n:number) {
            while(buf.readAvailable < n) {
                await this.read(buf);
            }
        }

        public write(data:egret.ByteArray, offset?:number, length?:number): boolean {
            if (this._state != WebSocketStateEnum.CONNECTED) {
                return false;
            }
            this.writeBytes(data, offset, length);
            return true;
        }
    }

}
