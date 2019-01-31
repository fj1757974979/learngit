module Home {

	export class GameFuncType {
		public static SHOP_GIFT = "shopGift"; // 商城礼包 done
		public static ADVERT = "advert"; // 广告 
		public static FEAT = "honor"; // 功勋 done
		public static EQUIP = "equip"; // 宝物 done
		public static RANK_SEASON = "rankSeason"; // 锦标赛
		public static SURVEY = "survey"; // 调查问卷 done
		public static WORLD_WAR = "worldWar"; // 国战
		public static CARD_UP_JADE = "cardUpJade"; // 宝玉升级卡牌 done
		public static EMOJI_TO_CHAT = "emojiToChat"; // 聊天发表情 done
		public static VIDEO_TO_CHAT = "videoToChat"; // 战报分享到聊天 done
		public static VIP_CARD = "vipCard"; // 士族体验卡
		public static SKIN = "skin"; // 皮肤 done
		public static LEVEL_VIDEO = "levelVideo"; // 关卡战报 done
		public static SKILL_INSTR = "skillInstruction"; // 技能结算说明 done
		public static RANDOM_NAME = "randomName"; // 随机名字 done
		public static IAP = "iap"; // 内购 done
	}

	export class FunctionMgr {

		private static _inst: FunctionMgr;

		public static get inst(): FunctionMgr {
            if (!FunctionMgr._inst) {
                FunctionMgr._inst = new FunctionMgr();
            }
            return FunctionMgr._inst;
        }

		public isFuncOpen(t: string): boolean {
			let channel = window.gameGlobal.channel;
			let data = Data.function_config.get(channel);
			if (data == null) {
				return false;
			}
			return data[t] == 1;
		}

		public isShopGiftOpen(): boolean {
			return this.isFuncOpen(GameFuncType.SHOP_GIFT);
		}

		public isAdvertOpen(): boolean {
			return this.isFuncOpen(GameFuncType.ADVERT);
		}

		public isFeatOpen(): boolean {
			if (Player.inst.isNewVersionPlayer()) {
				return false;
			}
			return this.isFuncOpen(GameFuncType.FEAT);
		}

		public isEquipOpen(): boolean {
			return this.isFuncOpen(GameFuncType.EQUIP);
		}

		public isRankSeasonOpen(): boolean {
			return this.isFuncOpen(GameFuncType.RANK_SEASON);
		}

		public isSurveyOpen(): boolean {
			return this.isFuncOpen(GameFuncType.SURVEY);
		}

		public isWorldWarOpen(): boolean {
			if (Player.inst.isNewVersionPlayer()) {
				return false;
			}
			return this.isFuncOpen(GameFuncType.WORLD_WAR);
		}

		public isCardUpJadeOpen(): boolean {
			return this.isFuncOpen(GameFuncType.CARD_UP_JADE);
		}

		public isEmojiToChatOpen(): boolean {
			return this.isFuncOpen(GameFuncType.EMOJI_TO_CHAT);
		}

		public isVideoToChatOpen(): boolean {
			return this.isFuncOpen(GameFuncType.VIDEO_TO_CHAT);
		}

		public isVipCardOpen(): boolean {
			return this.isFuncOpen(GameFuncType.VIP_CARD);
		}

		public isSkinOpen(): boolean {
			return this.isFuncOpen(GameFuncType.SKIN);
		}

		public isLevelVideoOpen(): boolean {
			return this.isFuncOpen(GameFuncType.LEVEL_VIDEO);
		}

		public isSkillInstructionOpen(): boolean {
			return this.isFuncOpen(GameFuncType.SKILL_INSTR);
		}

		public isRandomNameOpen(): boolean {
			return this.isFuncOpen(GameFuncType.RANDOM_NAME);
		}

		public isInAppPurchaseOpen(): boolean {
			if (Core.DeviceUtils.isWXGame() && WXGame.WXGameMgr.inst.platform != "android") {
				return false;
			}
			return this.isFuncOpen(GameFuncType.IAP);
		}
	}
}