module War {

    export class BaseJob {

        public get type(): number {
            return Job.UnknowJob;
        }

        public get name(): string {
            return Utils.job2Text(this.type);
        }
        
        public isCountryJob(): boolean {
            return false;
        }

        public isCityJob(): boolean {
            return false;
        }

        public isSameJob(job: Job): boolean {
            return this.type == job;
        }

        public async enter() {

        }

        public async leave() {

        }

        public canNotice(): boolean {
            return false;
        }

        public canKickMember(): boolean {
            return false;
        }
        public canSetPrefect(): boolean {
            return false;
        }
        public canSetOtherCityJob(): boolean {
            return false;
        }
        public canJoinCityJob(): boolean {
            return false;
        }
        public canSetBuild(): boolean {
            return false;
        }
        public canSetCampFlag(): boolean {
            return false;
        }
        public canAppointToJob(job: Job): boolean {
            return false;
        }
    }

    export class UnkownJob extends BaseJob {
        public canAppointToJob(job: Job): boolean {
            return true;
        }
    }

//     enum Job {
//         UnknowJob = 0,
//         YourMajesty = 1,  // 主公
//         Counsellor = 2,   // 军师
//         General = 3,      // 中郎将
//         Prefect = 4,      // 太守
//         DuWei = 5,        // 都尉
//         FieldOfficer = 6, // 校尉
// }

    export class CountryJob extends BaseJob {
        
        public isCountryJob(): boolean {
            return true;
        }
    }

    export class YourMajestyJob extends CountryJob {
        public get type(): number {
            return Job.YourMajesty;
        }
        public canSetPrefect(): boolean {
            return true;
        }
        public canJoinCityJob(): boolean {
            return true;
        }
        public canSetCampFlag(): boolean {
            return true;
        }
    }

    export class CounsellorJob extends CountryJob {
        public get type(): number {
            return Job.Counsellor;
        }
        public canAppointToJob(job: Job): boolean {
            if (this.type == job) {
                return false;
            }
            return true;
        }
    }

    export class GeneralJob extends CountryJob {
        public get type(): number {
            return Job.General;
        }
        public canAppointToJob(job: Job): boolean {
            if (this.type == job) {
                return false;
            }
            return true;
        }
    }

    export class CityJob extends BaseJob {
        public isCityJob(): boolean {
            return true;
        }

        public canKickMember(): boolean {
            return true;
        }
        public canJoinCityJob(): boolean {
            return true;
        }
        //
        // public canSetBuild() {
        //     return this._job == Job.Prefect;
        // }
        // public canSetWarCmd() {
        //     return this._job == Job.Prefect;
        // }
        // public canSetJob(job: Job) {
        //     if (job == Job.Prefect) {
        //         return false;
        //     } else {
        //         return this._job == Job.Prefect;
        //     }
        // }
        // public canChangeToJob(job: Job) {
        //     if (job == this._job) {
        //         return false;
        //     }
        //     if (job == Job.Prefect && this._job != Job.UnknowJob) {
        //         return false;
        //     }
        //     return true;
        // }
    }

    export class PrefectJob extends CityJob {
        public get type(): number {
            return Job.Prefect;
        }
        public canSetOtherCityJob() {
            return true;
        }

        public canNotice(): boolean {
            return true;
        }
        public canSetBuild(): boolean {
            return true;
        }
    }

    export class DuWeiJob extends CityJob {
        public get type(): number {
            return Job.DuWei;
        }
        public canAppointToJob(job: Job): boolean {
            if (job == Job.DuWei) {
                return false;
            }
            return true;
        }
    }

    export class FieldOfficerJob extends CityJob {
        public get type(): number {
            return Job.FieldOfficer;
        }
        public canAppointToJob(job: Job): boolean {
            if (job == Job.FieldOfficer) {
                return false;
            }
            return true;
        }
    }

    export class NationalEmployee {
        protected _countryJobObj: BaseJob;
        protected _cityJobObj: BaseJob;
        protected _player: MyWarPlayer;

        public constructor() {
            this._countryJobObj = null;
            this._cityJobObj = null;
        }

        public get cityJob(): BaseJob {
            return this._cityJobObj;
        }

        public get countryJob(): BaseJob {
            return this._countryJobObj;
        }

        public async setCountryJob(job: Job) {
            if (this._countryJobObj && this._countryJobObj.isSameJob(job)) {
                return;
            }
            if (this._countryJobObj) {
                await this._countryJobObj.leave();
            }
            this._countryJobObj = newJob(job);
            if (this._countryJobObj) {
                await this._countryJobObj.enter();
            }
        }

        public async setCityJob(job: Job) {
            if (this._cityJobObj && this._cityJobObj.isSameJob(job)) {
                return;
            }
            if (this._cityJobObj) {
                await this._cityJobObj.leave();
            }
            this._cityJobObj = newJob(job);
            if (this._cityJobObj) {
                await this._cityJobObj.enter();
            }
        }

        public hasOfficialTitle(): boolean {
            return this.hasCountryOfficialTitle() || this.hasCityOfficialTitle();
        }

        public hasCountryOfficialTitle(): boolean {
            return this._countryJobObj && this._countryJobObj.type != Job.UnknowJob
        }

        public hasCityOfficialTitle(): boolean {
            return this._cityJobObj && this._cityJobObj.type != Job.UnknowJob;
        }

        public canKickMember(): boolean {
            return this._cityJobObj.canKickMember();
        }

        public canNotice(): boolean {
            return this._cityJobObj.canNotice();
        }
        public canSurrender(): boolean {
            return this._cityJobObj.isSameJob(Job.Prefect) && !this._countryJobObj.isSameJob(Job.YourMajesty);
        }
        public canAutocephaly(): boolean {
            return this._cityJobObj.isSameJob(Job.Prefect) && !this._countryJobObj.isSameJob(Job.YourMajesty);
        }
        public hasSameJob(job: Job): boolean {
            return this._cityJobObj.isSameJob(job) || this._countryJobObj.isSameJob(job);
        }
        public canSetPrefect() {
            return this._countryJobObj.canSetPrefect();
        }
        public canSetOtherCityJob() {
            return this._cityJobObj.canSetOtherCityJob();
        }
        public canAppointToJob(job: Job): boolean {
            let type = Utils.job2Type(job);
            if (type == JobType.CityJob) {
                return this._cityJobObj.canAppointToJob(job);
            } else if (type == JobType.CountryJob) {
                return this._countryJobObj.canAppointToJob(job);
            }
            return false;
        }
        public canJoinCityJob() {
            return this._cityJobObj.canJoinCityJob() || this._countryJobObj.canJoinCityJob();
        }
        public canSetBuild() {
            return this._cityJobObj.canSetBuild();
        }
        public canSetCampFlag() {
            return this._countryJobObj.canSetCampFlag();
        }
        public doubleJobName(bool: boolean): string {
            return Utils.doubleJob(this._countryJobObj.type, this._cityJobObj.type, bool);
        }
    }

    function newJob(job: Job): BaseJob {
        switch(job) {
            case Job.UnknowJob:
                return new UnkownJob();
            case Job.YourMajesty:
                return new YourMajestyJob();
            case Job.Counsellor:
                return new CounsellorJob();
            case Job.General:
                return new GeneralJob();
            case Job.Prefect:
                return new PrefectJob();
            case Job.DuWei:
                return new DuWeiJob();
            case Job.FieldOfficer:
                return new FieldOfficerJob();
            default:
                console.error("can't general job obj for type ", job);
                return null;
        }
    }
}