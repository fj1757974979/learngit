
class Utils {

    public static camp2Text(camp:Camp): string {
        switch(camp) {
        case Camp.WEI:
            return Core.StringUtils.TEXT(70194);
        case Camp.SHU:
            return Core.StringUtils.TEXT(70195);
        case Camp.WU:
            return Core.StringUtils.TEXT(70196);
        case Camp.HEROS:
            return Core.StringUtils.TEXT(70197);
        default:
            return "";
        }
    }

    public static job2Color(job: any): string {
        switch(job) {
            case Job.UnknowJob:
                return "";
            case Job.YourMajesty:
                return "#cfce75c";
            case Job.Counsellor:
                return "#cfc5c5c";
            case Job.General:
                return "#cfc855c";
            case Job.Prefect:
                return "#cc95cfc";
            case Job.DuWei:
                return "#c5ca4fc";
            case Job.FieldOfficer:
                return "#c5cfc60";
            default :
                return "";
        }
    }
    public static job2Text(job: any, withColor: boolean = false): string {
        switch(job) {
            case Job.UnknowJob:
                return "";
            case Job.YourMajesty:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.TEXT(70346) + "#n";
                } else {
                    return Core.StringUtils.TEXT(70346);
                }
            case Job.Counsellor:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.TEXT(70347) + "#n";
                } else {
                    return Core.StringUtils.TEXT(70347);
                }
            case Job.General:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.TEXT(70348) + "#n";
                } else {
                    return Core.StringUtils.TEXT(70348);
                }
            case Job.Prefect:
                if (withColor) {
                    return Utils.job2Color(job) +Core.StringUtils.TEXT(70349) + "#n";
                } else {
                    return Core.StringUtils.TEXT(70349);
                }
            case Job.DuWei:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.TEXT(70350) + "#n";
                } else {
                    return Core.StringUtils.TEXT(70350);
                }
            case Job.FieldOfficer:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.TEXT(70351) + "#n";
                } else {
                    return Core.StringUtils.TEXT(70351);
                }
            default :
                return "";
        }
    }
    public static job2TextDesc(job: any, withColor: boolean = false): string {
        switch(job) {
            case Job.UnknowJob:
                return "";
            case Job.YourMajesty:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.format("#fdesc,70208({0})#e", Core.StringUtils.TEXT(70346)) + "#n";
                } else {
                    return Core.StringUtils.format("#fdesc,70208({0})#e", Core.StringUtils.TEXT(70346));
                }
            case Job.Counsellor:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.format("#fdesc,70209({0})#e", Core.StringUtils.TEXT(70347)) + "#n";
                } else {
                    return Core.StringUtils.format("#fdesc,70209({0})#e", Core.StringUtils.TEXT(70347));
                }
            case Job.General:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.format("#fdesc,70210({0})#e", Core.StringUtils.TEXT(70348)) + "#n";
                } else {
                    return Core.StringUtils.format("#fdesc,70210({0})#e", Core.StringUtils.TEXT(70348));
                }
            case Job.Prefect:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.format("#fdesc,70211({0})#e", Core.StringUtils.TEXT(70349)) + "#n";
                } else {
                    return Core.StringUtils.format("#fdesc,70211({0})#e", Core.StringUtils.TEXT(70349));
                }
            case Job.DuWei:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.format("#fdesc,70212({0})#e", Core.StringUtils.TEXT(70350)) + "#n";
                } else {
                    return Core.StringUtils.format("#fdesc,70212({0})#e", Core.StringUtils.TEXT(70350));
                }
            case Job.FieldOfficer:
                if (withColor) {
                    return Utils.job2Color(job) + Core.StringUtils.format("#fdesc,70213({0})#e", Core.StringUtils.TEXT(70351)) + "#n";
                } else {
                    return Core.StringUtils.format("#fdesc,70213({0})#e", Core.StringUtils.TEXT(70351));
                }
            default :
                return "";
        }
    }
    public static doubleJob(job1: Job, job2: Job, withColor: boolean = false): string {
        let str = "";
        if (job1 != Job.UnknowJob && job2 != Job.UnknowJob) {
            str = `${Utils.job2TextDesc(job1, withColor)} ${Utils.job2TextDesc(job2, withColor)}`;
        } else {
            str = `${Utils.job2TextDesc(job1, withColor)}${Utils.job2TextDesc(job2, withColor)}`;
        }
        return str;
    }
    public static job2descText(job: Job): string {
        switch(job) {
            case Job.UnknowJob:
                return "";
            case Job.YourMajesty:
                return Core.StringUtils.TEXT(70208);
            case Job.Counsellor:
                return Core.StringUtils.TEXT(70209);
            case Job.General:
                return Core.StringUtils.TEXT(70210);
            case Job.Prefect:
                return Core.StringUtils.TEXT(70211);
            case Job.DuWei:
                return Core.StringUtils.TEXT(70212);
            case Job.FieldOfficer:
                return Core.StringUtils.TEXT(70213);
        }
    }
    public static job2Type(job: Job): JobType {
        switch(job) {
            case Job.UnknowJob:
                return JobType.Null;
            case Job.YourMajesty:
                return JobType.CountryJob;
            case Job.Counsellor:
                return JobType.CountryJob;
            case Job.General:
                return JobType.CountryJob;
            case Job.Prefect:
                return JobType.CityJob;
            case Job.DuWei:
                return JobType.CityJob;
            case Job.FieldOfficer:
                return JobType.CityJob;
        }
    }
    public static warResType2Url(type: WarResType) {
        switch(type) {
            case WarResType.Gold :
                return "common_goldIcon_png";
            case WarResType.Defense :
                return "war_cityHpIcon_png";
            case WarResType.Agriculture :
                return "war_foodBagIcon_png";
            case WarResType.Business :
                return "war_goldBagIcon_png";
            case WarResType.Forage :
                return "war_foodIcon_png";
            case WarResType.Glory :
                return "war_honorIcon_png";
            case WarResType.Contribution:
                return "war_fightIcon_png";
        }
    }
    public static warResType2desc(type: WarResType) {
        switch(type) {
            case WarResType.Gold :
                return Core.StringUtils.TEXT(70207);
            case WarResType.Defense :
                return Core.StringUtils.TEXT(70202);
            case WarResType.Agriculture :
                return Core.StringUtils.format(Core.StringUtils.TEXT(70203), Data.parameter.get("forage_conversion").para_value[0]);
            case WarResType.Business :
                return Core.StringUtils.format(Core.StringUtils.TEXT(70204), Data.parameter.get("gold_conversion").para_value[0]);
            case WarResType.Forage :
                return Core.StringUtils.TEXT(70206);
            case WarResType.Glory :
                return Core.StringUtils.TEXT(70205);
        }
    }
    public static warMsType2Url(type: WarMsType) {
        switch(type) {
            case WarMsType.Build :
                return "war_cityHpIcon_png";
            case WarMsType.Irrigation:
                return "war_foodBagIcon_png";
            case WarMsType.Trade:
                return "war_goldBagIcon_png";
            default:
            return "common_goldIcon_png";
        }
    }
    public static warMsType2WarResType(type: WarMsType) : WarResType {
        switch(type) {
            case WarMsType.Build:
                return WarResType.Defense;
            case WarMsType.Trade:
                return WarResType.Business;
            case WarMsType.Irrigation:
                return WarResType.Agriculture;
            default:
                return null;
        }
    }
    public static warMsTextType2Url(type: WarMsType) {
        switch(type) {
            case WarMsType.Build :
                return "war_buildHpText_png";
            case WarMsType.Irrigation:
                return "war_buildFoodText_png";
            case WarMsType.Trade:
                return "war_buildGoldText_png";
            case WarMsType.Transport:
                return "";
            default:
                return "";
        }
    }
    public static warMsBgType2Url(type: WarMsType) {
        switch(type) {
            case WarMsType.Build :
                return "war_buildHpBg_png";
            case WarMsType.Irrigation:
                return "war_buildFoodBg_png";
            case WarMsType.Trade:
                return "war_buildGoldBg_png";
            case WarMsType.Transport:
                return "war_buildTransBg_png";
            default:
                return "war_buildAddBg_png";
        }
    }
    public static warMsType2text(type: WarMsType) {
        switch(type) {
            case WarMsType.Irrigation:
                return Core.StringUtils.TEXT(70352);
            case WarMsType.Trade:
                return Core.StringUtils.TEXT(70353);
            case WarMsType.Build:
                return Core.StringUtils.TEXT(70354);
            case WarMsType.Transport:
                return Core.StringUtils.TEXT(70355);
            case WarMsType.Dispatch:
                return Core.StringUtils.TEXT(70356);
            default:
                return Core.StringUtils.TEXT(70269);
        }
    }
    public static warMsDesc2text(type: WarMsType) {
        switch(type) {
            case WarMsType.Irrigation:
                return Core.StringUtils.TEXT(70357);
            case WarMsType.Trade:
                return Core.StringUtils.TEXT(70358);
            case WarMsType.Build:
                return Core.StringUtils.TEXT(70359);
            case WarMsType.Transport:
                return Core.StringUtils.TEXT(70360);
            case WarMsType.Dispatch:
                return Core.StringUtils.TEXT(70361);
            default:
                return Core.StringUtils.TEXT(70269);
        }
    }
    public static warTranType2textUrl(type: pb.TransportTypeEnum) {
        switch(type) {
            case pb.TransportTypeEnum.GoldTT:
                return "war_buildAddBg_png";
            case pb.TransportTypeEnum.ForageTT:
                return "war_buildAddBg_png";
            default:
                return "";
        }
    }
    public static warTranType2text(type: pb.TransportTypeEnum) {
        switch(type) {
            case pb.TransportTypeEnum.GoldTT:
                return Core.StringUtils.TEXT(70362);
            case pb.TransportTypeEnum.ForageTT:
                return Core.StringUtils.TEXT(70363);
            default:
                return "";
        }
    }
    //运输时候取得是每移动一步的时间
    public static warMsType2time(type: WarMsType) {
        switch(type) {
            case WarMsType.Irrigation:
                return Data.parameter.get("irrigation_time").para_value[0] * 3600;
            case WarMsType.Trade:
                return Data.parameter.get("trade_time").para_value[0] * 3600;
            case WarMsType.Build:
                return Data.parameter.get("build_time").para_value[0] * 3600;
            case WarMsType.Transport:
                return Data.parameter.get("march_speed").para_value[0] * 3600;
            default:
            return 0;
        }
    }
    public static rankChangeType2Text(type: number): number[] {
        switch(type) {
            case pb.FetchSeasonHandCardReply.ChangeTypeEnum.Fight:
                return [70174, 70177];
            case pb.FetchSeasonHandCardReply.ChangeTypeEnum.Win:
                return [70172, 70175];
            case pb.FetchSeasonHandCardReply.ChangeTypeEnum.Lose:
                return [70173, 70176];
        }
    }

    public static camp2Url(camp:Camp): string {
        switch(camp) {
        case Camp.WEI:
            return "cardpool_weiFlag_png";
        case Camp.SHU:
            return "cardpool_shuFlag_png";
        case Camp.WU:
            return "cardpool_wuFlag_png";
        case Camp.HEROS:
            return "cardpool_qunFlag_png";
        default:
            return "cardpool_weiFlag_png";
        }
    }

    public static resType2Text(resType:ResType): string {
        switch(resType) {
        case ResType.T_WEAP:
            return "武器";
        case ResType.T_HORSE:
            return "马匹";
        case ResType.T_MAT:
            return "辎重";
        case ResType.T_GOLD:
            return "金币";
        case ResType.T_FORAGE:
            return "粮草";
        case ResType.T_MED:
            return "桃";
        case ResType.T_BAN:
            return "绷带";
        case ResType.T_WINE:
            return "酒";
        case ResType.T_BOOK:
            return "书";
        default:
            return "";
        }
    }
    public static priv2descText(priv: Priv): number {
        switch(priv) {
            case Priv.VIP_PRIV:
                return 10700;
            case Priv.TREASURE_ADD_CARD:
                return 10701;
            case Priv.TREASURE_ADD_GOLD:
                return 10702;
            case Priv.REWARD_ADD_TREASURE:
                return 10703;
            case Priv.TREASURE_ADD_ACC_CNT:
                return 10704;
            case Priv.DAILY_ADD_CARD:
                return 10705;
            case Priv.TREASURE_SUB_TIME:
                return 10706;
            case Priv.BATTLE_ADD_GOLD:
                return 10707;
            case Priv.BATTLE_ADD_STAR:
                return 10708;
            case Priv.BATTLE_NOT_SUB_STAR:
                return 10709;
        }
    }

    public static resType2Icon(resType:ResType): string {
        switch(resType) {
        case ResType.T_BAN:
            return "common_ban_png";
        case ResType.T_BOOK:
            return "common_book_png";
        case ResType.T_FORAGE:
            return "common_forage_png";
        case ResType.T_GOLD:
            return "common_goldIcon_png";
        case ResType.T_JADE:
            return "common_jadeIcon_png";
        case ResType.T_BOWLDER:
            return "common_bowlderIcon_png";
        case ResType.T_HORSE:
            return "common_horse_png";
        case ResType.T_MAT:
            return "common_mat_png";
        case ResType.T_MED:
            return "common_med_png";
        case ResType.T_WEAP:
            return "common_weap_png";
        case ResType.T_WINE:
            return "common_wine_png";
        default:
            return "common_book_png";
        }
    }

    public static resType2Texture(resType:ResType): egret.Texture {
        return RES.getRes(Utils.resType2Icon(resType));
    }

    public static resTypePriority(resType:ResType): number {
        switch(resType) {
        case ResType.T_WEAP:
            return 1;
        case ResType.T_HORSE:
            return 0;
        case ResType.T_MAT:
            return 2;
        case ResType.T_GOLD:
            return 6;
        case ResType.T_FORAGE:
            return 4;
        case ResType.T_MED:
            return 4;
        case ResType.T_BAN:
            return 5;
        case ResType.T_WINE:
            return 7;
        case ResType.T_BOOK:
            return 8;
        default:
            return 9;
        }
    }
    public static str2num(str: string) {
        str = str.trim();
        let strNum = parseInt(str);
        if (isNaN(strNum) || str.length <= 0 || str.length != strNum.toString().length) {
            return false;
        }
        return strNum;
    }
    public static async setImageUrlPicture(img: fairygui.GImage, url: string) {
        let texture = await Social.SocialMgr.inst.getTextureByResUrl(url);
        if (texture) {
            let w = img.width;
            let h = img.height;
            img.texture = texture;
            img.width = w;
            img.height = h;
        }
    }

    public static getResolutionDistance() : number {
        return (fairygui.GRoot.inst.getDesignStageHeight() - 800 - window.support.topMargin - window.support.bottomMargin);
    }
}
