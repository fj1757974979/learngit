module War {

    export class WarPlayer extends PlayerStatusDelegate {

        // private _centerJob: CenterJob;
        // private _locationJob: LocationJob;

        // public constructor() {
        //     super();
        //     this.setDelegateHost(this);
        // }

        // public setJob(centerJob: number, locationJob: number) {
        //     this._centerJob = new CenterJob(centerJob);
        //     this._locationJob = new LocationJob(locationJob);
        // }
        // public canSetJob(job: Job) {
        //     let jobType = Utils.job2Type(job);
        //     if (jobType == JobType.CityJob) {
        //         return this._locationJob.canSetJob(job);
        //     } else if (jobType == JobType.CountryJob) {
        //         return this._centerJob.canSetJob(job);
        //     }
        // }
        // public canChangeToJob(job: Job) {
        //     let jobType = Utils.job2Type(job);
        //     if (jobType == JobType.CityJob) {
        //         return this._locationJob.canChangeToJob(job);
        //     } else if (jobType == JobType.CountryJob) {
        //         return this._centerJob.canChangeToJob(job);
        //     }
        // }
    }
}