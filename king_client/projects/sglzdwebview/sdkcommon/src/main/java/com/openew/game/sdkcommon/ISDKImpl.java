package com.openew.game.sdkcommon;

import android.app.ActionBar;
import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import android.view.ViewGroup;
import android.view.WindowManager;

/**
 * Created by elliot on 2018/6/25.
 */
public interface ISDKImpl {
    void init(Activity context, SDKInitListener lsn);
    void login(Activity context, Object param, SDKLoginListener lsn);
    void logout(Activity context);
    void pay(Activity context, int total, int count, String pid, String sdkParam);
    void openChannelCenter(Activity context);
    void showExitDialog(Activity context, SDKExitListener lsn);
    void onEnterGame(Activity context, String userId, String userName, int level, int serverId, String serverName);
    void onCreateRole(Activity context, String userId, String userName, int level, int serverId, String serverName);
    void onLevelUp(Activity context, String userId, String userName, int level, int serverId, String serverName);

    void onStart(Activity context);
    void onStop(Activity context);
    void onDestroy(Activity context);
    void onResume(Activity context);
    void onPause(Activity context);
    void onRestart(Activity context);
    void onNewIntent(Activity context, Intent intent);
    void onActivityResult(Activity context, int requestCode, int resultCode, Intent data);
    void onConfigurationChanged(Activity context, Configuration newConfig);
    void onSaveInstanceState(Activity context, Bundle outState);
    void onRestoreInstanceState(Activity context, Bundle savedInstanceState);
    void onWindowFocusChanged(Activity context, boolean hasFocus);
    void onWindowAttributesChanged(Activity context, WindowManager.LayoutParams params);
}
