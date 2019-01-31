package com.openew.sdks.googleplay.ads;

import android.app.Activity;
import android.app.Application;
import android.provider.Settings;

import com.appsflyer.AFInAppEventParameterName;
import com.appsflyer.AFInAppEventType;
import com.appsflyer.AppsFlyerConversionListener;
import com.appsflyer.AppsFlyerLib;

import java.util.HashMap;
import java.util.Map;

public class AppFlyersWrapper {

    private Application mAppInst;
    private String mDevKey = "";

    private AppsFlyerConversionListener mConversionListener = new AppsFlyerConversionListener() {
        @Override
        public void onInstallConversionDataLoaded(Map<String, String> conversionData) {

        }

        @Override
        public void onInstallConversionFailure(String errorMessage) {

        }

        @Override
        public void onAppOpenAttribution(Map<String, String> attributionData) {

        }

        @Override
        public void onAttributionFailure(String errorMessage) {

        }
    };

    public void init(Application appInst, String devKey) {
        mAppInst = appInst;
        mDevKey = devKey;
        AppsFlyerLib.getInstance().setDebugLog(true);
        AppsFlyerLib.getInstance().init(mDevKey, mConversionListener, mAppInst.getApplicationContext());
        AppsFlyerLib.getInstance().startTracking(mAppInst);

        AppsFlyerLib.getInstance().setCollectIMEI(false);
        AppsFlyerLib.getInstance().setCollectAndroidID(false);
//        String gaid = AdsHelper.getInstance().getGoogleAdsId(appInst.getApplicationContext());
//        setGAID(gaid);
    }

    public void setCustomId(String userId) {
        AppsFlyerLib.getInstance().setCustomerUserId(userId);
    }

    private void setGAID(String gaid) {
        if (gaid == null) {
            AppsFlyerLib.getInstance().setCollectIMEI(true);
            AppsFlyerLib.getInstance().setCollectAndroidID(true);
            String androidId = Settings.Secure.getString(mAppInst.getApplicationContext().getContentResolver(),
                    Settings.Secure.ANDROID_ID);
            AppsFlyerLib.getInstance().setAndroidIdData(androidId);
        } else {
            AppsFlyerLib.getInstance().setCollectIMEI(false);
            AppsFlyerLib.getInstance().setCollectAndroidID(false);
//            AppsFlyerLib.getInstance().setAndroidIdData(gaid);
        }
    }

    public void onEnterGame(String userId) {
        setCustomId(userId);

        Map<String, Object> eventValue = new HashMap<>();
        eventValue.put(AFInAppEventParameterName.CUSTOMER_USER_ID, userId);
        AppsFlyerLib.getInstance().trackEvent(mAppInst.getApplicationContext(),AFInAppEventType.LOGIN,eventValue);
    }

    public void onPayment(String sku, float price, String currency) {
        Map<String, Object> eventValue = new HashMap<>();
        eventValue.put(AFInAppEventParameterName.REVENUE, price);
        eventValue.put(AFInAppEventParameterName.CONTENT_ID, sku);
        eventValue.put(AFInAppEventParameterName.CURRENCY, currency);
        AppsFlyerLib.getInstance().trackEvent(mAppInst.getApplicationContext() , AFInAppEventType.PURCHASE , eventValue);
    }
}
