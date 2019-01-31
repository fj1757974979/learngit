package ren.yale.android.cachewebviewlib;

import android.content.Context;
import android.text.TextUtils;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.util.HashSet;

import static java.lang.Integer.parseInt;


/**
 * Created by yale on 2017/9/18.
 */

public class ResourceLoader {

    private volatile static ResourceLoader INSTANCE;
    private Context mContext;
    private String mAssetDir;
    private String mUrl;
    private int mVersion;
    private HashSet<String> mAssetResSet;


    public static ResourceLoader getInstance(){
        ResourceLoader tmp = INSTANCE;
        if (tmp ==null){
            synchronized (ResourceLoader.class){
                tmp = INSTANCE;
                if (tmp == null){
                    tmp = new ResourceLoader();
                    INSTANCE = tmp;
                }
            }
        }
        return tmp;
    }

    public  void init(Context context,String url){
        mContext = context.getApplicationContext();
        //mAssetDir = assetDir;
        if (mAssetResSet!=null){
            mAssetResSet.clear();
            mAssetResSet = null;
        }
        mAssetResSet = new HashSet<>();
        mUrl = url;
        //listRes(mAssetDir);
        initVersion();
        initRes();
    }

    private int toVersion(String version) {
        String[] versions =version.split("\\.");
        if (versions.length < 3) return -1;
        int v1 = parseInt(versions[0]);
        int v2 = parseInt(versions[1]);
        int v3 = parseInt(versions[2]);
        int scale = 1000;
        return v1 * scale * scale + v2 * scale + v3;
    }

    private void initRes() {
        try {
            InputStream in = mContext.getAssets().open("files.ini");
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));
            String line;
            while( (line = bufferedReader.readLine()) != null) {
                mAssetResSet.add(line);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initVersion() {
        mVersion = 0;
        try {
            InputStream in = mContext.getAssets().open( "version.ini");
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(in));
            String versionStr = bufferedReader.readLine();
            mVersion = toVersion(versionStr);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private String getUrlPath(String url){
        try {
            URI u = new URI(url);
            return u.getPath();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public String[] parseURL(String url) {
        url = url.replaceAll(mUrl, "");
        url = url.replaceAll("v=", "");
        String[] ret = url.split("\\?");
        return ret;
    }

    public String findAssetFile(String url){
        int pos = -1;
        String[] part = parseURL(url);
        String file = part[0];

        pos = file.indexOf('/');
        if (pos == 0) {
            file = file.substring(pos + 1);
        }
        int version = 0;
        if (part.length >= 2) {
            version = toVersion(part[1]);
        }
        if (version < 0 || version > mVersion) return "";

        if (mAssetResSet.contains(file)){
            return file;
        }

        return "";
    }


    public InputStream getAssetFileStream(String urlPath){
        String assetFile = findAssetFile(urlPath);
        if (TextUtils.isEmpty(assetFile)){
            return null;
        }
        try {
            CacheWebViewLog.d(urlPath);
            return  mContext.getAssets().open(assetFile);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }




}
