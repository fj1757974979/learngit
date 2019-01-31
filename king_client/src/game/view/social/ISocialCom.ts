module Social {

	export interface ISocialCom {
		onChosen(b: boolean): Promise<boolean>;
		refresh(): Promise<void>;

	}
}