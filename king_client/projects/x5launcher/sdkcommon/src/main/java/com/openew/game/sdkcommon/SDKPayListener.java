package com.openew.game.sdkcommon;

abstract public class SDKPayListener {
    public void onPaySuccess(SDKPayResult result) {}
    public void onPayFail(String reason) {}

}
