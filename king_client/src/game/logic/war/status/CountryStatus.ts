// TypeScript file
module War {
    // export enum CountryStatusName {
    //     ST_ALIVE = 0,          // 存活
    //     ST_DEFEAT = 1,         // 消灭
    // }

    export class CountryStatusBase extends WarStatusBase {
        protected _country: Country;

        public constructor(host: any) {
            super(host);
            this._country = <Country>host;
        }

        public get host(): Country {
            return this._country;
        }
    }

    export class CountryAlive extends CountryStatusBase {
        public get name(): number {
            return CountryStatusName.ST_ALIVE;
        }
    }

    export class CountryDefeat extends CountryStatusBase {
        public get name(): number {
            return CountryStatusName.ST_DEFEAT;
        }

        public async enter(...param: any[]) {
            let name = this._country.countryName;
            Core.TipsUtils.showTipsFromCenter(Core.StringUtils.format("#cr{0}#n势力被消灭", name));
        }
    }

    export class CountryStatusDelegate extends WarStatusDelegateBase {
        protected _country: Country;

        public setDelegateHost(host: any) {
            this._country = <Country>host;
            super.setDelegateHost(host);
        }

        protected initStatus() {
            this._statusObjs.setValue(CountryStatusName.ST_ALIVE, new CountryAlive(this._country));
            this._statusObjs.setValue(CountryStatusName.ST_DEFEAT, new CountryDefeat(this._country));
        }

        public async changeStatus(stName: number, time: number = -1, ...param: any[]) {
            super.changeStatus(stName, time, ...param);
            console.log(`Country ${this._country.countryName} Status change to `, stName);
        }
    }
}