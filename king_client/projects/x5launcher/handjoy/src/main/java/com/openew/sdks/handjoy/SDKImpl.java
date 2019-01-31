package com.openew.sdks.handjoy;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;

import com.android.vending.billing.IInAppBillingService;
import com.facebook.AccessToken;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.Profile;
import com.facebook.ProfileTracker;
import com.facebook.login.LoginBehavior;
import com.facebook.login.LoginManager;
import com.facebook.login.LoginResult;
import com.facebook.share.Sharer;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.model.ShareVideo;
import com.facebook.share.model.ShareVideoContent;
import com.facebook.share.widget.ShareDialog;
import com.openew.game.sdkcommon.ISDKImpl;
import com.openew.game.sdkcommon.SDKExitListener;
import com.openew.game.sdkcommon.SDKImplBase;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKPayListener;
import com.openew.game.sdkcommon.SDKPayResult;
import com.openew.game.sdkcommon.SDKQueryProductListener;
import com.openew.game.sdkcommon.SDKShareListener;
import com.openew.game.sdkcommon.SDKUser;
import com.facebook.FacebookSdk;
import com.facebook.appevents.AppEventsLogger;
import com.openew.sdks.googleplay.ads.AppFlyersWrapper;
import com.openew.sdks.googleplay.iab.IabHelper;
import com.openew.sdks.googleplay.iab.IabResult;
import com.openew.sdks.googleplay.iab.Inventory;
import com.openew.sdks.googleplay.iab.Purchase;
import com.openew.sdks.googleplay.iab.SkuDetails;
import com.openew.sdks.googleplay.signin.SignInAccount;
import com.openew.sdks.googleplay.signin.SignInHelper;
import com.openew.sdks.googleplay.signin.SignInListener;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

/**
 * Created by elliot on 2018/10/25.
 */

public class SDKImpl extends SDKImplBase implements ISDKImpl {

    private CallbackManager callbackManager;
    public ProfileTracker profileTracker;
    private SDKLoginListener loginLsn;
    private SDKPayListener payLsn;
    private SDKShareListener shareLsn;
    private IabHelper mHelper;
    private String TAG = "LzdHandJoy";
    private int RC_REQUEST = 100001;
    private ShareDialog shareDialog;
    private SignInHelper mGoogleSignInHelper;
    private AppFlyersWrapper afWrapper;
    private HashMap<String, SkuDetails> skuDetailInfos = new HashMap<>();

    @Override
    public void init(Activity context, final SDKInitListener lsn) {
        lsn.onInitSuccess();
    }

    @Override
    public void login(Activity context, Object param, final SDKLoginListener lsn) {
        String loginType;
        try {
            JSONObject jsonParam = new JSONObject((String)param);
            loginType = jsonParam.getString("loginType");
        } catch (JSONException e) {
            e.printStackTrace();
            loginType = "facebook";
        }

        if (loginType.equals("facebook")) {
            AccessToken accessToken = AccessToken.getCurrentAccessToken();
            if (accessToken != null && !accessToken.isExpired()) {
                SDKUser user = new SDKUser();
                user.token = accessToken.getToken();
                user.channelUserID = accessToken.getUserId();
                user.loginChannel = "facebook";
                lsn.onLoginSuccess(user);
                return;
            }
            loginLsn = lsn;
            LoginManager.getInstance().setLoginBehavior(LoginBehavior.WEB_ONLY);
            LoginManager.getInstance().logInWithReadPermissions(context, Arrays.asList("public_profile"));
        } else if (loginType.equals("google")) {
            mGoogleSignInHelper.signIn(new SignInListener() {
                @Override
                public void onSignInSuccess(SignInAccount account) {
                    SDKUser user = new SDKUser();
                    user.token = account.token;
                    user.channelUserID = account.userId;
                    user.loginChannel = "google";
                    lsn.onLoginSuccess(user);
                }

                @Override
                public void onSignInFail(String reason) {
                    lsn.onLoginFail(reason);
                }
            });
        } else {
            lsn.onLoginFail("Error Login Type");
        }
    }

    @Override
    public void openChannelCenter(Activity context) {
    }

    @Override
    public void logout(Activity context) {

    }

    @Override
    public void queryProduct(String productIds, final SDKQueryProductListener lsn) {
        if (mHelper == null) {
            lsn.onFinishQueryProduct(null);
        } else {
            try {
                final JSONArray pids = new JSONArray(productIds);
                List<String> skus = new ArrayList();
                for (int i = 0; i < pids.length(); ++ i) {
                    skus.add(pids.get(i).toString());
                }
                //Log.d(TAG, "Prepare to query product, skus: " + skus);
                mHelper.queryInventoryAsync(true, skus, new IabHelper.QueryInventoryFinishedListener() {
                    @Override
                    public void onQueryInventoryFinished(IabResult result, Inventory inv) {
                        Log.d(TAG, "Query inventory finished.");

                        if (result.isFailure()) {
                            Log.e(TAG, "Failed to query inventory: " + result);
                            return;
                        }

                        Log.d(TAG, "Query inventory was successful.");
                        //Log.d(TAG, "Sku details: " + inv.toString());

                        try {
                            List infos = new ArrayList<List<String>>();
                            for (int i = 0; i < pids.length(); ++i) {
                                SkuDetails details = inv.getSkuDetails(pids.get(i).toString());
                                if (details != null) {
                                    List info = new ArrayList<String>();
                                    info.add(details.getSku());
                                    info.add(details.getPrice());
                                    info.add(details.getCurrency());
                                    info.add(String.format("%d", details.getPriceAmount()));
                                    infos.add(info);

                                    skuDetailInfos.put(details.getSku(), details);
                                }
                                // TODO 如果已拥有但未消耗，则消耗
                            }
                            JSONArray obj = new JSONArray(infos);
                            lsn.onFinishQueryProduct(obj);
                        } catch (JSONException e) {
                            e.printStackTrace();
                            lsn.onFinishQueryProduct(null);
                        }
                    }
                });

            } catch (JSONException e) {
                e.printStackTrace();
                lsn.onFinishQueryProduct(null);
            }

        }
    }

    @Override
    public void pay(Activity context, int total, int count, String pid, String sdkParam, SDKPayListener lsn) {
        if (mHelper != null) {
            payLsn = lsn;
            mHelper.launchPurchaseFlow(context, pid, RC_REQUEST, mPurchaseFinishedListener, sdkParam);
        } else {
            lsn.onPayFail("SDK not initialized");
        }
    }

    IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = new IabHelper.OnIabPurchaseFinishedListener() {
        @Override
        public void onIabPurchaseFinished(IabResult result, Purchase purchase) {
            Log.d(TAG, "Purchase finished: " + result); // + ", purchase: " + purchase);

            if (mHelper == null) return;

            if (result.isFailure()) {
                payLsn.onPayFail(result.getMessage());
            } else {
                mHelper.consumeAsync(purchase, mConsumeFinishedListener);
            }
        }
    };

    IabHelper.OnConsumeFinishedListener mConsumeFinishedListener = new IabHelper.OnConsumeFinishedListener() {
        @Override
        public void onConsumeFinished(Purchase purchase, IabResult result) {
            Log.d(TAG, "Consumption finished."); // Purchase: " + purchase + ", result: " + result);

            if (mHelper == null) return;

            if (result.isSuccess()) {
                try {
                    String purchaseData = purchase.getOriginalJson();
                    String purchaseSign = purchase.getSignature();
                    SDKPayResult payInfo = new SDKPayResult();
                    payInfo.pid = purchase.getSku();
                    payInfo.googlePayData = new JSONObject(purchaseData);
                    payInfo.paySign = purchaseSign;
                    //Log.d(TAG, "Call payListener with result: " + payInfo.toString());
                    if (payLsn != null) {
                        payLsn.onPaySuccess(payInfo);
                    }
                    SkuDetails details = skuDetailInfos.get(purchase.getSku());
                    if (details != null) {
                        afWrapper.onPayment(details.getSku(), details.getPriceAmount()/1000000, details.getCurrency());
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                    if (payLsn != null) {
                        payLsn.onPayFail(e.getMessage());
                    }
                }
            } else {
                if (payLsn != null) {
                    payLsn.onPayFail(result.getMessage());
                }
            }
        }
    };

    @Override
    public void onEnterGame(Activity context, String userId, String userName, int level, int serverId, String serverName) {
        afWrapper.onEnterGame(userId);
    }

    @Override
    public void onCreateRole(Activity context, String userId, String userName, int level, int serverId, String serverName) {
    }

    @Override
    public void onLevelUp(Activity context, String userId, String userName, int level, int serverId, String serverName) {
    }

    @Override
    public void showExitDialog(Activity context, final SDKExitListener lsn) {
		lsn.onExitSuccess();
    }

    @Override
    public void onAppCreate(Application appInst) {
        Log.d(TAG, "onAppCreate");
        afWrapper = new AppFlyersWrapper();
        afWrapper.init(appInst, "RThnuB74b7fC7jyxpkU7sb");
    }

    @Override
    public void onCreate(Activity context) {
        super.onCreate(context);
        FacebookSdk.sdkInitialize(context.getApplicationContext());
        AppEventsLogger.activateApp(context);
        callbackManager = CallbackManager.Factory.create();
        profileTracker = new ProfileTracker() {
            @Override
            protected void onCurrentProfileChanged(Profile oldProfile, Profile currentProfile) {
                onFacebookLogin();
            }
        };
        LoginManager.getInstance().registerCallback(callbackManager, new FacebookCallback<LoginResult>() {
            @Override
            public void onSuccess(LoginResult loginResult) {
                // 将会产生配置变化的事件，调用profileTracker的回调，进入onFacebookLogin()
            }

            @Override
            public void onCancel() {
                if (loginLsn != null) {
                    loginLsn.onLoginFail("Login Cancel");
                }
            }

            @Override
            public void onError(FacebookException error) {
                if (loginLsn != null) {
                    loginLsn.onLoginFail(error.getLocalizedMessage());
                }
            }
        });
        String base64EncodedPublicKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAgN8kCwQMXe59knh6SzdL56gl2hMYH9BudVqQmvzqFkKFNYD2Fe7MLJ6Zj4+2WlJsLAs/8kDvHduYsxlPy8drdE8og6PicoYF3LZcwOfE1FiidrW2cWbtvaznO5MX9mCyEdsnqDy699uD7rYPyut7HnMps8DMhSAucBDJ1eNFLg93/m35Tev6u3EzsXlnmJGTC29L723Tbznw1vKd+3r1k8FyWa8RlmpnEhvsuURur7c2AB7JfBTXOynzBR6Qq8I04Bpcxf6qZPHUk5N9ifHwQMHuNZpyPW5YO3/3tBSGjTgfImGb+CaIGKoKcMP+CIHF64NFqClJQge0mNvBgWsYLwIDAQAB";
        mHelper = new IabHelper(context, base64EncodedPublicKey);
        mHelper.enableDebugLogging(true, TAG);
        mHelper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
            @Override
            public void onIabSetupFinished(IabResult result) {
                Log.d(TAG, "Setup finished");

                if (!result.isSuccess()) {
                    Log.e(TAG, "Problem setting up in-app billing: " + result);
                    mHelper = null;
                    return;
                }

                if (mHelper == null) return;

                Log.d(TAG, "Setup successful.");
//                mHelper.queryInventoryAsync(mGotInventoryListener);
            }
        });

        shareDialog = new ShareDialog(context);
        shareDialog.registerCallback(callbackManager, new FacebookCallback<Sharer.Result>() {
            @Override
            public void onSuccess(Sharer.Result result) {
                if (shareLsn != null) {
                    shareLsn.onShareCompleted(true);
                    shareLsn = null;
                }
            }
            @Override
            public void onCancel() {
                if (shareLsn != null) {
                    shareLsn.onShareCompleted(false);
                    shareLsn = null;
                }
            }
            @Override
            public void onError(FacebookException error) {
                Log.e(TAG, error.toString());
                if (shareLsn != null) {
                    shareLsn.onShareCompleted(false);
                    shareLsn = null;
                }
            }
        });

        try {
            mGoogleSignInHelper = new SignInHelper();
            mGoogleSignInHelper.initGooglePlus(context);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

//    IabHelper.QueryInventoryFinishedListener mGotInventoryListener = new IabHelper.QueryInventoryFinishedListener() {
//        @Override
//        public void onQueryInventoryFinished(IabResult result, Inventory inventory) {
//            Log.d(TAG, "Query inventory finished.");
//
//            if (mHelper == null) return;
//
//            if (result.isFailure()) {
//                Log.e(TAG, "Failed to query inventory: " + result);
//                return;
//            }
//
//            Log.d(TAG, "Query inventory was successful.");
//
//            // TODO inventory包含所有已购买的商品
//        }
//    };

    private void onFacebookLogin() {
        Profile currentProfile = Profile.getCurrentProfile();
        AccessToken accessToken = AccessToken.getCurrentAccessToken();
        if (currentProfile != null && accessToken != null) {
            SDKUser user = new SDKUser();
            user.token = accessToken.getToken();
            user.channelUserID = accessToken.getUserId();
            user.loginChannel = "facebook";
            loginLsn.onLoginSuccess(user);
        } else {
            loginLsn.onLoginFail("Login Fail");
        }
    }

    @Override
    public void onStart(Activity context) {
    }
    @Override
    public void onStop(Activity context) {
    }
    @Override
    public void onDestroy(Activity context) {
//        LoginManager.getInstance().logOut();
        super.onDestroy(context);
    }
    @Override
    public void onResume(Activity context) {
    }
    @Override
    public void onPause(Activity context) {
    }
    @Override
    public void onRestart(Activity context) {
    }
    @Override
    public void onNewIntent(Activity context, Intent intent) {
    }
    @Override
    public boolean onActivityResult(Activity context, int requestCode, int resultCode, Intent data) {
        super.onActivityResult(context, requestCode, resultCode, data);

        mGoogleSignInHelper.onActivityResult(requestCode, resultCode, data);

        callbackManager.onActivityResult(requestCode, resultCode, data);

        if (mHelper == null) return false;

        if (!mHelper.handleActivityResult(requestCode, resultCode, data)) {
            return false;
        } else {
            return true;
        }
    }
    @Override
    public void onConfigurationChanged(Activity context, Configuration newConfig) {
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

    @Override
    public void shareVideo(Activity context, Uri videoFileUri, SDKShareListener lsn) {
        Log.d(TAG, "shareVideo " + videoFileUri.toString());
        if (ShareDialog.canShow(ShareVideoContent.class)) {
            Log.d(TAG, "building ShareVideo");
            ShareVideo video = new ShareVideo.Builder()
                    .setLocalUrl(videoFileUri)
                    .build();
            Log.d(TAG, "build ShareVideo done");
            Log.d(TAG, "building ShareVideoContent");
            ShareVideoContent content = new ShareVideoContent.Builder()
                    .setVideo(video)
                    .build();
            Log.d(TAG, "building ShareVideoContent done");
            shareLsn = lsn;
            shareDialog.show(content, ShareDialog.Mode.AUTOMATIC);
        } else {
            Log.d(TAG, "ShareDialog can't show ShareVideoContent");
            lsn.onShareCompleted(false);
        }
    }

    @Override
    public void shareLink(Activity context, String title, String link, SDKShareListener lsn) {
        if (ShareDialog.canShow(ShareLinkContent.class)) {
            ShareLinkContent content = new ShareLinkContent.Builder()
                    .setContentUrl(Uri.parse(link))
                    .setContentTitle(title)
                    .build();
            shareLsn = lsn;
            shareDialog.show(content);
        } else {
            lsn.onShareCompleted(false);
        }
    }
}
