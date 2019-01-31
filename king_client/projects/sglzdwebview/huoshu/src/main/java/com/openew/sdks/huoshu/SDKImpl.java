package com.openew.sdks.huoshu;

import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;

import com.gzyouai.fengniao.sdk.framework.PoolExitDialogListener;
import com.gzyouai.fengniao.sdk.framework.PoolLoginInfo;
import com.gzyouai.fengniao.sdk.framework.PoolLoginListener;
import com.gzyouai.fengniao.sdk.framework.PoolRoleInfo;
import com.gzyouai.fengniao.sdk.framework.PoolRoleListener;
import com.gzyouai.fengniao.sdk.framework.PoolSDKCallBackListener;
import com.gzyouai.fengniao.sdk.framework.PoolSDKCode;
import com.gzyouai.fengniao.sdk.framework.PoolSdkHelper;
import com.openew.game.sdkcommon.ISDKImpl;
import com.openew.game.sdkcommon.SDKExitListener;
import com.openew.game.sdkcommon.SDKImplBase;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKUser;

/**
 * Created by elliot on 2018/6/25.
 */

public class SDKImpl extends SDKImplBase implements ISDKImpl {

    @Override
    public void init(Activity context, final SDKInitListener lsn) {
        PoolSdkHelper.init(context, new PoolSDKCallBackListener() {
            @Override
            public void poolSdkCallBack(int code, String msg) {
                switch (code) {
                    case PoolSDKCode.POOLSDK_INIT_SUCCESS:
                        lsn.onInitSuccess();
                        break;
                    case PoolSDKCode.POOLSDK_INIT_FAIL:
                        lsn.onInitFail();
                        break;
                    default:
                        break;
                }
            }
        });
    }

    @Override
    public void login(Activity context, Object param, final SDKLoginListener lsn) {
        PoolSdkHelper.login("", new PoolLoginListener() {
            @Override
            public void onLoginSuccess(PoolLoginInfo poolLoginInfo) {
                SDKUser user = new SDKUser();
                user.userType = poolLoginInfo.getUserType();
                user.timeStamp = poolLoginInfo.getTimestamp();
                user.token = poolLoginInfo.getServerSign();
                user.channelUserID = poolLoginInfo.getOpenID();
                user.channelUserName = poolLoginInfo.getUsername();
                lsn.onLoginSuccess(user);
            }

            @Override
            public void onLoginFailed(String errorMsg) {
                lsn.onLoginFail(errorMsg);
            }
        });
    }

    @Override
    public void openChannelCenter(Activity context) {
        if (PoolSdkHelper.hasChannelCenter()) {
            PoolSdkHelper.openChannelCenter();
        }
    }

    @Override
    public void logout(Activity context) {

    }

    @Override
    public void pay(Activity context, int total, int count, String pid, String sdkParam) {

    }

    @Override
    public void onEnterGame(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        PoolRoleInfo poolRoleInfo = new PoolRoleInfo();
        poolRoleInfo.setRoleID(userId);
        poolRoleInfo.setRoleLevel(String.format("%d", level));
        poolRoleInfo.setRoleSex("0");
        poolRoleInfo.setRoleName(userName);
        poolRoleInfo.setServerID(String.format("%d", serverId));
        poolRoleInfo.setServerName(serverName);
        poolRoleInfo.setCustom("");
        poolRoleInfo.setRoleCTime(System.currentTimeMillis()/1000);//角色创建时（秒）
        poolRoleInfo.setPartyName("");
        poolRoleInfo.setRoleType("");//角色类型
        poolRoleInfo.setRoleChangeTime(System.currentTimeMillis()/1000);//角色更新时间
        poolRoleInfo.setVipLevel("0");//vip等级
        poolRoleInfo.setDiamond("0");//余额
        poolRoleInfo.setMoneyType("");//商品单位
        poolRoleInfo.setCallType(PoolRoleInfo.Type_EnterGame);//进入游戏

        PoolSdkHelper.submitRoleData(poolRoleInfo, new PoolRoleListener() {
            @Override
            public void onRoleDataSuccess(String s) {
                Log.d("onEnterGame", "submit info success");
            }
        });
    }

    @Override
    public void onCreateRole(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        PoolRoleInfo poolRoleInfo = new PoolRoleInfo();
        poolRoleInfo.setRoleID(userId);
        poolRoleInfo.setRoleLevel(String.format("%d", level));
        poolRoleInfo.setRoleSex("0");
        poolRoleInfo.setRoleName(userName);
        poolRoleInfo.setServerID(String.format("%d", serverId));
        poolRoleInfo.setServerName(serverName);
        poolRoleInfo.setCustom("");
        poolRoleInfo.setRoleCTime(System.currentTimeMillis()/1000);//角色创建时（秒）
        poolRoleInfo.setPartyName("");
        poolRoleInfo.setRoleType("");//角色类型
        poolRoleInfo.setRoleChangeTime(System.currentTimeMillis()/1000);//角色更新时间
        poolRoleInfo.setVipLevel("0");//vip等级
        poolRoleInfo.setDiamond("0");//余额
        poolRoleInfo.setMoneyType("");//商品单位
        poolRoleInfo.setCallType(PoolRoleInfo.Type_CreateRole);//进入游戏

        PoolSdkHelper.submitRoleData(poolRoleInfo, new PoolRoleListener() {
            @Override
            public void onRoleDataSuccess(String s) {
                Log.d("onCreateRole", "submit info success");
            }
        });
    }

    @Override
    public void onLevelUp(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        PoolRoleInfo poolRoleInfo = new PoolRoleInfo();
        poolRoleInfo.setRoleID(userId);
        poolRoleInfo.setRoleLevel(String.format("%d", level));
        poolRoleInfo.setRoleSex("0");
        poolRoleInfo.setRoleName(userName);
        poolRoleInfo.setServerID(String.format("%d", serverId));
        poolRoleInfo.setServerName(serverName);
        poolRoleInfo.setCustom("");
        poolRoleInfo.setRoleCTime(System.currentTimeMillis()/1000);//角色创建时（秒）
        poolRoleInfo.setPartyName("");
        poolRoleInfo.setRoleType("");//角色类型
        poolRoleInfo.setRoleChangeTime(System.currentTimeMillis()/1000);//角色更新时间
        poolRoleInfo.setVipLevel("0");//vip等级
        poolRoleInfo.setDiamond("0");//余额
        poolRoleInfo.setMoneyType("");//商品单位
        poolRoleInfo.setCallType(PoolRoleInfo.Type_RoleUpgrade);//进入游戏

        PoolSdkHelper.submitRoleData(poolRoleInfo, new PoolRoleListener() {
            @Override
            public void onRoleDataSuccess(String s) {
                Log.d("onLevelUp", "submit info success");
            }
        });
    }

    @Override
    public void showExitDialog(Activity context, final SDKExitListener lsn) {
        if (PoolSdkHelper.hasExitDialog()) {
            PoolSdkHelper.showExitDialog(new PoolExitDialogListener() {
                @Override
                public void onDialogResult(int code, String msg) {
                    switch (code) {
                        case PoolSDKCode.EXIT_SUCCESS:
                            lsn.onExitSuccess();
                            break;
                        case PoolSDKCode.EXIT_CANCEL:
                            lsn.onExitFail();
                            break;
                        default:
                            lsn.onExitFail();
                            break;
                    }
                }
            });
        } else {
            lsn.onExitSuccess();
        }
    }

    @Override
    public void onStart(Activity context) {
        PoolSdkHelper.onStart();
    }
    @Override
    public void onStop(Activity context) {
        PoolSdkHelper.onStop();
    }
    @Override
    public void onDestroy(Activity context) {
        PoolSdkHelper.onDestroy();
    }
    @Override
    public void onResume(Activity context) {
        PoolSdkHelper.onResume();
    }
    @Override
    public void onPause(Activity context) {
        PoolSdkHelper.onPause();
    }
    @Override
    public void onRestart(Activity context) {
        PoolSdkHelper.onRestart();
    }
    @Override
    public void onNewIntent(Activity context, Intent intent) {
        PoolSdkHelper.onNewIntent(intent);
    }
    @Override
    public void onActivityResult(Activity context, int requestCode, int resultCode, Intent data) {
        PoolSdkHelper.onActivityResult(requestCode, resultCode, data);
    }
    @Override
    public void onConfigurationChanged(Activity context, Configuration newConfig) {
        PoolSdkHelper.onConfigurationChanged(newConfig);
    }
    @Override
    public void onSaveInstanceState(Activity context, Bundle outState) {
        PoolSdkHelper.onSaveInstanceState(outState);
    }
    @Override
    public void onRestoreInstanceState(Activity context, Bundle savedInstanceState) {
        PoolSdkHelper.onRestoreInstanceState(savedInstanceState);
    }
    @Override
    public void onWindowFocusChanged(Activity context, boolean hasFocus) {
        PoolSdkHelper.onWindowFocusChanged(hasFocus);
    }
    @Override
    public void onWindowAttributesChanged(Activity context, WindowManager.LayoutParams params) {
        PoolSdkHelper.onWindowAttributesChanged(params);
    }
}
