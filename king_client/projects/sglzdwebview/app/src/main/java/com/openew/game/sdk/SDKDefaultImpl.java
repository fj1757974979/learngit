package com.openew.game.sdk;

import android.app.Activity;

import com.openew.game.sdkcommon.ISDKImpl;
import com.openew.game.sdkcommon.SDKImplBase;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKUser;

/**
 * Created by elliot on 2018/6/25.
 */
public class SDKDefaultImpl extends SDKImplBase implements ISDKImpl {
    public void init(Activity context, SDKInitListener lsn) {
        lsn.onInitSuccess();
    }

    public void login(Activity context, Object param, SDKLoginListener lsn) {
        SDKUser user = new SDKUser();
        user.accountLogin = true;
        lsn.onLoginSuccess(user);
    }


    public void logout(Activity context) {

    }

    public void pay(Activity context, int total, int count, String pid, String sdkParam) {

    }

    public void openChannelCenter(Activity context) {}
}
