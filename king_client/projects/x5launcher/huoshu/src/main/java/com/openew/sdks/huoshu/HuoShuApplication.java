package com.openew.sdks.huoshu;

import android.util.Log;

import com.gzyouai.publicsdk.application.PoolSDKApplication;
import com.openew.game.sdkcommon.SDKImplBase;

public class HuoShuApplication extends PoolSDKApplication {
    @Override
    public void onCreate() {
        super.onCreate();
//        SDKImplBase.appCreateProxy.onAppCreate(this);
    }
}
