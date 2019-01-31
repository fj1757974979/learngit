

// 字符串解析
// #(skill,skillid)
// #(desc,skillid)
// #(hero,heroid)

const skillRegx = /#\(\s*skill\s*,\s*(\d+)\s*\)/g;
const descRegx = /#\(\s*desc\s*,\s*(\d+)\s*\)/g;
const heroRegx = /#\(\s*hero\s*,\s*(\d+)\s*\)/g;

// event:skill,skillid
// event:hero,cardid,level
// event:desc,skillid
let lastSkillid:number;
async function htmlClickCallback(event:egret.TextEvent): Promise<fairygui.GComponent> {
    let args = event.text.split(",");
    let type = args[0];
    let id = parseInt(args[1]);
    // console.log(`click link ${event.text} ${type} ${id}`);
    if (type == "skill" || type == "desc") {
        // console.log(`htmlClickCallback ${lastSkillid} ${id}`);
        if (lastSkillid == id) {
            lastSkillid = null;
            return;
        }
        lastSkillid = id;
        let skillRes = Data.skill.get(id);
        let desc = "<font strokecolor=0x0 stroke=2><b><i>" + skillRes.name + ":</i> </b></font>" + parse2html(skillRes.desTra) + "";
        let com = fairygui.UIPackage.createObject(PkgName.cards, ViewName.skillInfo).asCom;
        com.getChild("skillDescTxt").asRichTextField.text = desc;
        Core.LayerManager.inst.maskLayer.addChild(com);
        // fairygui.GRoot.inst.addChild(com);
        // this.addChild(com);

        let onTouch;
        onTouch = function() {
            fairygui.GTimers.inst.callDelay(100, function(currentId) {
                //console.log(`onTouchEnd ${lastSkillid} ${currentId}`);
                if (lastSkillid == currentId) lastSkillid = null;
            }, null, id);
            com.parent.removeChild(com);
            egret.MainContext.instance.stage.removeEventListener(egret.TouchEvent.TOUCH_END, onTouch, com);
        }

        egret.MainContext.instance.stage.addEventListener(egret.TouchEvent.TOUCH_END, onTouch, com);
        com.center();
        return com;
    } else if (type == "hero") {
        //console.log(args[2]);
        if (Core.ViewManager.inst.getView("htmlCardView") == null) {
            let cardInfoWnd = new CardPool.OtherCardInfo();
            cardInfoWnd.contentPane = fairygui.UIPackage.createObject(PkgName.cardpool, ViewName.cardInfoOther).asCom;
            Core.ViewManager.inst.register("htmlCardView", cardInfoWnd);
            cardInfoWnd.setViewMode();
        } else {
            await Core.ViewManager.inst.close("htmlCardView");
        }

        let level = 5;
        //console.log(args[2]);
        if (args[2] != "level") {            
            level = parseInt(args[2]);
        } 
        let data = CardPool.CardPoolMgr.inst.getCardData(id, level);
        if (!data) {
            for (let i=5; i>0; i--) {
                if (!data) {
                    data = CardPool.CardPoolMgr.inst.getCardData(id, i);
                } 
                if (data) break;
            }
        }
        
        let cardObj:CardPool.Card = new CardPool.Card(data);
        cardObj.skin = args[3];
        await Core.ViewManager.inst.open("htmlCardView", cardObj);
        (Core.ViewManager.inst.getView("htmlCardView") as CardPool.CardInfoWnd).setViewMode();
        return null;
    }
}

function parse2html(str:String, level:number = null) {
    str = str.replace(skillRegx, function (match, skill):string {
        let id = parseInt(skill);
        let skillRes = Data.skill.get(id);
        let skillname:string = skillRes.name.replace("n", "");
        return `<a href="event:skill,${skill}">[<u>${skillname}</u>]</a>`;
    });
    str = str.replace(descRegx, function(match, skill):string {
        let id = parseInt(skill);
        let skillRes = Data.skill.get(id);
        let skillname:string = skillRes.name.replace("n", "");
        return `<a href="event:desc,${skill}"><u><i>${skillname}</i></u></a>`;
    });
    str = str.replace(heroRegx, function (match, hero):string {
        let id = parseInt(hero);
        let heroInfo = CardPool.CardPoolMgr.inst.getCardData(id, level || 5);
        if (!heroInfo) {
            heroInfo = CardPool.CardPoolMgr.inst.getCardData(id, 1);
        }
        let heroname:string=heroInfo.name.replace(/#c\w(.*)#n/, "$1");
        return `<a href="event:hero,${hero},level,skin">[<u><i>${heroname}</i></u>]</a>`;
    });
    return str;
}