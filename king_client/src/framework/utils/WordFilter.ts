module Core {

    class TreeNode {
        private _data: Collection.Dictionary<string, TreeNode>;
    
        // 是否是敏感词的词尾字，敏感词树的叶子节点必然是词尾字，父节点不一定是
        public isEnd: boolean;
        public parent: TreeNode;
        public value: string;
    
        constructor() {
            this._data = new Collection.Dictionary<string, TreeNode>();
            this.isEnd = false;
        }
    
        public getChild(name: string): TreeNode {
            return this._data.getValue(name);
        }
    
        public addChild(char: string): TreeNode {
            let node = new TreeNode();
            this._data.setValue(char, node);
            node.value = char;
            node.parent = this;
            return node;
        }
    
        public getFullWord(): string {
            let rt: string = this.value;
            let node: TreeNode = this.parent;
            while (node) {
                rt = node.value + rt;
                node = node.parent;
            }
            return rt;
        }

        public get isLeaf(): boolean {
            return this._data.size() <= 0;
        }
    }


    export class WordFilter {
        private static _inst: WordFilter;
        private _treeRoot: TreeNode;

        public static get inst(): WordFilter {
            if (!this._inst) {
                this._inst = new WordFilter();
            }
            return this._inst;
        }
        
        public registerWords(words: Array<string>) {
            this._treeRoot = new TreeNode();
            this._treeRoot.value = "";
            for (let word of words) {
                let len = word.length;
                let currentBranch = this._treeRoot;
                for (let c = 0; c < len; c++) {
                    let char = word.charAt(c);
                    let tmp = currentBranch.getChild(char);
                    if (tmp) {
                        currentBranch = tmp;
                    } else {
                        currentBranch = currentBranch.addChild(char);
                    }
                }
                currentBranch.isEnd = true;
            }
        }
                    
        /**
         * 判断是否包含敏感词 
        */
        public containsDirtyWords(word: string): boolean {
            let char: string;
            let curTree = this._treeRoot;
            let childTree: TreeNode;
    
            let c: number = 0;  // 循环索引
            let endIndex: number = 0;  // 词尾索引
            let headIndex: number = -1;  // 敏感词词首索引
            while (c < word.length) {
                char = word.charAt(c);
                childTree = curTree.getChild(char);
                if (childTree) {
                   
                    if (childTree.isEnd) {
                        return true;
                    }
                    if (headIndex == -1) {
                        headIndex = c;
                    }
                    curTree = childTree;
                    c++;

                } else {
                    
                    if (curTree != this._treeRoot) {
                        //如果之前有遍历到敏感词非词尾，匹配部分未完全匹配，则设置循环索引为敏感词词首索引
                        c = headIndex;
                        headIndex = -1;
                    }
                    curTree = this._treeRoot;
                    c++;
                }
            }
                        
            return false;
        }
    }

}