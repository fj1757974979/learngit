package com.openew.game.sdk;

import android.app.ActionBar;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.res.Configuration;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.ViewGroup;
import android.view.WindowManager;

import com.openew.game.sdkcommon.ISDKImpl;
import com.openew.game.sdkcommon.SDKExitListener;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;

/**
 * Created by elliot on 2018/6/25.
 */
public class SDKProxy {

    private static SDKProxy instance = null;
    private ISDKImpl sdkImpl;

    public static SDKProxy getInstance() {
        if (SDKProxy.instance == null) {
            SDKProxy.instance = new SDKProxy();
        }
        return SDKProxy.instance;
    }

    public SDKProxy() {
        sdkImpl = null;
    }

    public void login(final Activity context, final Object param, final SDKLoginListener lsn) {
        if (sdkImpl != null) {
            new Handler(context.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    sdkImpl.login(context, param, lsn);
                }
            });
        }
    }

    public void logout(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.logout(context);
        }
    }
    public void pay(Activity context, int total, int count, String pid, String sdkParam) {
        if (sdkImpl != null) {
            sdkImpl.pay(context, total, count, pid, sdkParam);
        }
    }

    public void init(final Activity context, final SDKInitListener lsn) {
        try {
            ApplicationInfo info = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            String sdkType = info.metaData.getString("sdkType");
            if (sdkType.equals("HuoShu")) {
                sdkImpl = new com.openew.sdks.huoshu.SDKImpl();
            } else {
                sdkImpl = new SDKDefaultImpl();
            }
            new Handler(context.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    sdkImpl.init(context, lsn);
                }
            });

        } catch (PackageManager.NameNotFoundException e) {
            Log.e("sdk", "sdk type meta not found");
        }
    }

    public void showExitDialog(final Activity context, final SDKExitListener lsn) {
        new Handler(context.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                sdkImpl.showExitDialog(context, lsn);
            }
        });
    }

    public void onEnterGame(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        if (sdkImpl != null) {
            sdkImpl.onEnterGame(context, userId, userName, level, serverId, serverName);
        }
    }

    public void onCreateRole(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        if (sdkImpl != null) {
            sdkImpl.onCreateRole(context, userId, userName, level, serverId, serverName);
        }
    }

    public void onLevelUp(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        if (sdkImpl != null) {
            sdkImpl.onLevelUp(context, userId, userName, level, serverId, serverName);
        }
    }

    public void onStart(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.onStart(context);
        }
    }

    public void onStop(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.onStop(context);
        }
    }

    public void onDestroy(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.onDestroy(context);
        }
    }

    public void onResume(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.onResume(context);
        }
    }

    public void onPause(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.onPause(context);
        }
    }

    public void onRestart(Activity context) {
        if (sdkImpl != null) {
            sdkImpl.onRestart(context);
        }
    }

    public void onNewIntent(Activity context, Intent intent) {
        if (sdkImpl != null) {
            sdkImpl.onNewIntent(context, intent);
        }
    }

    public void onActivityResult(Activity context, int requestCode, int resultCode, Intent data) {
        if (sdkImpl != null) {
            sdkImpl.onActivityResult(context, requestCode, resultCode, data);
        }
    }

    public void onConfigurationChanged(Activity context, Configuration newConfig) {
        if (sdkImpl != null) {
            sdkImpl.onConfigurationChanged(context, newConfig);
        }
    }

    public void onSaveInstanceState(Activity context, Bundle outState) {
        if (sdkImpl != null) {
            sdkImpl.onSaveInstanceState(context, outState);
        }
    }

    public void onRestoreInstanceState(Activity context, Bundle savedInstanceState) {
        if (sdkImpl != null) {
            sdkImpl.onRestoreInstanceState(context, savedInstanceState);
        }
    }

    public void onWindowFocusChanged(Activity context, boolean hasFocus) {
        if (sdkImpl != null) {
            sdkImpl.onWindowFocusChanged(context, hasFocus);
        }
    }

    public void onWindowAttributesChanged(Activity context, WindowManager.LayoutParams params) {
        if (sdkImpl != null) {
            sdkImpl.onWindowAttributesChanged(context, params);
        }
    }
}
