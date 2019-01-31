module Core {

    export enum AdjustType {
        NO_BORDER,
        EXACT_FIT,
        EXCEPT_MARGIN,
    }

    export interface IBaseView {
        name: string

        isInit():boolean

        isShow():boolean

        addToParent(parent?:fairygui.GComponent):void

        removeFromParent():void

        initUI():void

        setVisible(flag:boolean):void

        open(...param:any[]):Promise<any>

        close(...param:any[]):Promise<any>

        destroy()

        getNode(nodeName:string): fairygui.GObject

        adjust(display:fairygui.GObject, adjustType:AdjustType)
    }

}