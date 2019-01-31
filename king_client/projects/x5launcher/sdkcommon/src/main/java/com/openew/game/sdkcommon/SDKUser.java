package com.openew.game.sdkcommon;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by elliot on 2018/6/25.
 */
public class SDKUser {
    public String channelID;
    public String channelUserID;
    public String token;
    public String channelUserName;
    public String timeStamp;
    public String userType;
    public String tdChannelID;
    public boolean accountLogin;
    public String loginChannel;

    public SDKUser() {
        channelID = "";
        channelUserID = "";
        token = "";
        channelUserName = "";
        timeStamp = "";
        userType = "";
        tdChannelID = "";
        accountLogin = false;
        loginChannel = "";
    }

    public String toString() {

        JSONObject obj = toJson();
        if (obj != null) {
            return obj.toString();
        } else {
            return "";
        }

    }

    public JSONObject toJson() {
        try {
            JSONObject obj = new JSONObject();
            obj.put("channelID", channelID);
            obj.put("channelUserID", channelUserID);
            obj.put("token", token);
            obj.put("channelUserName", channelUserName);
            obj.put("timeStamp", timeStamp);
            obj.put("userType", userType);
            obj.put("accountLogin", accountLogin);
            obj.put("tdChannelID", tdChannelID);
            obj.put("loginChannel", loginChannel);
            return obj;
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }
    }
}
