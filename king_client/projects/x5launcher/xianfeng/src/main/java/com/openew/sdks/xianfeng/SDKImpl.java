package com.openew.sdks.xianfeng;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import android.view.WindowManager;

import com.openew.game.sdkcommon.ISDKImpl;
import com.openew.game.sdkcommon.SDKExitListener;
import com.openew.game.sdkcommon.SDKImplBase;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKPayListener;
import com.openew.game.sdkcommon.SDKUser;
import com.xfsdk.define.OnlineUser;
import com.xfsdk.define.bean.PaymentBean;
import com.xfsdk.interfaces.XFExitListener;
import com.xfsdk.interfaces.XFListener;
import com.xfsdk.sdk.XFSdk;

public class SDKImpl extends SDKImplBase implements ISDKImpl {

    private SDKLoginListener loginLsn = null;
    private SDKPayListener payLsn = null;

    @Override
    public void init(Activity context, final SDKInitListener lsn) {
        XFSdk.getInstance().onCreate(context, 1);
        XFSdk.getInstance().setLoginListener(new XFListener() {
            @Override
            public void onLoginSuccess(OnlineUser onlineUser) {
                if (loginLsn != null) {
                    SDKUser user = new SDKUser();
                    user.token = onlineUser.getToken();
                    user.channelUserID = onlineUser.getUserId();
                    user.loginChannel = "xianfeng";
                    loginLsn.onLoginSuccess(user);
                }
            }

            @Override
            public void onLoginFailed(String s) {
                if (loginLsn != null) {
                    loginLsn.onLoginFail(s);
                }
            }

            @Override
            public void onSdkLogout() {

            }

            @Override
            public void onSdkSwitch() {

            }

            @Override
            public void onPaySuccess(OnlineUser onlineUser) {

            }

            @Override
            public void onPayFailed(String s) {

            }
        });
        lsn.onInitSuccess();
    }

    @Override
    public void login(Activity context, Object param, final SDKLoginListener lsn) {
        loginLsn = lsn;
        XFSdk.getInstance().login();
    }

    @Override
    public void openChannelCenter(Activity context) {
    }

    @Override
    public void logout(Activity context) {
        XFSdk.getInstance().logout();
    }

    @Override
    public void pay(Activity context, int total, int count, String pid, String sdkParam, SDKPayListener lsn) {
        PaymentBean paymentBean = new PaymentBean();
        paymentBean.setAppname(context.getResources().getString(R.string.app_name));
        paymentBean.setExtn("CP自己生成的订单号");
        paymentBean.setGoodsId(pid);
        paymentBean.setGoodsName("商品名称");
        paymentBean.setServerName("服务器名称");
        paymentBean.setServerId("服务器ID");
        paymentBean.setRoleName("角色名称");
        paymentBean.setRoleId("角色ID");
        paymentBean.setRoleGrade("角色等级");
        paymentBean.setUnitPrice(String.format("%s", total * 100)); // 商品单价 （单位：分）
        paymentBean.setCount(count); // 购买数量

        XFSdk.getInstance().pay(paymentBean);
    }

    @Override
    public void onEnterGame(Activity context, String userId, String userName, int level, int serverId, String serverName) {
    }

    @Override
    public void onCreateRole(Activity context, String userId, String userName, int level, int serverId, String serverName) {
    }

    @Override
    public void onLevelUp(Activity context, String userId, String userName, int level, int serverId, String serverName) {
    }

    @Override
    public void showExitDialog(Activity context, final SDKExitListener lsn) {
        XFSdk.getInstance().exit(new XFExitListener() {
            @Override
            public void onSdkExit(boolean b) {
                lsn.onExitSuccess();
            }

            @Override
            public void onNoExiterProvide() {
                lsn.onExitFail();
            }
        });
    }

    @Override
    public void onAppCreate(Application appInst) {

    }

    @Override
    public void onCreate(Activity context) {

    }

    @Override
    public void onStart(Activity context) {
        XFSdk.getInstance().onStart();
    }
    @Override
    public void onStop(Activity context) {
        XFSdk.getInstance().onStop();
    }
    @Override
    public void onDestroy(Activity context) {
        super.onDestroy(context);
        XFSdk.getInstance().onDestroy();
    }
    @Override
    public void onResume(Activity context) {
        XFSdk.getInstance().onResume();
    }
    @Override
    public void onPause(Activity context) {
        XFSdk.getInstance().onPause();
    }
    @Override
    public void onRestart(Activity context) {
        XFSdk.getInstance().onRestart();
    }
    @Override
    public void onNewIntent(Activity context, Intent intent) {
        XFSdk.getInstance().onNewIntent(intent);
    }
    @Override
    public boolean onActivityResult(Activity context, int requestCode, int resultCode, Intent data) {
        XFSdk.getInstance().onActivityResult(requestCode, resultCode, data);
        return super.onActivityResult(context, requestCode, resultCode, data);
    }
    @Override
    public void onConfigurationChanged(Activity context, Configuration newConfig) {
        XFSdk.getInstance().onConfigurationChanged(newConfig);
    }
    @Override
    public void onSaveInstanceState(Activity context, Bundle outState) {
    }
    @Override
    public void onRestoreInstanceState(Activity context, Bundle savedInstanceState) {
    }
    @Override
    public void onWindowFocusChanged(Activity context, boolean hasFocus) {
    }
    @Override
    public void onWindowAttributesChanged(Activity context, WindowManager.LayoutParams params) {
    }
}
