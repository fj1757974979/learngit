package com.openew.launcher;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.widget.Toast;

import com.openew.game.sdk.SDKProxy;
import com.openew.game.sdkcommon.SDKShareListener;
import com.openew.game.utils.ScreenRecorder;
import com.openew.sdks.talkingdata.TD;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKPayListener;
import com.openew.game.sdkcommon.SDKPayResult;
import com.openew.game.sdkcommon.SDKQueryProductListener;
import com.openew.game.sdkcommon.SDKUser;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class NativeCall {
    private MainActivity mContext;
    private String TAG = "callNative";

    NativeCall(MainActivity c) {
        mContext = c;
    }
    @JavascriptInterface
    public void callNative(String s) {
        Log.d(TAG, s);
        try {
            JSONObject obj = new JSONObject(s);
            String msg = obj.getString("msg");
            if (msg.equals("login")) {
                SDKProxy.getInstance().login(mContext, obj.getString("args"),
                        new SDKLoginListener() {
                            @Override
                            public void onLoginSuccess(SDKUser user) {
                                try {
                                    ApplicationInfo info = mContext.getPackageManager().getApplicationInfo(mContext.getPackageName(), PackageManager.GET_META_DATA);
                                    user.tdChannelID = info.metaData.getString("tdChannelID");
                                    JSONObject json = new JSONObject();
                                    json.put("msg", "loginDone");

                                    JSONObject args = new JSONObject();
                                    args.put("success", true);
                                    args.put("info", user.toJson());

                                    json.put("args", args);

                                    String msg = json.toString();
                                    Log.d("login", "result " + msg);
                                    mContext.callJS(msg);
                                } catch (Exception e) {
                                    Log.e("login", e.getLocalizedMessage());
                                    e.printStackTrace();
                                }
                            }

                            @Override
                            public void onLoginFail(String reason) {
                                try {
                                    JSONObject json = new JSONObject();
                                    json.put("msg", "loginDone");

                                    JSONObject args = new JSONObject();
                                    args.put("success", false);
                                    args.put("reason", reason);

                                    json.put("args", args);

                                    String msg = json.toString();
                                    Log.d("login", "result " + msg);
                                    mContext.callJS(msg);
                                } catch (JSONException e) {
                                    e.printStackTrace();
                                }
                            }
                        });
            } else if (msg.equals("initSDK")) {
            } else if (msg.equals("getTDChannelID")) {
                try {
                    JSONObject json = new JSONObject();
                    json.put("msg", "getTDChannelID");
                    JSONObject args = new JSONObject();

                    ApplicationInfo info = mContext.getPackageManager().getApplicationInfo(mContext.getPackageName(), PackageManager.GET_META_DATA);
                    String tdChannelID = info.metaData.getString("tdChannelID");
                    args.put("tdChannelID", tdChannelID);
                    args.put("native", true);

                    json.put("args", args);

                    String returnmsg = json.toString();
                    Log.d("login", "result " + returnmsg);
                    mContext.callJS(returnmsg);
                } catch (Exception e) {
                    Log.e("tdChannel", e.getLocalizedMessage());
                    e.printStackTrace();
                }
            } else if (msg.equals("onEnterGame")) {
                JSONObject args = obj.getJSONObject("args");
                SDKProxy.getInstance().onEnterGame(mContext,
                        args.getString("userId"), args.getString("userName"),
                        args.getInt("level"),
                        args.getInt("serverId"),
                        args.getString("serverName"));
            } else if (msg.equals("onCreateRole")) {
                JSONObject args = obj.getJSONObject("args");
                SDKProxy.getInstance().onCreateRole(mContext,
                        args.getString("userId"), args.getString("userName"),
                        args.getInt("level"),
                        args.getInt("serverId"),
                        args.getString("serverName"));
            } else if (msg.equals("onLevelUp")) {
                JSONObject args = obj.getJSONObject("args");
                SDKProxy.getInstance().onLevelUp(mContext,
                        args.getString("userId"), args.getString("userName"),
                        args.getInt("level"),
                        args.getInt("serverId"),
                        args.getString("serverName"));
            } else if (msg.equals("getLocale")) {
                String country = mContext.getResources().getConfiguration().locale.getCountry();
                String language = mContext.getResources().getConfiguration().locale.getLanguage();
                JSONObject json = new JSONObject();
                json.put("msg", "getLocale");
                JSONObject args = new JSONObject();
                args.put("country", country);
                args.put("language", language);
                json.put("args", args);
                String returnMsg = json.toString();
                mContext.callJS(returnMsg);
            } else if (msg.equals("startPay")) {
                JSONObject args = obj.getJSONObject("args");
                String pid = args.getString("productId");
                int price = args.getInt("price");
                int count = args.getInt("price");
                final String orderId = args.getString("orderId");
                SDKProxy.getInstance().pay(mContext, price, count, pid, orderId, new SDKPayListener() {
                    @Override
                    public void onPaySuccess(SDKPayResult result) {
                        try {
                            JSONObject json = new JSONObject();
                            json.put("msg", "finishPay");
                            JSONObject args = new JSONObject();
                            args.put("success", true);
                            args.put("payResult", result.toJson());
                            json.put("args", args);
                            String msg = json.toString();
                            Log.d("pay", "Pay success. Result: " + msg);
                            mContext.callJS(msg);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }

                    @Override
                    public void onPayFail(String reason) {
                        try {
                            JSONObject json = new JSONObject();
                            json.put("msg", "finishPay");
                            JSONObject args = new JSONObject();
                            args.put("success", false);
                            args.put("reason", reason);
                            json.put("args", args);
                            String msg = json.toString();
                            Log.d("pay", "Pay fail. Result: " + msg);
                            mContext.callJS(msg);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                });

            } else if (msg.equals("googleplayReqProducts")) {
                JSONObject args = obj.getJSONObject("args");
                JSONArray pids = args.getJSONArray("productIds");
                SDKProxy.getInstance().queryProduct(pids.toString(), new SDKQueryProductListener() {
                    @Override
                    public void onFinishQueryProduct(JSONArray productsInfo) {
                        super.onFinishQueryProduct(productsInfo);
                        try {
                            JSONObject json = new JSONObject();
                            json.put("msg", "googleplayGetProducts");
                            JSONObject args = new JSONObject();
                            if (productsInfo == null) {
                                args.put("success", false);
                            } else {
                                args.put("success", true);
                                args.put("info", productsInfo);
                            }
                            json.put("args", args);
                            String msg = json.toString();
                            Log.d("googleplayGetProducts", "result " + msg);
                            mContext.callJS(msg);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                });
            } else if (msg.equals("navigateToGooglePlay")) {
                JSONObject args = obj.getJSONObject("args");
                String link = args.getString("link");
                // TODO
            } else if (msg.equals("td_Account")) {
                JSONObject args = obj.getJSONObject("args");
                TD.setAccount(args);
            } else if (msg.equals("td_onMissionBegin")) {
                JSONObject args = obj.getJSONObject("args");
                TD.onMissionBegin(args);
            } else if (msg.equals("td_onMissionCompleted")) {
                JSONObject args = obj.getJSONObject("args");
                TD.onMissionCompleted(args);
            } else if (msg.equals("td_onMissionFailed")) {
                JSONObject args = obj.getJSONObject("args");
                TD.onMissionFailed(args);
            } else if (msg.equals("td_setLevel")) {
                JSONObject args = obj.getJSONObject("args");
                TD.setLevel(args);
            } else if (msg.equals("td_onItemPurchase")) {
                JSONObject args = obj.getJSONObject("args");
                TD.onItemPurchase(args);
            } else if (msg.equals("td_onItemUse")) {
                JSONObject args = obj.getJSONObject("args");
                TD.onItemUse(args);
            } else if (msg.equals("td_onEvent")) {
                JSONObject args = obj.getJSONObject("args");
                TD.onEvent(args);
            } else if (msg.equals("startRecord")) {
                ScreenRecorder recorder = mContext.getScreenRecorder();
                if (recorder != null) {
                    mContext.getScreenRecorder().startRecord(recorder.new StartRecordListener() {
                        @Override
                        public void onComplete(boolean success) {
                            try {
                                JSONObject json = new JSONObject();
                                json.put("msg", "startRecordComplete");
                                JSONObject args = new JSONObject();
                                args.put("success", success);
                                json.put("args", args);
                                mContext.callJS(json.toString());
                            } catch (JSONException e) {
                                e.printStackTrace();
                            }
                        }
                    });
                }
            } else if (msg.equals("stopRecord")) {
                ScreenRecorder recorder = mContext.getScreenRecorder();
                if (recorder != null) {
                    mContext.getScreenRecorder().stopRecord();
                }
            } else if (msg.equals("useNativeSound")) {
                try {
                    JSONObject json2 = new JSONObject();
                    json2.put("msg", "setSupportRecord");
                    JSONObject args2 = new JSONObject();
                    boolean isSupport = ScreenRecorder.isDeviceSupport();
                    args2.put("support", isSupport);
                    args2.put("topMargin", 0);
                    args2.put("bottomMargin", 0);
                    json2.put("args", args2);
                    mContext.callJS(json2.toString());

//                    JSONObject json = new JSONObject();
//                    json.put("msg", "useNativeSound");
//                    JSONObject args = new JSONObject();
//                    args.put("support", false);
//                    json.put("args", args);
//                    mContext.callJS(json.toString());
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            } else if (msg.equals("saveToPhoto")) {
                ScreenRecorder recorder = mContext.getScreenRecorder();
                if (recorder != null) {
                    recorder.saveToPhoto();
                }
            } else if (msg.equals("shareVideo")) {
                ScreenRecorder recorder = mContext.getScreenRecorder();
                if (recorder != null) {
                    Log.d(TAG, "got ScreenRecorder obj");
                    Uri recentVideoUri = recorder.getRecentVideoUri();
                    Log.d(TAG, recentVideoUri.toString());
                    if (recentVideoUri != null) {
                        Log.d(TAG, "calling sdk shareVideo");
                        SDKProxy.getInstance().shareVideo(mContext, recentVideoUri, new SDKShareListener() {
                            @Override
                            public void onShareCompleted(boolean success) {
                                if (!success) {
                                    Toast.makeText(mContext, R.string.share_fail, Toast.LENGTH_SHORT).show();
                                }
                            }
                        });
                    } else {
                        Toast.makeText(mContext, R.string.share_no_video, Toast.LENGTH_SHORT).show();
                    }
                } else {
                    Toast.makeText(mContext, R.string.record_not_support, Toast.LENGTH_SHORT).show();
                }
            } else if (msg.equals("shareLink")) {
                JSONObject args = obj.getJSONObject("args");
                String title = args.getString("title");
                String link = args.getString("link");
                SDKProxy.getInstance().shareLink(mContext, title, link, new SDKShareListener() {
                    @Override
                    public void onShareCompleted(boolean success) {
                        try {
                            JSONObject json = new JSONObject();
                            json.put("msg", "shareLinkComplete");
                            JSONObject args = new JSONObject();
                            args.put("success", success);
                            json.put("args", args);
                            mContext.callJS(json.toString());
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                });
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}
