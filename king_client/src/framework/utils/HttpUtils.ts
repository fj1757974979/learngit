module Core {

    export class HttpUtils {

        public static getQueryVariable(variable:string):string {
            let query = window.location.search.substring(1);
            let vars = query.split("&");
            for (var i=0; i<vars.length; i++) {
                let pair = vars[i].split("=");
                if(pair[0] == variable) {
                    return pair[1];
                }
            }
            return null;
        }

        public static post(_url:string, params:Collection.Dictionary<string, string>=null): Promise<any> {
            let request = new egret.HttpRequest();
            request.responseType = egret.HttpResponseType.TEXT;
            //request.responseType = "document";
            request.open(_url, egret.HttpMethod.POST);
            request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            
            let body = "";
            if (params) {
                let paramsPairs = [];
                params.forEach((k, v) => {
                    paramsPairs.push(`${k}=${v}`);
                });
                body = paramsPairs.join("&");
            }
            request.send(body);

            return new Promise<any>((reslove, reject) => {
                request.once(egret.Event.COMPLETE, (event:egret.Event)=>{
                    let req = <egret.HttpRequest>event.currentTarget;
                    reslove(req.response);
                }, this);

                request.once(egret.IOErrorEvent.IO_ERROR, (event:egret.IOErrorEvent)=>{
                    reject("get error : " + event.data);
                }, this);
            });
            //request.addEventListener(egret.ProgressEvent.PROGRESS,this.onPostProgress,this);
        }

    }

}
