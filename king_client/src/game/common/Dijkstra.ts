// Dijkstra最短路径

module Util {

    // 邻接矩阵
    export class DjAdjacencyMatrix {
        private _arc: Array<Array<number>>;
        private _vertexNum: number;
        private _initialized: boolean;

        public constructor(vertexNum: number) {
            this._arc = new Array<Array<number>>();
            this._vertexNum = vertexNum;
            for (let i = 0; i < vertexNum; i ++) {
                let arr = new Array<number>();
                for (let j = 0; j < vertexNum; j ++) {
                    arr.push(Number.MAX_VALUE);
                }
                this._arc.push(arr);
            }
            this._initialized = false;
        }

        public get vertexNum(): number {
            return this._vertexNum;
        }

        public get arc(): Array<Array<number>> {
            return this._arc;
        }

        public get initialized(): boolean {
            return this._initialized;
        }

        public addAdjacentPoint(idx1: number, idx2: number, value: number): boolean {
            if (idx1 < 0 || idx1 >= this._vertexNum || idx2 < 0 || idx2 >= this._vertexNum) {
                return false;
            }
            this._arc[idx1][idx2] = value;
            this._arc[idx2][idx1] = value;
            this._initialized = true;
            return true;
        }

        public reset() {
            for (let i = 0; i < this._vertexNum; i ++) {
                for (let j = 0; j < this._vertexNum; j ++) {
                    this._arc[i][j] = Number.MAX_VALUE;
                }
            }
            this._initialized = false;
        }
    }

    export class DjDistance {
        public path: Array<number>;
        public value: number;
        public visit: boolean;

        public constructor() {
            this.path = new Array<number>();
            this.value = 0;
            this.visit = false;
        }
    }

    export function Dijkstra(matrix: DjAdjacencyMatrix, begin: number): Array<DjDistance> {
        let dis = new Array<DjDistance>();
        let vexnum = matrix.vertexNum;
        for (let i = 0; i < vexnum; i ++) {
            let disObj = new DjDistance();
            disObj.path = [begin, i]; 
            disObj.value = matrix.arc[begin][i];
            dis.push(disObj);
        }
        dis[begin].value = 0;
        dis[begin].visit = true;
        for (let count = 1; count < vexnum; count ++) {
            let temp = 0;
            let min = Number.MAX_VALUE;
            for (let i = 0; i < vexnum; i++) {
                if (!dis[i].visit && dis[i].value < min) {
                    min = dis[i].value;
                    temp = i;
                }
            }
            
            dis[temp].visit = true;
            for (let i = 0; i < vexnum; i++) {
                if (!dis[i].visit && matrix.arc[temp][i] != Number.MAX_VALUE && (dis[temp].value + matrix.arc[temp][i]) < dis[i].value) {
                    dis[i].value = dis[temp].value + matrix.arc[temp][i];
                    dis[i].path = dis[temp].path.concat([i]);
                }
            }
        }
        return dis;
    }
}