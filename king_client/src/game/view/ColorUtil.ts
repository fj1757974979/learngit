module util {
    export function setObjGray(obj, isset: boolean) {
        if (!isset) {
            obj.filters = [];
            return;
        }
        let colorMatrix = [
            0.3, 0.6, 0, 0, 0,
            0.3, 0.6, 0, 0, 0,
            0.3, 0.6, 0, 0, 0,
            0, 0, 0, 1, 0
        ];

        let colorFilter = new egret.ColorMatrixFilter(colorMatrix);
        obj.filters = [colorFilter];
    }
}