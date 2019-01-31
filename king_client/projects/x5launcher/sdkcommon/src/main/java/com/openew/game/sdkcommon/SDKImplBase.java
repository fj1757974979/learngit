package com.openew.game.sdkcommon;

import android.app.ActionBar;
import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.view.ViewGroup;
import android.view.WindowManager;

/**
 * Created by elliot on 2018/6/25.
 */
public class SDKImplBase {
    public void init(Activity context, SDKInitListener lsn) {
        lsn.onInitSuccess();
    }
    public void login(Activity context, Object param, SDKLoginListener lsn) {}
    public void logout(Activity context) {}
    public void queryProduct(String productIds, SDKQueryProductListener lsn) {
        lsn.onFinishQueryProduct(null);
    }
    public void pay(Activity context, int total, int count, String pid, String sdkParam, SDKPayListener lsn) {}
    public void openChannelCenter(Activity context) {}
    public void showExitDialog(Activity context, SDKExitListener lsn) {
        lsn.onExitSuccess();
    }
    public void onEnterGame(Activity context, String userId, String userName, int level, int serverId, String serverName) {}
    public void onCreateRole(Activity context, String userId, String userName, int level, int serverId, String serverName) {}
    public void onLevelUp(Activity context, String userId, String userName, int level, int serverId, String serverName) {}

    public void onAppCreate(Application appInst) {}
    public void onCreate(Activity context) {}
    public void onStart(Activity context) {}
    public void onStop(Activity context) {}
    public void onDestroy(Activity context) {}
    public void onResume(Activity context) {}
    public void onPause(Activity context) {}
    public void onRestart(Activity context) {}
    public void onNewIntent(Activity context, Intent intent) {}
    public boolean onActivityResult(Activity context, int requestCode, int resultCode, Intent data) {return false;}
    public void onConfigurationChanged(Activity context, Configuration newConfig) {}
    public void onSaveInstanceState(Activity context, Bundle outState) {}
    public void onRestoreInstanceState(Activity context, Bundle savedInstanceState) {}
    public void onWindowFocusChanged(Activity context, boolean hasFocus) {}
    public void onWindowAttributesChanged(Activity context, WindowManager.LayoutParams params) {}
    public void shareVideo(Activity context, Uri videoFileUri, SDKShareListener lsn) {
        lsn.onShareCompleted(false);
    }
    public void shareLink(Activity context, String title, String link, SDKShareListener lsn) {
        lsn.onShareCompleted(false);
    }

    public static ISDKImpl impInstance = null;
    public static IApplicationCreateProxy appCreateProxy = null;
}
