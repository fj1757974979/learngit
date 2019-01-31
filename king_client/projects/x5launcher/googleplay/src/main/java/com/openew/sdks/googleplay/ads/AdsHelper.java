package com.openew.sdks.googleplay.ads;

import android.content.Context;
import android.util.Log;

//import com.google.android.gms.ads.identifier.AdvertisingIdClient;
//import com.google.android.gms.common.GooglePlayServicesNotAvailableException;
//import com.google.android.gms.common.GooglePlayServicesRepairableException;

import java.io.IOException;

public class AdsHelper {

    private static AdsHelper sInstance = null;
    private String TAG = "AdsHelper";

    public static AdsHelper getInstance() {
        if (AdsHelper.sInstance == null) {
            AdsHelper.sInstance = new AdsHelper();
        }
        return AdsHelper.sInstance;
    }

//    public String getGoogleAdsId(Context context) {
//        try {
//            return AdvertisingIdClient.getAdvertisingIdInfo(context).getId();
//        } catch (GooglePlayServicesNotAvailableException e) {
//            Log.e(TAG, "can't get GAID because GooglePlay service not available");
//            return null;
//        } catch (IOException e) {
//            Log.e(TAG, "can't get GAID because IOException: " + e.getMessage());
//            return null;
//        } catch (GooglePlayServicesRepairableException e) {
//            Log.e(TAG, "can't get GAID because GooglePlay service needs repair!");
//            return null;
//        }
//    }
}
