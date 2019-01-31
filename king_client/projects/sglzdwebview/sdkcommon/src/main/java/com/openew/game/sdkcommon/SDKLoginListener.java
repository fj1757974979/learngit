package com.openew.game.sdkcommon;

/**
 * Created by elliot on 2018/6/25.
 */
abstract public class SDKLoginListener {
    public void onLoginSuccess(SDKUser user) {}
    public void onLoginFail(String reason) {}
}
