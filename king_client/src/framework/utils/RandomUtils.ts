module Core {

    export class RandomUtils {

        /**
         * @returns [0, n) 的整数，当n <= 0, return 0
         */
        public static randInt(n:number):number {
            if (n <= 0) {
                return 0;
            }
            return Math.floor(Math.random() * n);
        }

        public static shuffle(arr: Array<any>): Array<any> {
            let size = arr.length;
            while (size >= 2) {
                let k = RandomUtils.randInt(size);
                let tmp = arr[k];
                arr[k] = arr[size - 1];
                arr[size - 1] = tmp;
                // arr[size - 1], arr[k] = arr[k], arr[size - 1];
                -- size;
            }
            return arr;
        }
    }

}