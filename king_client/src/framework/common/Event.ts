module Core {

    export class EventCenter extends egret.EventDispatcher {
        private static _inst: EventCenter;

        public static get inst(): EventCenter {
            if (!EventCenter._inst) {
                EventCenter._inst = new EventCenter();
            }
            return EventCenter._inst;
        }
    }

    export class Event {
        public static CloseViewEvt = "CloseViewEvt";
        public static OpenViewEvt = "OpenViewEvt";
        public static ReLoginEv = "ReLoginEv";
        public static AddTreasureEvt = "AddTreasureEv";
        public static DelTreasureEvt = "DelTreasureEv";
        public static UpdateTreasureEvt = "UpdateTreasureEvt";
        public static UpdateDailyTreasureEvt = "UpdateDailyTreasureEvt";
        public static HomeListChangedEvt = "HomeListChangeEvt";
        public static CardHintNumChangeEv = "CardHintNumChangeEv";
        public static LevelHintNumChangeEv = "LevelHintNumChangeEv";
        public static AvatarHintNumChangeEv = "AvatarHintNumChangeEv";
        public static ReConnectEv = "ReConnectEv";
    }
}