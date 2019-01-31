module Home {

    export class SurveyView extends Core.BaseWindow {
        private _closeBtn: fairygui.GButton;
        private _beginBtn: fairygui.GButton;
        private _nextBtn: fairygui.GButton;
        private _completeBtn: fairygui.GButton;
        private _rewardBtn: fairygui.GButton;
        private _answerList: fairygui.GList;
        private _answers: Array<Array<number>>;
        public static IsComplete: boolean = false;

        private _index: number;

        public initUI() {
            super.initUI();
            this.adjust(this.getChild("panel"), Core.AdjustType.EXCEPT_MARGIN);
            this.y += window.support.topMargin;

            this._closeBtn = this.getChild("closeBtn").asButton;
            this._beginBtn = this.getChild("beginBtn").asButton;
            this._nextBtn = this.getChild("nextBtn").asButton;
            this._completeBtn = this.getChild("completeBtn").asButton;
            this._rewardBtn = this.getChild("rewardBtn").asButton;
            this._answerList = this.getChild("answerList").asList;

            this._closeBtn.addClickListener(() => {
                this.close();
            }, this);

            this._beginBtn.addClickListener(() => {
                this.begin();
            }, this);

            this._nextBtn.addClickListener(() => {
                this.next();
            }, this);

            this._completeBtn.addClickListener(() => {
                this.complete();
            }, this);

            this._rewardBtn.addClickListener(() => {
                this.reward();
            }, this);

            this._answerList.addClickListener(() => {
                if (this._answerList.getSelection().length > 0) {
                    if (this._index == Data.question.keys.length) {
                        this._completeBtn.visible = true;
                    } else {
                        this._nextBtn.visible = true;
                    }
                } else {
                    this._nextBtn.visible = false;
                    this._completeBtn.visible = false;
                }
            }, this);
        }

        private async reward() {
            this._rewardBtn.enabled = false;
            let result = await Net.rpcCall(pb.MessageID.C2S_GET_SURVEY_REWARD, null);
            if (result.errcode == 0) {

                let reply = pb.OpenTreasureReply.decode(result.payload);
                let reward = new Treasure.TreasureReward();
                reward.setRewardForOpenReply(reply);
                Core.ViewManager.inst.open(ViewName.treasureRewardInfo, reward, new Treasure.TreasureItem(-1, "BX6004"));

                let view = Core.ViewManager.inst.getView(ViewName.match) as Pvp.MatchView;
                view.hideQuestion();
                this.close();
            }
            this._rewardBtn.enabled = true;
        }

        public begin(): void {
            this.getController("page").setSelectedIndex(2);
            this.initQuestion(1);
            this._completeBtn.visible = false;
            this._answers = new Array(Data.question.keys.length);
        }

        public next(): void {
            let selection: number[] = this._answerList.getSelection();
            this._answers[this._index - 1] = selection;
            //console.log(`${this._index} ` + selection.toString() + this._answers.toString());
            this.initQuestion(this._index + 1);
        }

        public async complete() {
            let selection: number[] = this._answerList.getSelection();
            this._answers[this._index - 1] = selection;
            let pbanswer = new pb.SurveyAnswer();
            pbanswer.Answers = [];
            for (let i = 0; i < Data.question.keys.length; i++) {
                let an = new pb.Answer();
                an.QuestionID = i + 1;
                an.AnswerIDs = this._answers[i];
                pbanswer.Answers.push(an);
            }
            await Net.rpcCall(pb.MessageID.C2S_COMPLETE_SURVEY, pb.SurveyAnswer.encode(pbanswer));
            this.getController("page").setSelectedIndex(1);
        }

        public initQuestion(index: number): void {
            this._index = index;
            let count = Data.question.keys.length;
            let info = Data.question.get(index);
            this._nextBtn.visible = false;

            this._answerList.clearSelection();

            this.getChild("progressTxt").asTextField.text = `${index}/${count}`;

            let questTextField: fairygui.GTextField = this.getChild("question").asTextField;
            questTextField.text = info.question;

            if (info.type == 1) {
                this._answerList.selectionMode = fairygui.ListSelectionMode.Single;
            } else {
                this._answerList.selectionMode = fairygui.ListSelectionMode.Multiple_SingleClick;
            }
            let answers = ["answerA", "answerB", "answerC", "answerD", "answerE", "answerF", "answerG", "answerH"];
            for (let i = 0; i < answers.length; i++) {
                let answer: string = info[answers[i]];

                let answerTextField = this._answerList.getChildAt(i).asCom.getChild("optionTxt").asTextField;
                if (answer) {
                    answerTextField.text = answer;
                    this._answerList.getChildAt(i).asCom.visible = true;
                } else {
                    this._answerList.getChildAt(i).asCom.visible = false;
                }
            }
        }

        public async open(...param: any[]) {
            super.open(param);

            if (SurveyView.IsComplete) {
                this.getController("page").setSelectedIndex(1);
            }
            
            this.scaleX = 0.5;
            this.scaleY = 0.5;
            await new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 1, scaleY: 1 }, 300, egret.Ease.backOut).call(() => {
                    resolve();
                });
            });

        }

        public async close(...param: any[]) {
            await new Promise<void>(resolve => {
                egret.Tween.get(this).to({ scaleX: 0, scaleY: 0 }, 300, egret.Ease.backIn).call(function () {
                    this.hide();
                    resolve();
                }, this);
            });
        }
    }
}