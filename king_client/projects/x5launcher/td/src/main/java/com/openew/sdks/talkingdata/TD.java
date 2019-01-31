package com.openew.sdks.talkingdata;

import android.content.Context;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import com.tendcloud.tenddata.TDGAAccount;
import com.tendcloud.tenddata.TDGAItem;
import com.tendcloud.tenddata.TDGAMission;
import com.tendcloud.tenddata.TalkingDataGA;

public class TD {

    private static TDGAAccount _account = null;

    public static void init(Context context, String appId, String channelId) {
        TalkingDataGA.init(context, appId, channelId);
    }

    public static void setAccount(JSONObject param) {
        try {
            TDGAAccount account = TDGAAccount.setAccount(param.getString("accountId"));
            account.setAccountName(param.getString("accountName"));
            String loginChannel = param.getString("loginChannel");
            if (loginChannel.equals("facebook")) {
                account.setAccountType(TDGAAccount.AccountType.TYPE1);
            } else if (loginChannel.equals("google")) {
                account.setAccountType(TDGAAccount.AccountType.TYPE2);
            } else {
                account.setAccountType(TDGAAccount.AccountType.REGISTERED);
            }
            account.setLevel(param.getInt("level"));
            account.setGameServer(param.getString("gameServer"));
            TD._account = account;
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void onMissionBegin(JSONObject param) {
        try {
            String mission = param.getString("mission");
            TDGAMission.onBegin(mission);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void onMissionCompleted(JSONObject param) {
        try {
            String mission = param.getString("mission");
            TDGAMission.onCompleted(mission);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void onMissionFailed(JSONObject param) {
        try {
            String mission = param.getString("mission");
            String reason = param.getString("reason");
            TDGAMission.onFailed(mission, reason);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void setLevel(JSONObject param) {
        try {
            if (TD._account != null) {
                int level = param.getInt("level");
                TD._account.setLevel(level);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void onItemPurchase(JSONObject param) {
        try {
            String item = param.getString("item");
            int number = param.getInt("itemNumber");
            int price = param.getInt("priceInVirtualCurrency");
            TDGAItem.onPurchase(item, number, (double)price);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void onItemUse(JSONObject param) {
        try {
            String item = param.getString("item");
            int number = param.getInt("itemNumber");
            TDGAItem.onUse(item, number);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private static HashMap<String, Object> jsonToMap(JSONObject obj) throws JSONException {
        java.util.HashMap<String, Object> map = new HashMap();
        Iterator it = obj.keys();
        while(it.hasNext()) {
            String key = (String)it.next();
            Object value = obj.get(key);
            if (value instanceof JSONObject) {
                map = TD.jsonToMap((JSONObject)value);
            } else {
                map.put(key, value);
            }
        }
        return map;
    }

    public static void onEvent(JSONObject param) {
        try {
            String event = param.getString("name");
            JSONObject data = param.getJSONObject("data");
            java.util.Map<String, Object> map = TD.jsonToMap(data);
            TalkingDataGA.onEvent(event, map);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
