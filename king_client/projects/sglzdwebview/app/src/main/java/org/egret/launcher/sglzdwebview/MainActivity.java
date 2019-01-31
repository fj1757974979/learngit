package org.egret.launcher.sglzdwebview;

import android.Manifest;
import android.app.ActionBar;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.media.SoundPool;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.webkit.WebView;
import android.widget.FrameLayout;
import android.os.Environment;
import android.widget.TextView;
import android.view.KeyEvent;
import android.widget.Toast;

import com.openew.game.sdk.SDKProxy;
import com.openew.game.sdkcommon.SDKExitListener;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.sdkcommon.SDKLoginListener;
import com.openew.game.sdkcommon.SDKUser;

import java.io.File;
import java.lang.reflect.Field;
import java.util.HashMap;

import org.egret.launcher.egret_android_launcher.NativeActivity;
import org.egret.launcher.egret_android_launcher.NativeCallback;
import org.egret.launcher.egret_android_launcher.NativeLauncher;
import org.egret.runtime.launcherInterface.INativePlayer;
import org.egret.launcher.sglzdwebview.ZipUtil;
import org.egret.launcher.sglzdwebview.FileUtils;
import org.egret.launcher.sglzdwebview.R;
import org.json.JSONException;
import org.json.JSONObject;

import ren.yale.android.cachewebviewlib.CacheWebView;
import ren.yale.android.cachewebviewlib.ResourceLoader;
import ren.yale.android.cachewebviewlib.WebViewCache;
import ren.yale.android.cachewebviewlib.utils.FileUtil;

public class MainActivity extends NativeActivity {
    public static MainActivity instance = null;
    private final String token = "be38adfd895a1e9256d74972278eb8f1aede9fc457b789fcafd5fc5fbd7dd451";
    //private final String token = "66922a7b89c881fa83cc9898b7cd514200818e9b4de9b986a6eb1f8efd9d3237";

    /*
    * 设置是否显示FPS面板
    *   true: 显示面板
    *   false: 隐藏面板
    * Set whether to show FPS panel
    *   true: show FPS panel
    *   false: hide FPS panel
    * */
    private final boolean showFPS = true;

    private FrameLayout rootLayout = null;
    
    private Handler handler = new Handler();
    private long clickTime = 0; // 第一次点击的时间

    private int GAME_PERMISSION_REQUEST_CODE = 8964;

    @Override
    public void onBackPressed() {
        exit();
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        // 是否触发按键为back键
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            onBackPressed();
            return true;
        } else { // 如果不是back键正常响应
            return super.onKeyDown(keyCode, event);
        }
    }

    private void exit() {
        if ((System.currentTimeMillis() - clickTime) > 2000) {
            Toast.makeText(this, "再按一次退出游戏", Toast.LENGTH_SHORT).show();
            clickTime = System.currentTimeMillis();
        } else {
            SDKProxy.getInstance().showExitDialog(this, new SDKExitListener() {
                @Override
                public void onExitSuccess() {
                    MainActivity.this.finish();
                }

                @Override
                public void onExitFail() {
                }
            });
        }
    }

    public void getAllFiles(String dirPath, String _type) {
        File f = new File(dirPath);
        if (!f.exists()) {//判断路径是否存在
            return;
        }

        File[] files = f.listFiles();

        if(files==null){//判断权限
            return;
        }

        for (File _file : files) {//遍历目录
            Log.d("LOGCAT","filePath:"+_file.getAbsolutePath());
            if(_file.isFile() && _file.getName().endsWith(_type)){
                String _name=_file.getName();
                String filePath = _file.getAbsolutePath();//获取文件路径
                String fileName = _file.getName().substring(0,_name.length()-4);//获取文件名
                Log.d("LOGCAT","fileName:"+fileName);
                Log.d("LOGCAT","filePath:"+filePath);
            } else if(_file.isDirectory()){//查询子目录
                getAllFiles(_file.getAbsolutePath(), _type);
            } else{
            }
        }
        return;
    }

    private void installCache(String from, String to) {
        AssetManager mgr = this.getAssets();
        FileUtils.copyFileOrDir(mgr, from, to);
    }

    private void zipCache(String from, String to) {

        try {
            ZipUtil.zip(from, to);
        } catch (Exception e) {
            Log.e("ZIP", e.getMessage());
        }
    }

    public void enterGame() {
        this.findViewById(R.id.bg).setVisibility(View.GONE);
        this.findViewById(R.id.tips).setVisibility(View.GONE);
        this.findViewById(R.id.logo).setVisibility(View.GONE);
    }

    private CacheWebView _webview;

    private void hackEgretWebView() {
        rootLayout.removeViewAt(0);
        Class<NativeLauncher> clazz = NativeLauncher.class;
        Field field = null;

        try {
            field = clazz.getDeclaredField("E");
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
            return;
        }

        this._webview = new CacheWebView(this);
        _webview.setCacheStrategy(WebViewCache.CacheStrategy.NORMAL);
        _webview.setEncoding("UTF-8");
        _webview.getWebViewCache().getCacheExtensionConfig().addExtension("fui").addExtension(
                "mp3").addExtension("json");

        field.setAccessible(true);
        try {
            field.set(launcher, this._webview);
        } catch (IllegalAccessException e) {
            e.printStackTrace();
            return;
        }
        field.setAccessible(false);

        rootLayout.addView(this._webview, 0);
    }


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        instance = this;
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        rootLayout = (FrameLayout)findViewById(R.id.rootLayout);
        ((TextView)this.findViewById(R.id.tips)).setText(R.string.init_game);


//        progressCallback = new NativeCallback() {
//            @Override
//            public void onCallback(String msg, int val) {
//                switch (msg) {
//                    case NativeLauncher.RequestingRuntime:
//                        /*
//                        * 向服务器请求runtime和游戏信息
//                        * Request the server for runtime and game information
//                        * */
//                        break;
//                    case NativeLauncher.LoadingRuntime:
//                        /*
//                        * 下载和加载runtime
//                        * Download and load runtime
//                        * */
//                        break;
//                    case NativeLauncher.RetryRequestingRuntime:
//                        handler.postDelayed(new Runnable() {
//                            @Override
//                            public void run() {
//                                launcher.loadRuntime(token);
//                            }
//                        }, 1000);
//                        break;
//                    case NativeLauncher.LoadingGame:
//                        /*
//                        * 下载和加载游戏资源
//                        * Download and load game resources
//                        * */
//                        launcher.startRuntime(showFPS);
//                        //MainActivity.instance.enterGame();
//                        break;
//                    case NativeLauncher.GameStarted:
//                        /*
//                        * 游戏启动
//                        * Game started
//                        * */
//                        break;
//                    case NativeLauncher.LoadRuntimeFailed:
//                        /*
//                        * 加载runtime和游戏信息失败
//                        * Loading runtime and game resources failed
//                        * */
//                        break;
//                    default:
//
//                        break;
//                }
//            }
//        };

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            String[] permissions = {
                    Manifest.permission.READ_PHONE_STATE,
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
            };
            boolean allGranted = true;
            for (String permission: permissions) {
                if (checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (!allGranted) {
                Log.d("permission", "permissions denied, requesting it");
                requestPermissions(permissions, GAME_PERMISSION_REQUEST_CODE);
            } else {
                initSDKAndRuntime();
            }
        } else {
            initSDKAndRuntime();
        }

        SoundMgr.init(this);
    }

    private void initSDKAndRuntime() {
        /* zip all cache files */
        String cachePath = this.getCacheDir().getPath() + "/CacheWebView";

        // uncomment when needed
        //String storagePath = "/storage/emulated/0/Download/cache.zip";
        //zipCache(cachePath, storagePath);

        //Log.d("LOGCAT", cachePath);
        //getAllFiles(cachePath, "js");
        /* copy assets/org.chromium.android_webview to cachepath
         */


        //getAllFiles(cachePath, "js");
        if (!FileUtils.fileExists(cachePath)) {
            ((TextView)this.findViewById(R.id.tips)).setText(R.string.init_install);
            FileUtils.createDir(cachePath);
            installCache("CacheWebView", this.getCacheDir().getPath());
            //FileUtils.createFile(cachePath + "/installed.done");
        }
        //getAllFiles(cachePath, "js");

        ResourceLoader.getInstance().init(this, "game");
        launcher.initViews(rootLayout);

        WebView.setWebContentsDebuggingEnabled(false);
        this.hackEgretWebView();

        setExternalInterfaces();



        /*
         * 设置是否自动关闭启动页
         *   1: 自动关闭启动页
         *   0: 手动关闭启动页
         * Set whether to close the startup page automatically
         *   1. close the startup page automatically
         *   0. close the startup page manually
         * */
        launcher.closeLoadingViewAutomatically = 1;

        /*
         * 设置是否每次启动都重新下载游戏资源
         *   0: 版本更新才重新下载
         *   1: 每次启动都重新下载
         * Set whether to re-download game resources each time the application starts
         *   0: re-download game resources if version updated
         *   1: re-download game resources each time the application starts
         * */
        launcher.clearGameCache = 0;

        /*
         * 设置runtime代码log的等级
         *   0: Debug
         *   1: Info
         *   2: Warning
         *   3: Error
         * Set log level for runtime code
         *   0: Debug
         *   1: Info
         *   2: Warning
         *   3: Error
         * */
        launcher.logLevel = 3;

        SDKProxy.getInstance().init(this, new SDKInitListener() {
            @Override
            public void onInitSuccess() {
                launcher.loadRuntime(token);

                // 延迟几秒去掉动画
                MainActivity.this.handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        // this code will be executed after 2 seconds
                        MainActivity.instance.enterGame();

                    }
                }, 3000);
//                new Handler().postDelayed(new Runnable() {
//                    @Override
//                    public void run() {
//                        // this code will be executed after 2 seconds
//                        MainActivity.instance.enterGame();
//                    }
//                }, 3000);
            }

            @Override
            public void onInitFail() {
                ((TextView)MainActivity.this.findViewById(R.id.tips)).setText(R.string.sdk_init_fail);
            }
        });
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (grantResults.length > 0) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        }

        if (requestCode == GAME_PERMISSION_REQUEST_CODE) {
            boolean allGranted = true;
            for (int grant: grantResults) {
                if (grant != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) {
                initSDKAndRuntime();
            } else {
                AlertDialog.Builder builder = new AlertDialog.Builder(this);
                builder.setMessage("游戏需要访问相关手机权限，请到权限设置中授权");
                builder.setPositiveButton("去授权", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        Intent intent = new Intent();
                        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                        intent.addCategory(Intent.CATEGORY_DEFAULT);
                        intent.setData(Uri.parse("package:" + getPackageName()));
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
                        intent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
                        startActivity(intent);
                    }
                });
                builder.setNegativeButton("取消", null);
                builder.show();
                ((TextView)MainActivity.this.findViewById(R.id.tips)).setText(R.string.sdk_init_fail);
            }
        }
    }

    // 切回前台
    @Override
    protected void onStart() {
        super.onStart();

        SDKProxy.getInstance().onStart(this);
    }

    // 切到后台
    @Override
    protected void onStop() {
        super.onStop();
        SDKProxy.getInstance().onStop(this);
    }

    @Override
    protected void onDestroy() {
        if (this._webview != null) {
            this._webview.destroy();
        }
        super.onDestroy();
        SoundMgr.destroy();
        SDKProxy.getInstance().onDestroy(this);
    }

    @Override
    public void onResume() {
        super.onResume();
        SDKProxy.getInstance().onResume(this);
    }

    @Override
    public void onPause() {
        super.onPause();
        SDKProxy.getInstance().onPause(this);
    }

    @Override
    public void onRestart() {
        super.onRestart();
        SDKProxy.getInstance().onRestart(this);
    }

    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        SDKProxy.getInstance().onNewIntent(this, intent);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        SDKProxy.getInstance().onActivityResult(this, requestCode, resultCode, data);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        SDKProxy.getInstance().onConfigurationChanged(this, newConfig);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        SDKProxy.getInstance().onSaveInstanceState(this, outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        super.onRestoreInstanceState(savedInstanceState);
        SDKProxy.getInstance().onRestoreInstanceState(this, savedInstanceState);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        SDKProxy.getInstance().onWindowFocusChanged(this, hasFocus);
    }

    @Override
    public void onWindowAttributesChanged(WindowManager.LayoutParams params) {
        super.onWindowAttributesChanged(params);
        SDKProxy.getInstance().onWindowAttributesChanged(this, params);
    }

    private void setExternalInterfaces() {
        launcher.setExternalInterface("callNative", new INativePlayer.INativeInterface() {
            @Override
            public void callback(String s) {
                Log.d("Egret Launcher", "callNative message: " + s);
//                launcher.callExternalInterface("callJS", "message from native");
                try {
                    JSONObject obj = new JSONObject(s);
                    String msg = obj.getString("msg");
                    if (msg.equals("login")) {
                        SDKProxy.getInstance().login(MainActivity.this, obj.getString("args"),
                                new SDKLoginListener() {
                            @Override
                            public void onLoginSuccess(SDKUser user) {
                                try {
                                    ApplicationInfo info = MainActivity.this.getPackageManager().getApplicationInfo(MainActivity.this.getPackageName(), PackageManager.GET_META_DATA);
                                    user.tdChannelID = info.metaData.getString("tdChannelID");
                                    JSONObject json = new JSONObject();
                                    json.put("msg", "loginDone");

                                    JSONObject args = new JSONObject();
                                    args.put("success", true);
                                    args.put("info", user.toJson());

                                    json.put("args", args);

                                    String msg = json.toString();
                                    Log.d("login", "result " + msg);
                                    launcher.callExternalInterface("callJS", msg);
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
                                    launcher.callExternalInterface("callJS", msg);
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

                            ApplicationInfo info = MainActivity.this.getPackageManager().getApplicationInfo(MainActivity.this.getPackageName(), PackageManager.GET_META_DATA);
                            String tdChannelID = info.metaData.getString("tdChannelID");
                            args.put("tdChannelID", tdChannelID);

                            json.put("args", args);

                            String returnmsg = json.toString();
                            Log.d("login", "result " + returnmsg);
                            launcher.callExternalInterface("callJS", returnmsg);
                        } catch (Exception e) {
                            Log.e("tdChannel", e.getLocalizedMessage());
                            e.printStackTrace();
                        }
                    } else if (msg.equals("playSound")) {
                        JSONObject args = obj.getJSONObject("args");
                        String path = args.getString("path");
                        Double volume = args.getDouble("volume");
                        SoundMgr.playSound(path, volume.floatValue());
                    } else if (msg.equals("playMusic")) {
                        JSONObject args = obj.getJSONObject("args");
                        String path = args.getString("path");
                        Double volume = args.getDouble("volume");
                        SoundMgr.playMusic(path, volume.floatValue());
                    } else if (msg.equals("setMusicVolume")) {
                        JSONObject args = obj.getJSONObject("args");
                        Double volume = args.getDouble("volume");
                        SoundMgr.setMusicVolume(volume.floatValue());
                    } else if (msg.equals("stopMusic")) {
                        SoundMgr.stopMusic();
                    } else if (msg.equals("useNativeSound")){

                        // 调用脚本，使用native声音系统
                        JSONObject json = new JSONObject();
                        json.put("msg", "useNativeSound");
                        String msgjs = json.toString();
                        Log.d("activity", "useNativeSound " + msgjs);
                        launcher.callExternalInterface("callJS", msgjs);
                    } else if (msg.equals("onEnterGame")) {
                        JSONObject args = obj.getJSONObject("args");
                        SDKProxy.getInstance().onEnterGame(MainActivity.this,
                                args.getString("userId"), args.getString("userName"),
                                args.getInt("level"),
                                args.getInt("serverId"),
                                args.getString("serverName"));
                    } else if (msg.equals("onCreateRole")) {
                        JSONObject args = obj.getJSONObject("args");
                        SDKProxy.getInstance().onCreateRole(MainActivity.this,
                                args.getString("userId"), args.getString("userName"),
                                args.getInt("level"),
                                args.getInt("serverId"),
                                args.getString("serverName"));
                    } else if (msg.equals("onLevelUp")) {
                        JSONObject args = obj.getJSONObject("args");
                        SDKProxy.getInstance().onLevelUp(MainActivity.this,
                                args.getString("userId"), args.getString("userName"),
                                args.getInt("level"),
                                args.getInt("serverId"),
                                args.getString("serverName"));
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
