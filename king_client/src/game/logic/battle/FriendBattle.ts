module Battle {

    export class FriendBattle extends Battle {
        public get battleType(): BattleType {
            return BattleType.Friend;
        }

        public getEndViewName(): string {
            return ViewName.friendBattleEnd;
        }

        public isPvp(): boolean {
            return true;
        }
    }

}