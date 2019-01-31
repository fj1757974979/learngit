module Treasure {

	export class TreasureRewardView extends Core.BaseView {

		private _card: UI.CardCom;
		private _skin: fairygui.GComponent;
		private _emoji: fairygui.GComponent;
		private _headFrame: fairygui.GComponent;
		private _countText: fairygui.GTextField;
		private _goldText: fairygui.GTextField;
		private _levelText: fairygui.GTextField;
		private _levelUpTips: fairygui.GTextField;
		private _expProgressBar: UI.MaskProgressBar;
		private _expProgressText: fairygui.GTextField;
		private _cardRemainText: fairygui.GTextField;

		private _boxEff0: fairygui.GLoader;
		private _boxEff1: fairygui.GLoader;
		private _boxEff2: fairygui.GLoader;
		private _boxEff3: fairygui.GLoader;
		private _boxEff4: fairygui.GLoader;
		//private _boxLight: fairygui.GLoader;
		private _rareLight: fairygui.GLoader;

		private _tranGold: fairygui.Transition;
		private _tranCard: fairygui.Transition;
		private _tranBowlder: fairygui.Transition;
		private _tranNewCard: fairygui.Transition;
		private _tranJade: fairygui.Transition;
		private _tranSkin: fairygui.Transition;
		private _tranEmoji: fairygui.Transition;
		private _tranHeadFrame: fairygui.Transition;
		private _tranHuodongItem: fairygui.Transition;
		private _transPlaying: boolean;

		private _reward: TreasureReward;
		private _treasure: TreasureItem;
		private _cardIds: Array<number>;
		private _skinIds: Array<string>;
		private _emojiTeamIds: Array<number>;
		private _headFrameIds: Array<string>;
		private _gold: number;
		private _jade: number;
		private _bowlder: number;
		private _huodongItem: number;

		private _curCardId: number;
		private _curAmount: number;
		private _curMaxAmount: number;
		private _toAmount: number;
		private _curGold: number;
		private _curJade: number;
		private _curBowlder: number;
		private _curHuodongItem: number;

		private _timeoutHdr: () => void;
		private _aniResolve: (value? :void|PromiseLike<void>) => void;
		private _finishCallback: () => void;
		private _transPlayDone: () => void;

		public initUI() {
			super.initUI();
			this.adjust(this.getChild("bg"));
			this._card = this.getChild("card").asCom as UI.CardCom;
			this._skin = this.getChild("skin").asCom;
			this._emoji = this.getChild("emoji").asCom;
			this._headFrame = this.getChild("headFrame").asCom;
			this._countText = this.getChild("cardCnt").asTextField;
			this._goldText = this.getChild("goldCnt").asTextField;
			this._levelText = this.getChild("level").asTextField;
			this._levelUpTips = this.getChild("levelTip").asTextField;
			this._expProgressBar = this.getChild("expProgressBar").asCom as UI.MaskProgressBar;
			this._expProgressText = this.getChild("progressCnt").asTextField;
			this._cardRemainText = this.getChild("cardRemaining").asTextField;

			this._boxEff0 = this.getChild("box0").asLoader;
			this._boxEff1 = this.getChild("box1").asLoader;
			this._boxEff2 = this.getChild("box2").asLoader;
			this._boxEff3 = this.getChild("box3").asLoader;
			this._boxEff4 = this.getChild("box4").asLoader;
			//this._boxLight = this.getChild("boxLight").asLoader;
			this._rareLight = this.getChild("rareLight").asLoader;

			this._tranGold = this.getTransition("gold");
			this._tranCard = this.getTransition("card");
			this._tranNewCard = this.getTransition("newCard");
			this._tranJade = this.getTransition("jade");
			this._tranBowlder = this.getTransition("bowlder");
			this._tranSkin = this.getTransition("skin");
			this._tranEmoji = this.getTransition("emoji");
			this._tranHeadFrame = this.getTransition("headFrame");
			this._tranHuodongItem = this.getTransition("item");
			this._transPlaying = false;

			this._expProgressBar.getChild("text").asTextField.text = "";
			this._expProgressBar.getChild("head").asLoader.visible = false;

			this._reward = null;
			this._finishCallback = null;

			this.addClickListener(this._playTransition, this);
		}

		public async open(...param: any[]) {
			await super.open(...param);
			Core.MaskUtils.hideTransMask();// 新手指引强撸
			this._reward = param[0] as TreasureReward;
			this._treasure = param[1] as TreasureItem;
			this._finishCallback = param[2];
			this._refreshContent();
			this._playTransition();
		}

		public async close(...param: any[]) {
			await super.close(...param);
			this._transPlaying = false;
			this._finishCallback = null;
		}

		private _refreshContent() {
			this._cardIds = this._reward.cardIds.keys();
			if (!this._cardIds) {
				this._cardIds = [];
			}
			this._skinIds = this._reward.skinIds.keys();
			if (!this._skinIds) {
				this._skinIds = [];
			}
			this._emojiTeamIds = this._reward.emojiIds.keys();
			if (!this._emojiTeamIds) {
				this._emojiTeamIds = [];
			}
			this._headFrameIds = this._reward.headFrames.keys();
			if (this._headFrameIds) {
				this._headFrameIds = [];
			}
			this._gold = this._reward.gold;
			this._jade = this._reward.jade;
			this._bowlder = this._reward.bowlder;
			this._huodongItem = this._reward.huodongItems;
			this._cardRemainText.text = `${this._cardIds.length}`;
			let rareType = this._treasure.getRareType();
			this._boxEff0.url = `treasure_${rareType}0_png`;
			this._boxEff1.url = `treasure_${rareType}1_png`;
			this._boxEff2.url = `treasure_${rareType}2_png`;
			this._boxEff3.url = `treasure_${rareType}3_png`;
			this._boxEff4.url = `treasure_${rareType}4_png`;
			//this._boxLight.url = `treasure_boxLight${rareType}_jta`;
		}

		private _setEmojiRewardInfo() {
			let emojiTeamId = this._emojiTeamIds[0];
			let icon = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_EMOJI, null, emojiTeamId);
			this._emoji.visible = true;
			this._emoji.getChild("headFrame").asLoader.url = icon;
			this._emoji.alpha = 1;
			this._countText.text = `x${this._reward.emojiIds.getValue(emojiTeamId)}`;
			this._countText.color = 0xffffff;
			this._levelUpTips.visible = false;
			this._rareLight.visible = false;
		}

		private _setHeadFrameRewardInfo() {
			let headFrameId = this._headFrameIds[0];
			let icon = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_HEAD_FRAME, null, headFrameId);
			this._headFrame.visible = true;
			this._headFrame.getChild("headFrame").asLoader.url = icon;
			this._headFrame.alpha = 1;
			this._countText.text = `x${this._reward.headFrames.getValue(headFrameId)}`;
			this._countText.color = 0xffffff;
			this._levelUpTips.visible = false;
			this._rareLight.visible = false;
		}

		private _setSkinRewardInfo() {
			let skinId = this._skinIds[0];
			let skinData = this._reward.skinIds.getValue(skinId);
			this._skin.visible = true;
		 	Utils.setImageUrlPicture(this._skin.getChild("cardImg").asImage, `skin_m_${skinId}_png`);
			this._skin.getChild("nameText").asTextField.text = CardPool.CardSkinMgr.inst.getSkinConf(skinId).name;
			this._skin.alpha = 1;
			this._countText.text = `x${this._reward.skinIds.getValue(skinId)}`;
			this._countText.color = 0xffffff;
			this._levelUpTips.visible = false;
			this._rareLight.visible = false;
		}

		private _setCardRewardInfo() {
			let cardId = this._cardIds[0];
			this._curCardId = cardId;
			let cardCount = this._reward.cardIds.getValue(cardId);
			let cardObj = CardPool.CardPoolMgr.inst.getCollectCard(cardId);
			if (!cardObj) {
				cardObj = new CardPool.Card(CardPool.CardPoolMgr.inst.getCardData(cardId, 1));
				cardObj.amount = cardCount;
			}
			this.getChild("card").asCom.alpha = 1;
			this.getChild("gold").asCom.alpha = 0;
			this._card.cardObj = cardObj;
			this._card.setDeskFront();
			this._card.setDeskBackground();
			this._card.setCardImg();
			this._card.setEquip();
			this._card.setNumText();
			this._card.setNumOffsetText();
			this._card.setName();
			this._card.setQualityMode(true);
			this._countText.text = `x${cardCount}`;
			this._countText.color = 0xffffff;
			this._goldText.visible = false;
			this._levelText.visible = true;
			this._levelText.text = Core.StringUtils.format(Core.StringUtils.TEXT(60029), Core.StringUtils.getZhNumber(cardObj.level));
			this._curAmount = cardObj.amount - cardCount;
			this._toAmount = cardObj.amount;
			this._curMaxAmount = cardObj.maxAmount;
			this._levelUpTips.visible = false;
			this._expProgressBar.visible = true;
			this._expProgressText.visible = true;
			if (this._curMaxAmount <= 0) {
				this._expProgressText.text = `${this._curAmount}/`+Core.StringUtils.TEXT(60030);
				this._expProgressBar.setProgress(100, 100);
			} else {
				this._expProgressText.text = `${this._curAmount}/${this._curMaxAmount}`;
				this._expProgressBar.setProgress(this._curAmount, this._curMaxAmount);
			}

			if ((cardObj.amount == cardCount && cardObj.level == 1) || this._curAmount >= this._curMaxAmount) {
				this._levelUpTips.visible = true;
			}
		}

		private _setGoldRewardInfo() {
			this._levelUpTips.visible = false;
			this._levelText.visible = false;
			this.getChild("card").asCom.alpha = 0;
			this.getChild("jade").asCom.alpha = 0;
			this.getChild("gold").asCom.alpha = 1;
			this.getChild("bowlder").asCom.alpha = 0;
			this._curGold = Player.inst.getResource(ResType.T_GOLD) - this._gold;
			this._goldText.text = `${this._curGold}`;
			this._countText.text = `x${this._gold}`;
			this._countText.color = 0xffff00;
			this._goldText.visible = true;
			this._goldText.color = 0xffff00;
			this._expProgressText.visible = false;
			this._expProgressBar.setProgress(0, 100);
			this._expProgressBar.visible = false;
		}

		private _setJadeRewardInfo() {
			this._levelUpTips.visible = false;
			this._levelText.visible = false;
			this.getChild("card").asCom.alpha = 0;
			this.getChild("gold").asCom.alpha = 0;
			this.getChild("jade").asCom.alpha = 1;
			this.getChild("bowlder").asCom.alpha = 0;
			this._curJade = Player.inst.getResource(ResType.T_JADE) - this._jade;
			this._goldText.text = `${this._curJade}`;
			this._countText.text = `x${this._jade}`;
			this._countText.color = 0x66ff99;
			this._goldText.visible = true;
			this._goldText.color = 0x66ff99;
			this._expProgressText.visible = false;
			this._expProgressBar.setProgress(0, 100);
			this._expProgressBar.visible = false;
		}

		private _setBowlderRewardInfo() {
			this._levelUpTips.visible = false;
			this._levelText.visible = false;
			this.getChild("card").asCom.alpha = 0;
			this.getChild("gold").asCom.alpha = 0;
			this.getChild("jade").asCom.alpha = 0;
			this.getChild("bowlder").asCom.alpha = 1;
			this._curBowlder = Player.inst.getResource(ResType.T_BOWLDER) - this._bowlder;
			this._goldText.text = `${this._curBowlder}`;
			this._countText.text = `x${this._bowlder}`;
			this._countText.color = 0x66ff99;
			this._goldText.visible = true;
			this._goldText.color = 0x66ff99;
			this._expProgressText.visible = false;
			this._expProgressBar.setProgress(0, 100);
			this._expProgressBar.visible = false;
		}

		private _setHuodongItemRewardInfo() {
			this._levelUpTips.visible = false;
			this._levelText.visible = false;
			this.getChild("card").asCom.alpha = 0;
			this.getChild("gold").asCom.alpha = 0;
			this.getChild("jade").asCom.alpha = 0;
			this.getChild("bowlder").asCom.alpha = 0;
			this.getChild("item").asCom.alpha = 1;
			this.getChild("item").asCom.getChild("n20").asLoader.url = Reward.RewardMgr.inst.getRewardIcon(Reward.RewardType.T_EXCHANGE_ITEM);
			this._curHuodongItem = Player.inst.getResource(ResType.T_EXCHANGE_ITEM) - this._huodongItem;
			this._goldText.text = `${this._curHuodongItem}`;
			this._countText.text = `x${this._huodongItem}`;
			this._countText.color = 0xffffff;
			this._goldText.visible = true;
			this._goldText.color = 0xffffff;
			this._expProgressText.visible = false;
			this._expProgressBar.setProgress(0, 100);
			this._expProgressBar.visible = false;
		}

		private _onPlaySkinAniDone() {
			this.getChild("skin").asCom.visible = true;
			this._transPlaying = false;
		}

		private _onPlayEmojiAniDone() {
			this._emoji.visible = true;
			this._transPlaying = false;
		}

		private _onPlayHeadFrameAniDone() {
			this._headFrame.visible = true;
			this._transPlaying = false;
		}

		private _onPlayCardAniDone() {
			if (this._curMaxAmount <= 0) {
				this._expProgressText.text = `${this._toAmount}/`+Core.StringUtils.TEXT(60030);
				this._expProgressBar.setProgress(100, 100);
			} else {
				this._expProgressText.text = `${this._toAmount}/${this._curMaxAmount}`;
				this._expProgressBar.setProgress(this._toAmount, this._curMaxAmount);
				if (this._toAmount >= this._curMaxAmount) {
					this._levelUpTips.visible = true;
				}
			}
			this.getChild("card").asCom.visible = true;
			this._transPlaying = false;
			this._curCardId = null;
		}

		private _onPlayGoldAniDone() {
			//this._expProgressText.text = `${Player.inst.getResource(ResType.T_GOLD)}`;
			this._goldText.text = `${Player.inst.getResource(ResType.T_GOLD)}`;
			this._goldText.color = 0xffff00;
			this.getChild("gold").asCom.visible = true;
			this._transPlaying = false;
			this._gold = 0;
		}

		private _onPlayJadeAniDone() {
			this._goldText.text = `${Player.inst.getResource(ResType.T_JADE)}`;
			this._goldText.color = 0x66ff99;
			this.getChild("jade").asCom.visible = true;
			this._transPlaying = false;
			this._jade = 0;
		}

		private _onPlayBowlderAniDone() {
			this._goldText.text = `${Player.inst.getResource(ResType.T_BOWLDER)}`;
			this._goldText.color = 0x66ff99;
			this.getChild("bowlder").asCom.visible = true;
			this._transPlaying = false;
			this._bowlder = 0;
		}

		private _onPlayHuodongItemAniDone() {
			this._goldText.text = `${Player.inst.getResource(ResType.T_EXCHANGE_ITEM)}`;
			this._goldText.color = 0x66ff99;
			this.getChild("item").asCom.visible = true;
			this._transPlaying = false;
			this._huodongItem = 0;
		}

		private async _onPlayTransitionCompleted() {
			if (this._gold > 0) {
				await new Promise<void>(resolve => {
					this._aniResolve = resolve;
					let add = this._gold
					let times = 60
					let step = add / times
					if (step < 1) {
						times = add
						step = 1
					}
					this._timeoutHdr = () => {
						this._curGold += step
						if (this._curGold >= Player.inst.getResource(ResType.T_GOLD)) {
							this._curGold = Player.inst.getResource(ResType.T_GOLD);
							add = step;
						}
						this._goldText.text = `${Math.ceil(this._curGold)}`;
						add -= step;
						if (add <= 0) {
							this._aniResolve = null;
							this._timeoutHdr = null;
							this._onPlayGoldAniDone();
							resolve();
						}
					}
					fairygui.GTimers.inst.add(1, times, this._timeoutHdr, this);
				});
			} else if (this._jade > 0) {
				await new Promise<void>(resolve => {
					this._aniResolve = resolve;
					let add = this._jade
					let times = 60
					let step = add / times
					if (step < 1) {
						times = add
						step = 1
					}
					this._timeoutHdr = () => {
						this._curJade += step
						if (this._curJade >= Player.inst.getResource(ResType.T_GOLD)) {
							this._curJade = Player.inst.getResource(ResType.T_GOLD);
							add = step;
						}
						this._goldText.text = `${Math.ceil(this._curJade)}`;
						add -= step;
						if (add <= 0) {
							this._aniResolve = null;
							this._timeoutHdr = null;
							this._onPlayJadeAniDone();
							resolve();
						}
					}
					fairygui.GTimers.inst.add(1, times, this._timeoutHdr, this);
				});
			} else if (this._bowlder > 0) {
				await new Promise<void>(resolve => {
					this._aniResolve = resolve;
					let add = this._bowlder
					let times = 60
					let step = add / times
					if (step < 1) {
						times = add
						step = 1
					}
					this._timeoutHdr = () => {
						this._curBowlder += step
						if (this._curBowlder >= Player.inst.getResource(ResType.T_BOWLDER)) {
							this._curBowlder = Player.inst.getResource(ResType.T_BOWLDER);
							add = step;
						}
						this._goldText.text = `${Math.ceil(this._curBowlder)}`;
						add -= step;
						if (add <= 0) {
							this._aniResolve = null;
							this._timeoutHdr = null;
							this._onPlayBowlderAniDone();
							resolve();
						}
					}
					fairygui.GTimers.inst.add(1, times, this._timeoutHdr, this);
				});
			} else if (this._huodongItem > 0) {
				await new Promise<void>(resolve => {
					this._aniResolve = resolve;
					let add = this._huodongItem
					let times = 60
					let step = add / times
					if (step < 1) {
						times = add
						step = 1
					}
					this._timeoutHdr = () => {
						this._curHuodongItem += step
						if (this._curHuodongItem >= Player.inst.getResource(ResType.T_EXCHANGE_ITEM)) {
							this._curHuodongItem = Player.inst.getResource(ResType.T_EXCHANGE_ITEM);
							add = step;
						}
						this._goldText.text = `${Math.ceil(this._curHuodongItem)}`;
						add -= step;
						if (add <= 0) {
							this._aniResolve = null;
							this._timeoutHdr = null;
							this._onPlayHuodongItemAniDone();
							resolve();
						}
					}
					fairygui.GTimers.inst.add(1, times, this._timeoutHdr, this);
				});
			} else if (this._curCardId) {
				let curAmount = this._curAmount;
				if (this._curAmount < this._curMaxAmount) {
					let callCardAniDone = false;
					await this._expProgressBar.doProgressAnimation(this._curAmount, this._toAmount, this._curMaxAmount,(cur) => {
					if (this._curMaxAmount <= 0) {
						this._expProgressText.text = `${Math.round(cur)}/`+Core.StringUtils.TEXT(60030);
					} else {
						this._expProgressText.text = `${Math.round(cur)}/${this._curMaxAmount}`;
					}
						curAmount = Math.round(cur);
						if (curAmount >= this._curMaxAmount) {
							this._levelUpTips.visible = true;
						}
						if (curAmount >= this._toAmount && !callCardAniDone) {
							callCardAniDone = true;
							this._onPlayCardAniDone();
						}
					});
				}
				if (curAmount < this._toAmount) {
					// 继续
					let amount = curAmount;
					let add = this._toAmount - amount;
					await new Promise<void>(resolve => {
						this._aniResolve = resolve;
						this._timeoutHdr = () => {
							amount += 1;
							add -= 1;
							if (this._curMaxAmount <= 0) {
								this._expProgressText.text = `${amount}/`+Core.StringUtils.TEXT(60030);
							} else {
								this._expProgressText.text = `${amount}/${this._curMaxAmount}`;
							}
							if (amount >= this._curMaxAmount) {
								this._levelUpTips.visible = true;
							}
							if (add <= 0) {
								this._aniResolve = null;
								this._onPlayCardAniDone();
								resolve();
							}
						};
						fairygui.GTimers.inst.add(1, add, this._timeoutHdr, this);
                	});
				}	
			} else {
				await new Promise<void>(resolve => {
					this._aniResolve = resolve;
					let add = 1;
					let times = 60
					let step = add / times
					if (step < 1) {
						times = add
						step = 1
					}
					this._timeoutHdr = () => {
						add -= step;
						if (add <= 0) {
							this._aniResolve = null;
							this._timeoutHdr = null;
							// this._onPlaySkinAniDone();
							Function.apply(this._transPlayDone, this);
							resolve();
						}
					}
					fairygui.GTimers.inst.add(1, times, this._timeoutHdr, this);
				});
			}
		}

		private _playTransition() {
			if (this._transPlaying) {
				this._expProgressBar.stopProgressAnimation();
				if (this._aniResolve) {
					this._aniResolve();
					this._aniResolve = null;
				}
				if (this._tranGold.playing) {
					this._tranGold.stop(true);
				}
				if (this._tranCard.playing) {
					this._tranCard.stop(true);
				}
				if (this._tranNewCard.playing) {
					this._tranNewCard.stop(true);
				}
				if (this._tranJade.playing) {
					this._tranJade.stop(true);
				}
				if (this._tranBowlder.playing) {
					this._tranBowlder.stop(true);
				}
				if (this._tranHuodongItem.playing) {
					this._tranHuodongItem.stop(true);
				}
				if (this._tranSkin.playing) {
					this._tranSkin.stop(true);
				}
				if (this._tranEmoji.playing) {
					this._tranEmoji.stop(true);
				}
				if (this._tranHeadFrame.playing) {
					this._tranHeadFrame.stop(true);
				}
				if (this._timeoutHdr) {
					fairygui.GTimers.inst.remove(this._timeoutHdr, this);
					this._timeoutHdr = null;
				}
				if (this._gold > 0) {
					this._onPlayGoldAniDone();
				}  else if (this._jade > 0) {
					this._onPlayJadeAniDone();
				} else if (this._bowlder > 0) {
					this._onPlayBowlderAniDone();
				} else if (this._huodongItem > 0) {
					this._onPlayHuodongItemAniDone();
				} else if (this._curCardId) {
					this._onPlayCardAniDone();
				} else {
					this._onPlaySkinAniDone();
				}
				return;
			}
			this._transPlaying = true;
			if (this._gold > 0) {
				// 金币
				this._setGoldRewardInfo();
				this._tranGold.play(this._onPlayTransitionCompleted, this);
			} else if (this._jade > 0) {
				this._setJadeRewardInfo();
				this._tranJade.play(this._onPlayTransitionCompleted, this);
			} else if (this._bowlder > 0) {
				this._setBowlderRewardInfo();
				this._tranBowlder.play(this._onPlayTransitionCompleted, this);
			} else if (this._huodongItem > 0) {
				this._setHuodongItemRewardInfo();
				this._tranHuodongItem.play(this._onPlayTransitionCompleted, this);
			} else if (this._cardIds.length > 0) {
				// 卡牌
				this._setCardRewardInfo();
				this._cardRemainText.text = `${this._cardIds.length - 1}`;
				let card = CardPool.CardPoolMgr.inst.getCollectCard(this._cardIds[0]);
				let count = this._reward.cardIds.getValue(this._cardIds[0]);
				if (card.amount == count && card.level == 1) {
					this._levelUpTips.text = Core.StringUtils.TEXT(60065);
					this._tranNewCard.play(this._onPlayTransitionCompleted, this);
				} else {
					this._levelUpTips.text = Core.StringUtils.TEXT(60056);
					this._tranCard.play(this._onPlayTransitionCompleted, this);
				}
				if (card.rare >= 3) {
					this._rareLight.visible = true;
				} else {
					this._rareLight.visible = false;
				}
				this._cardIds.splice(0, 1);
			} else if (this._skinIds.length > 0) {
				//皮肤
				this._setSkinRewardInfo();
				this._transPlayDone = this._onPlaySkinAniDone;
				// this._tran4.play();
				this._tranSkin.play(this._onPlayTransitionCompleted, this);
				this._skinIds.splice(0, 1);
			} else if (this._emojiTeamIds.length > 0) {
				this._setEmojiRewardInfo();
				this._transPlayDone = this._onPlayEmojiAniDone;
				this._tranEmoji.play(this._onPlayTransitionCompleted, this);
				this._emojiTeamIds.splice(0, 1);
			} else {
				// headFrame
				if (this._headFrameIds.length <= 0) {
					Core.ViewManager.inst.open(ViewName.treasureRewardResult, this._reward, this._treasure, this._finishCallback);
					Core.ViewManager.inst.closeView(this);
					return;
				}
				this._setHeadFrameRewardInfo();
				this._transPlayDone = this._onPlayHeadFrameAniDone;
				this._tranHeadFrame.play(this._onPlayTransitionCompleted, this);
				this._headFrameIds.splice(0, 1);
			}
		}
	}
}