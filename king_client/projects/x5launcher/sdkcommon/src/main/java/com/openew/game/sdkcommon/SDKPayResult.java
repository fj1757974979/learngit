package com.openew.game.sdkcommon;

import org.json.JSONException;
import org.json.JSONObject;

public class SDKPayResult {
    public String pid;
    public String paySign;
    public JSONObject googlePayData;
    public String payCurrency;
    public int payMoney;

    public SDKPayResult() {
        pid = "";
        paySign = "";
        payCurrency = "CNY";
        googlePayData = null;
        payMoney = 0;
    }

    public JSONObject toJson() {
        try {
            JSONObject obj = new JSONObject();
            obj.put("pid", pid);
            obj.put("paySign", paySign);
            if (googlePayData != null) {
                obj.put("googlePayData", googlePayData);
            }
            return obj;
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }

    public String toString() {
        JSONObject obj = toJson();
        if (obj != null) {
            return obj.toString();
        } else {
            return null;
        }
    }
}
