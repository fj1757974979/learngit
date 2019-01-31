module Core {

    export class DeviceUtils {

        /**
         * 当前是否Html5版本
         */
        public static isHtml5():boolean {
            return egret.Capabilities.runtimeType == egret.RuntimeType.WEB;
        }

        /**
         * 当前是否是Native版本
         */
        public static isNative():boolean {
            return egret.Capabilities.runtimeType == egret.RuntimeType.NATIVE;
        }

        /**
         * 当前是否是微信小游戏版本
         */
        public static isWXGame():boolean {
            return egret.Capabilities.runtimeType == egret.RuntimeType.WXGAME;
        }

        /**
         * 是否是在手机上
         */
        public static isMobile():boolean {
            return egret.Capabilities.isMobile;
        }

        /**
         * 是否是在PC上
         */
        public static isPC():boolean {
            return !egret.Capabilities.isMobile;
        }

        /**
         * 是否是android系统
         */
        public static isAndroid():boolean {
            return egret.Capabilities.os == "Android";
        }

        /**
         * 是否是iOS系统
         */
        public static isiOS(): boolean {
            return egret.Capabilities.os == "iOS";
        }

    }

}