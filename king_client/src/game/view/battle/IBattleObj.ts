module Battle {

    export interface IBattleObj {
        objId: number
        playEffect(effectId:string | number, playType:number, visible?:boolean, targetCount?:number, value?:number): Promise<void>
    }

}