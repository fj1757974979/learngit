module Level {

    class LevelPageChangeAction extends fairygui.ControllerAction {
        private _view:LevelView;
        constructor(view:LevelView) {
            super();
            this._view = view;
        }
        public enter(control: fairygui.Controller) {
            this._view.resetCptBtn();
        }
    }
    export class LevelView extends Core.BaseView {
        private _chapterList: fairygui.GList;
        private _preCptBtn: fairygui.GButton;
        private _nextCptBtn: fairygui.GButton;
        //private _backBtn: fairygui.GButton;
        private _chapterPageCtrl: fairygui.Controller;
        private _renderChapterExecutor: Core.FrameExecutor;
        private _inScroll:boolean = false;

        public initUI() {
            super.initUI();
            //this.adjust(this.getChild("bg"), Core.AdjustType.NO_BORDER);
            this._chapterList = this.getChild("chapterList").asList;
            //this._chapterList.setVirtualAndLoop();
            //this._chapterList.itemRenderer = this._renderChapterList;
            //this._chapterList.callbackThisObj = this;
            this._chapterPageCtrl = this.getController("chapterPage");
            this._chapterPageCtrl.addAction(SoundMgr.inst.playSoundAction("page_mp3", true));
            this._chapterPageCtrl.addAction(new LevelPageChangeAction(this));

            this._chapterList.scrollPane.addEventListener(fairygui.ScrollPane.SCROLL, this.onScroll, this);
            this._chapterList.scrollPane.addEventListener(fairygui.ScrollPane.SCROLL_END, this.onScrollEnd, this);

            let pageNum = LevelMgr.inst.getChapterNum();
            this._chapterList.numItems = pageNum;
            for (let i = 0; i < pageNum; i++) {
                this._chapterPageCtrl.addPage(i.toString());
            }
            this._preCptBtn = this.getChild("preCptBtn").asButton;
            this._nextCptBtn = this.getChild("nextCptBtn").asButton;
            this._chapterPageCtrl.selectedIndex = 0;
            //this._backBtn = this.getChild("backBtn").asButton;

            this._preCptBtn.addClickListener(this._preCptOnClick, this);
            this._nextCptBtn.addClickListener(this._nextCptOnClick, this);
            this.onScrollEnd();
            //this.resetCptBtn();
            //this._backBtn.addClickListener(this._backOnClick, this);
        }
        public onScroll() {
            if (this._inScroll) return;
            this._inScroll = true;

            this._forEachChapter((idx: number, chapter: ChapterItem) => {
                chapter.visible = true;
            });
        }

        public onScrollEnd() {
            this._inScroll = false;

            this._forEachChapter((idx: number, chapter: ChapterItem) => {
                let visible:boolean = (idx == this._chapterPageCtrl.selectedIndex);  
                chapter.visible = visible;
            });
        }

        public resetCptBtn() {
            this._preCptBtn.visible = true;
            this._nextCptBtn.visible = true;
            if (this._chapterPageCtrl.selectedIndex == 0) {
                this._preCptBtn.visible = false;
            } else if(this._chapterPageCtrl.selectedIndex == this._chapterPageCtrl.pageCount - 1) {
                this._nextCptBtn.visible = false;
            }
            
        }
        public async open(...param: any[]) {
            super.open(...param);
            await this.refresh();
            //this.resetCptBtn();
        }

        public async refresh() {
            if (this._renderChapterExecutor) {
                this._renderChapterExecutor.cancel();
                this._renderChapterExecutor = null;
            }
            
            this._forEachChapter((idx: number, chapter: ChapterItem) => {
                chapter.clearLevel();
            });


            let page = -1;
            let pageChapter: Array<any>;
            let allChapter: Array<Array<any>> = [];
            this._forEachChapter((idx: number, chapter: ChapterItem) => {
                let chapterObj = LevelMgr.inst.getChapter(idx + 1);
                if (!chapterObj) {
                    return;
                }

                chapter.setName(chapterObj.id, chapterObj.name);
                if (page < 0 && (!chapterObj.isClear() || chapter.canOpenTreasure())) {
                    page = idx;
                    pageChapter = [chapter, chapterObj];
                } else {
                    allChapter.push([chapter, chapterObj]);
                }
            });

            this._renderChapterExecutor = new Core.FrameExecutor();
            if (pageChapter) {
                this._renderChapterExecutor.regist(this._renderChapter, this, pageChapter[0], pageChapter[1]);
            }
            allChapter.forEach(chapterArgs => {
                this._renderChapterExecutor.regist(this._renderChapter, this, chapterArgs[0], chapterArgs[1]);
            });
            this._renderChapterExecutor.execute();

            if (page > 0) {
                this._chapterPageCtrl.setSelectedIndex(page);
                this._chapterList.scrollToView(page, true);
            }
        }
    

        public async close(...param: any[]) {
            super.close(...param);
            this._renderChapterExecutor.cancel();
            this._renderChapterExecutor = null;
            this._forEachChapter((idx: number, chapter: ChapterItem) => {
                chapter.clearLevel();
            });
        }

        private _renderChapter(chapter: ChapterItem, chapterObj: Chapter) {
            chapter.setLevels(chapterObj.levelObjs);
        }

        private _forEachChapter(callback: Function) {
            for (let i = 0; i < this._chapterList.numItems; i++) {
                let chapterItem = this._chapterList.getChildAt(i);
                chapterItem.height = this.height - 76;
                if (chapterItem) {
                    callback.call(this, i, <ChapterItem>chapterItem);
                }
            }
        }

        private _preCptOnClick() {
            let idx = this._chapterPageCtrl.selectedIndex - 1;
            idx = idx < 0 ? 0 : idx;
            this._chapterPageCtrl.selectedIndex = idx;
        }

        private _nextCptOnClick() {
            let idx = this._chapterPageCtrl.selectedIndex + 1;
            idx = idx > this._chapterPageCtrl.pageCount - 1 ? this._chapterPageCtrl.pageCount - 1 : idx;
            this._chapterPageCtrl.selectedIndex = idx;
        }

        private _backOnClick() {
            Core.ViewManager.inst.open(ViewName.home);
            Core.ViewManager.inst.closeView(this);
        }
    }

}
