package com.openew.game.sdk;

import android.app.Activity;
import android.app.Application;
import android.util.Log;

import com.openew.game.sdkcommon.AppCreateListener;
import com.openew.game.sdkcommon.ISDKImpl;
import com.openew.game.sdkcommon.SDKImplBase;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKPayListener;
import com.openew.game.sdkcommon.SDKUser;
import com.openew.launcher.MainActivity;
import com.tencent.smtt.sdk.QbSdk;

/**
 * Created by elliot on 2018/6/25.
 */
public class SDKDefaultImpl extends SDKImplBase implements ISDKImpl {
    @Override
    public void init(Activity context, SDKInitListener lsn) {
        lsn.onInitSuccess();
    }

    public void login(Activity context, Object param, SDKLoginListener lsn) {
        SDKUser user = new SDKUser();
        user.accountLogin = true;
        lsn.onLoginSuccess(user);
    }

    @Override
    public void logout(Activity context) {

    }
    @Override
    public void pay(Activity context, int total, int count, String pid, String sdkParam, SDKPayListener lsn) {
        lsn.onPayFail("In-app Purchase not available now");
    }
    @Override
    public void openChannelCenter(Activity context) {}
}
