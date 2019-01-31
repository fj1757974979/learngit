module War {

    export class Const {
        public static job2Desc(job: Job): string {
            return Const.job2BattleRwdDesc(job) + ", " + Const.job2GoldRwdDesc(job);
        }

        public static job2BattleRwdDesc(job: Job): string {
            switch(job) {
                case Job.UnknowJob:
                    return "";
                case Job.YourMajesty:
                    return Core.StringUtils.format(Core.StringUtils.TEXT(70336), Data.parameter.get("king_per").para_value[0] * 100);
                case Job.Counsellor:
                    return Core.StringUtils.format(Core.StringUtils.TEXT(70336), Data.parameter.get("junshi_per").para_value[0] * 100);
                case Job.General:
                    return Core.StringUtils.format(Core.StringUtils.TEXT(70336), Data.parameter.get("zhonglangjiang_per").para_value[0] * 100);
                case Job.Prefect:
                    return Core.StringUtils.format(Core.StringUtils.TEXT(70337), Data.parameter.get("taishou_per").para_value[0] * 100);
                case Job.DuWei:
                    return Core.StringUtils.format(Core.StringUtils.TEXT(70337), Data.parameter.get("duwei_per").para_value[0] * 100);
                case Job.FieldOfficer:
                    return Core.StringUtils.format(Core.StringUtils.TEXT(70337), Data.parameter.get("xiaowei_per").para_value[0] * 100);
            }
        }

        public static job2GoldRwdDesc(job: Job): string {
            switch(job) {
            case Job.UnknowJob:
                return "";
            case Job.YourMajesty:
                return Core.StringUtils.format(Core.StringUtils.TEXT(70338), Data.parameter.get("king_salary").para_value[0] * 100);
            case Job.Counsellor:
                return Core.StringUtils.format(Core.StringUtils.TEXT(70338), Data.parameter.get("junshi_salary").para_value[0] * 100);
            case Job.General:
                return Core.StringUtils.format(Core.StringUtils.TEXT(70338), Data.parameter.get("zhonglangjiang_salary").para_value[0] * 100);
            case Job.Prefect:
                return Core.StringUtils.format(Core.StringUtils.TEXT(70339), Data.parameter.get("taishou_salary").para_value[0] * 100);
            case Job.DuWei:
                return Core.StringUtils.format(Core.StringUtils.TEXT(70339), Data.parameter.get("duwei_salary").para_value[0] * 100);
            case Job.FieldOfficer:
                return Core.StringUtils.format(Core.StringUtils.TEXT(70339), Data.parameter.get("xiaowei_salary").para_value[0] * 100);
            }
        }
    }

}