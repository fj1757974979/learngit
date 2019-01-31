module Reward {

	export class RewardType {
		public static T_GOLD = 0;
		public static T_JADE = 1;
		public static T_CARD = 2;
		public static T_TREASURE = 3; // 宝箱
		public static T_CARD_SKIN = 4;
		public static T_HEAD_FRAME = 5;
		public static T_FEATS = 6; // 功勋
		public static T_PRESTIGE =7; // 名望
		public static T_EQUIP = 8;
		public static T_EMOJI = 9;
		public static T_CONTRIBUTION = 10; //战功
		public static T_BOWLDER = 11;	//玉石
		public static T_EXCHANGE_ITEM = 12;

		public static T_COMMON_SKIN = 1000;
		public static T_COMMON_EMOJI = 1001;
		public static T_COMMON_HEAD_FRAME = 1002;
		public static T_COMMON_EQUIP = 1003;
		public static T_COMMON_CARD = 1004;
	}

	export class RewardIconSize {
		public static T_BIG = 0;
		public static T_NORMAL = 1;
	}

	export class RewardMgr {

		private static _inst: RewardMgr;

		public static get inst() {
            if(!RewardMgr._inst) {
                RewardMgr._inst = new RewardMgr();
            }
            return RewardMgr._inst;
        }

		public constructor() {
		}

		public getRewardIconByStrType(t: string, param?: any) {
			let resType = null;
			if (t == "gold") {
				resType = RewardType.T_GOLD;
			} else if (t == "card") {
				resType = RewardType.T_CARD;
			} else if (t == "skin") {
				resType = RewardType.T_CARD_SKIN;
			} else if (t == "headFrame") {
				resType = RewardType.T_HEAD_FRAME;
			} else if (t == "jade") {
				resType = RewardType.T_JADE;
			} else if (t == "bowlder") {
				resType = RewardType.T_BOWLDER;
			} else if (t == "treasure") {
				resType = RewardType.T_TREASURE;
			}
			if (resType != null) {
				return this.getRewardIcon(resType, null, param);
			} else {
				return "";
			}
		}

		public getRewardIcon(t: RewardType, size?: RewardIconSize, param?: any) {
			if (t >= 1000) {
				return this.getCommonRewardIcon(t, size);
			}

			if (!size) {
				size = RewardIconSize.T_NORMAL;
			}

			if (t == RewardType.T_GOLD) {
                return "common_goldIcon_png";
            } else if (t == RewardType.T_JADE) {
                return "common_jadeIcon_png";
			} else if (t == RewardType.T_BOWLDER) {
				return "common_bowlderIcon_png";
			} else if (t == RewardType.T_EXCHANGE_ITEM) {
				return "common_yanhua_png";
			} else if (t == RewardType.T_CARD) {
                return `avatar_${param}_png`;
            } else if (t == RewardType.T_HEAD_FRAME) {
                return `headframe_${param}_png`;
            } else if (t == RewardType.T_CARD_SKIN) {
				return `avatar_${param}_png`;
            } else if (t == RewardType.T_TREASURE) {
                return `treasure_box${param}_png`;
            } else if (t == RewardType.T_FEATS) {
                return `common_honorIcon_png`;
            } else if (t == RewardType.T_PRESTIGE) {
                return `common_fameIcon_png`;
            } else if (t == RewardType.T_EMOJI) {
				let teamId = <number>param;
				let team = Social.EmojiMgr.inst.getEmojiTeam(teamId);
				if (team) {
					return team.icon;
				}
			} else if (t == RewardType.T_CONTRIBUTION) {
				return `war_fightIcon_png`;
			} else if (t == RewardType.T_EQUIP) {
				let equipData = Equip.EquipMgr.inst.getEquipData(param);
				return equipData.equipIcon;
			}
		}

		public getCommonRewardIcon(t: RewardType, size?: RewardIconSize) {
			if (!size) {
				size = RewardIconSize.T_NORMAL;
			}

			if (t == RewardType.T_COMMON_CARD) {
				return "common_cardIcon_png";
			} else if (t == RewardType.T_COMMON_EMOJI) {
				return "common_emojiIcon_png";
			} else if (t == RewardType.T_COMMON_HEAD_FRAME) {
				return "common_headFrame_png";
			} else if (t == RewardType.T_COMMON_SKIN) {
				return "common_skinIcon_png";
			} else {
				return null;
			}
		}
	}
}
