package com.openew.game.sdk;

import android.app.Application;
import android.util.Log;

import com.openew.launcher.MainActivity;
import com.tencent.bugly.crashreport.CrashReport;
import com.tencent.smtt.sdk.QbSdk;

public class DefaultApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();

		CrashReport.initCrashReport(getApplicationContext());

        SDKProxy.getInstance().onAppCreate(this);

		//搜集本地tbs内核信息并上报服务器，服务器返回结果决定使用哪个内核。
		QbSdk.PreInitCallback cb = new QbSdk.PreInitCallback() {

			@Override
			public void onViewInitFinished(boolean arg0) {
				if (MainActivity.getInstance() != null) {
					MainActivity.getInstance().startX5();
				}
				// TODO Auto-generated method stub
				//x5內核初始化完成的回调，为true表示x5内核加载成功，否则表示x5内核加载失败，会自动切换到系统内核。
				Log.d("app", " onViewInitFinished is " + arg0);
			}

			@Override
			public void onCoreInitFinished() {
				// TODO Auto-generated method stub
			}
		};
		//x5内核初始化接口
		Log.d("app", "init x5 env");
		QbSdk.initX5Environment(getApplicationContext(),  cb);
		MainActivity.hasPreInit = true;
    }
}
