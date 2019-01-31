package com.openew.launcher;

import java.io.File;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.graphics.PixelFormat;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.Settings;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.openew.game.sdk.SDKProxy;
import com.openew.game.sdkcommon.SDKExitListener;
import com.openew.game.sdkcommon.SDKInitListener;
import com.openew.game.utils.ScreenRecorder;
import com.openew.launcher.utils.X5WebView;
import com.openew.sdks.talkingdata.TD;
import com.tencent.smtt.export.external.interfaces.IX5WebChromeClient.CustomViewCallback;
import com.tencent.smtt.export.external.interfaces.JsResult;
import com.tencent.smtt.export.external.interfaces.WebResourceError;
import com.tencent.smtt.export.external.interfaces.WebResourceRequest;
import com.tencent.smtt.sdk.CookieSyncManager;
import com.tencent.smtt.sdk.DownloadListener;
import com.tencent.smtt.sdk.QbSdk;
import com.tencent.smtt.sdk.WebChromeClient;
import com.tencent.smtt.sdk.WebSettings;
import com.tencent.smtt.sdk.WebSettings.LayoutAlgorithm;
import com.tencent.smtt.sdk.WebView;
import com.tencent.smtt.sdk.WebViewClient;
import com.tencent.smtt.utils.TbsLog;

import ren.yale.android.cachewebviewlib.ResourceLoader;

public class MainActivity extends Activity {
	/**
	 * 作为一个浏览器的示例展示出来，采用android+web的模式
	 */

	private static MainActivity _mainActivity = null;
	private X5WebView mWebView = null;
	private ViewGroup mViewParent;
	private String _cachePath;

	private static String mHomeUrl = "https://client.lzd.openew.com/king_war";
    //private static final String mHomeUrl = "http://192.168.1.240:5379/";
	private static final String TAG = "Launcher";

	private boolean _initX5 = false;
	private int GAME_PERMISSION_REQUEST_CODE = 8964;
	private long clickTime = 0; // 第一次点击的时间

    private ScreenRecorder mScreenRecorder = null;

    public static boolean hasPreInit = false;

    public static MainActivity getInstance() {
        return _mainActivity;
    }

	@Override
	protected void onCreate(Bundle savedInstanceState) {
        _mainActivity = this;
		super.onCreate(savedInstanceState);
		getWindow().setFormat(PixelFormat.TRANSLUCENT);

		//
		try {
			if (Integer.parseInt(android.os.Build.VERSION.SDK) >= 11) {
				getWindow()
						.setFlags(
								android.view.WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
								android.view.WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED);
			}
		} catch (Exception e) {
		}

		/*
		 * getWindow().addFlags(
		 * android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN);
		 */
		setContentView(R.layout.activity_main);
		mViewParent = (ViewGroup) findViewById(R.id.webView1);


        File  cacheFile = new File(this.getCacheDir(),"CacheWebView");
        String path = cacheFile.getAbsolutePath();
		_cachePath = path;
        /*
        String storagePath = "/storage/emulated/0/Download/cache.zip";
        zipCache(_cachePath, storagePath);

        if (!FileUtils.fileExists(_cachePath)) {
            FileUtils.createDir(_cachePath);
            installCache("CacheWebView", this.getCacheDir().getPath());
            //FileUtils.createFile(cachePath + "/installed.done");
        }
        getAllFiles(this.getCacheDir().getPath());
        */
        try {
            ApplicationInfo info = this.getPackageManager().getApplicationInfo(this.getPackageName(),
                    PackageManager.GET_META_DATA);
            mHomeUrl = info.metaData.getString("homeUrl");
			TD.init(this, info.metaData.getString("tdAppId"), info.metaData.getString("tdChannelID"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        ResourceLoader.getInstance().init(this,mHomeUrl);

		doCheckPermission();

		//initSDKAndRuntime();
	}


    public void getAllFiles(String dirPath) {
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
            if(_file.isFile()){
                String _name=_file.getName();
                String filePath = _file.getAbsolutePath();//获取文件路径
                String fileName = _file.getName().substring(0,_name.length()-4);//获取文件名
                Log.d("LOGCAT","fileName:"+fileName);
                Log.d("LOGCAT","filePath:"+filePath);
            } else if(_file.isDirectory()){//查询子目录
                getAllFiles(_file.getAbsolutePath());
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

	private void doCheckPermission() {
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
	}

	private void initSDKAndRuntime() {

		SDKProxy.getInstance().init(this, new SDKInitListener() {
			@Override
			public void onInitSuccess() {
			    Log.d(TAG, "init sdk success");

                SDKProxy.getInstance().onCreate(MainActivity.this);

                if (!MainActivity.hasPreInit) {
					QbSdk.PreInitCallback cb = new QbSdk.PreInitCallback() {

						@Override
						public void onViewInitFinished(boolean arg0) {
							if (MainActivity.getInstance() != null) {
								MainActivity.getInstance().startX5();
							}
							//x5內核初始化完成的回调，为true表示x5内核加载成功，否则表示x5内核加载失败，会自动切换到系统内核。
							Log.d(TAG, " onViewInitFinished is " + arg0);
						}

						@Override
						public void onCoreInitFinished() {
							Log.d(TAG, "onCoreInitFinished");
						}
					};
					Log.d(TAG, "init x5 env");
					//x5内核初始化接口
					QbSdk.initX5Environment(MainActivity.this.getApplicationContext(),  cb);
					MainActivity.hasPreInit = true;
				} else {
					startX5();
				}
			}

			@Override
			public void onInitFail() {
			    Log.d(TAG, "init sdk fail!");
			}
		});
	}

	public void startX5() {
        if (!_initX5) {
            mTestHandler.sendEmptyMessageDelayed(MSG_INIT_UI, 10);
            _initX5 = true;
        }
    }

	public void enterGame() {
		this.findViewById(R.id.bg).setVisibility(View.GONE);
		this.findViewById(R.id.tips).setVisibility(View.GONE);
		this.findViewById(R.id.logo).setVisibility(View.GONE);
	}

	private void init() {
        Log.d(TAG, "init");
		mWebView = new X5WebView(this, null);
		mWebView.setVisibility(View.INVISIBLE);

		// 延迟几秒去掉动画
		this.mTestHandler.postDelayed(new Runnable() {
			@Override
			public void run() {
				// this code will be executed after 2 seconds
				mWebView.setVisibility(View.VISIBLE);
				enterGame();

			}
		}, 4000);

		mViewParent.addView(mWebView, new FrameLayout.LayoutParams(
				FrameLayout.LayoutParams.FILL_PARENT,
				FrameLayout.LayoutParams.FILL_PARENT));

		mWebView.setWebViewClient(new WebViewClient() {
			private boolean isError = false;

			@Override
			public boolean shouldOverrideUrlLoading(WebView view, String url) {
				return false;
			}

			@Override
			public void onPageFinished(WebView view, String url) {
				super.onPageFinished(view, url);
				/* mWebView.showLog("test Log"); */
				if (isError) {
					isError = false;
					Log.e(TAG, String.format("load url %s fail", url));
					new Handler().postDelayed(new Runnable() {
						@Override
						public void run() {
							Log.d(TAG, String.format("try load %s again", mHomeUrl));
							mWebView.loadUrl(String.format("%s?v=%f", mHomeUrl, Math.random()));
						}
					}, 100);
				}
			}

			@Override
			public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
				super.onReceivedError(view, request, error);
				Log.d(TAG, "WebView load page error: " + error.toString());
				isError = true;
			}
		});

//		mWebView.setWebChromeClient(new WebChromeClient() {
//
//			@Override
//			public boolean onJsConfirm(WebView arg0, String arg1, String arg2,
//					JsResult arg3) {
//				return super.onJsConfirm(arg0, arg1, arg2, arg3);
//			}
//
//			View myVideoView;
//			View myNormalView;
//			CustomViewCallback callback;
//
//			// /////////////////////////////////////////////////////////
//			//
//			/**
//			 * 全屏播放配置
//			 */
//			@Override
//			public void onShowCustomView(View view,
//					CustomViewCallback customViewCallback) {
//				callback = customViewCallback;
//			}
//
//			@Override
//			public void onHideCustomView() {
//				if (callback != null) {
//					callback.onCustomViewHidden();
//					callback = null;
//				}
//				if (myVideoView != null) {
//					ViewGroup viewGroup = (ViewGroup) myVideoView.getParent();
//					viewGroup.removeView(myVideoView);
//					viewGroup.addView(myNormalView);
//				}
//			}
//
//			@Override
//			public boolean onJsAlert(WebView arg0, String arg1, String arg2,
//					JsResult arg3) {
//				/**
//				 * 这里写入你自定义的window alert
//				 */
//				return super.onJsAlert(null, arg1, arg2, arg3);
//			}
//		});

		mWebView.setDownloadListener(new DownloadListener() {

			@Override
			public void onDownloadStart(String arg0, String arg1, String arg2,
					String arg3, long arg4) {
				TbsLog.d(TAG, "url: " + arg0);
				new AlertDialog.Builder(MainActivity.this)
						.setTitle("allow to download？")
						.setPositiveButton("yes",
								new DialogInterface.OnClickListener() {
									@Override
									public void onClick(DialogInterface dialog, int which) {
										Toast.makeText(
										        MainActivity.this,
                                                "fake message: i'll download...",
                                                Toast.LENGTH_SHORT).show();
									}
								})
						.setNegativeButton("no",
								new DialogInterface.OnClickListener() {

									@Override
									public void onClick(DialogInterface dialog,
											int which) {
										// TODO Auto-generated method stub
										Toast.makeText(
												MainActivity.this,
												"fake message: refuse download...",
												Toast.LENGTH_SHORT).show();
									}
								})
						.setOnCancelListener(
								new DialogInterface.OnCancelListener() {

									@Override
									public void onCancel(DialogInterface dialog) {
										// TODO Auto-generated method stub
										Toast.makeText(
												MainActivity.this,
												"fake message: refuse download...",
												Toast.LENGTH_SHORT).show();
									}
								}).show();
			}
		});

		WebSettings webSetting = mWebView.getSettings();
		webSetting.setAllowFileAccess(true);
		webSetting.setLayoutAlgorithm(LayoutAlgorithm.NARROW_COLUMNS);
		webSetting.setSupportZoom(true);
		webSetting.setBuiltInZoomControls(true);
		webSetting.setUseWideViewPort(true);
		webSetting.setSupportMultipleWindows(false);
		// webSetting.setLoadWithOverviewMode(true);
		webSetting.setAppCacheEnabled(true);
		// webSetting.setDatabaseEnabled(true);
		webSetting.setDomStorageEnabled(true);
		webSetting.setJavaScriptEnabled(true);
		webSetting.setGeolocationEnabled(true);
		webSetting.setAppCacheMaxSize(Long.MAX_VALUE);
        webSetting.setCacheMode(WebSettings.LOAD_CACHE_ELSE_NETWORK);
		webSetting.setAppCachePath(_cachePath);
		webSetting.setDatabasePath(this.getDir("databases", 0).getPath());
		webSetting.setGeolocationDatabasePath(this.getDir("geolocation", 0)
				.getPath());
		// webSetting.setPageCacheCapacity(IX5WebSettings.DEFAULT_CACHE_CAPACITY);
		webSetting.setPluginState(WebSettings.PluginState.ON_DEMAND);
		// webSetting.setRenderPriority(WebSettings.RenderPriority.HIGH);
		// webSetting.setPreFectch(true);
        final NativeCall nativeCall = new NativeCall(this);

        mWebView.addJavascriptInterface(nativeCall, "NativeCall");
		long time = System.currentTimeMillis();
		mWebView.loadUrl(String.format("%s?v=%f", mHomeUrl, Math.random()));
		TbsLog.d("time-cost", "cost time: "
				+ (System.currentTimeMillis() - time));
		CookieSyncManager.createInstance(this);
		CookieSyncManager.getInstance().sync();
	}

	boolean[] m_selected = new boolean[] { true, true, true, true, false,
			false, true };


	@Override
	public void onBackPressed() {
		exit();
	}

	@Override
	public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
		if (grantResults.length > 0) {
			super.onRequestPermissionsResult(requestCode, permissions, grantResults);
		}

		if (requestCode == GAME_PERMISSION_REQUEST_CODE ||
                requestCode == ScreenRecorder.REQUEST_PER_CODE) {
			boolean allGranted = true;
			for (int grant: grantResults) {
				if (grant != PackageManager.PERMISSION_GRANTED) {
					allGranted = false;
					break;
				}
			}
			if (allGranted) {
			    if (requestCode == GAME_PERMISSION_REQUEST_CODE) {
                    initSDKAndRuntime();
                } else if (requestCode == ScreenRecorder.REQUEST_PER_CODE) {
			        if (mScreenRecorder != null) {
			            mScreenRecorder.onPermissionGranted();
                    }
                }
			} else {
				AlertDialog.Builder builder = new AlertDialog.Builder(this);
				builder.setMessage(R.string.auth_hint);
				builder.setPositiveButton(R.string.auth_confirm, new DialogInterface.OnClickListener() {
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
				builder.setNegativeButton(R.string.cancel, null);
				builder.show();
				if (requestCode == GAME_PERMISSION_REQUEST_CODE) {
                    ((TextView)MainActivity.this.findViewById(R.id.tips)).setText(R.string.sdk_init_fail);
                } else if (requestCode == ScreenRecorder.REQUEST_PER_CODE) {
				    if (mScreenRecorder != null) {
				        mScreenRecorder.onPermissionDenied();
                    }
                }
			}
		}
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
			Toast.makeText(this, R.string.exit_hint, Toast.LENGTH_SHORT).show();
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

    // 切回前台
    @Override
    protected void onStart() {
        super.onStart();
        callJS("{\"msg\":\"onStart\", \"arg\":{}}");

        SDKProxy.getInstance().onStart(this);
    }

    // 切到后台
    @Override
    protected void onStop() {
        super.onStop();
        callJS("{\"msg\":\"onStop\", \"arg\":{}}");
        SDKProxy.getInstance().onStop(this);
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
        if (!SDKProxy.getInstance().onActivityResult(this, requestCode, resultCode, data)) {
        	super.onActivityResult(requestCode, resultCode, data);
		}

		if (requestCode == ScreenRecorder.REQUEST_PRJ_CODE) {
            if (mScreenRecorder != null) {
                mScreenRecorder.onActivityResult(requestCode, resultCode, data);
            }
        }
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
	@Override
	protected void onDestroy() {
		if (mTestHandler != null)
			mTestHandler.removeCallbacksAndMessages(null);
		if (mWebView != null)
			mWebView.destroy();
        SDKProxy.getInstance().onDestroy(this);
		super.onDestroy();

		if (mScreenRecorder != null) {
		    mScreenRecorder.onDestroy();
        }

        MainActivity._mainActivity = null;
		android.os.Process.killProcess(android.os.Process.myPid());
	}

	public static final int MSG_INIT_UI = 1;
	private Handler mTestHandler = new Handler() {
		@Override
		public void handleMessage(Message msg) {
			switch (msg.what) {
			case MSG_INIT_UI:
				init();
				break;
			}
			super.handleMessage(msg);
		}
	};

	public void callJS(String msg) {
		if (mWebView == null) {
			return;
		}
	    class JSRunnable implements Runnable {
	        private X5WebView webView;
	        private String jsString;
	        JSRunnable(X5WebView w, String s) {
	            webView = w;
	            jsString = s;
            }

            public void run() {
	            try {
                    webView.evaluateJavascript(jsString, null);
                } catch (Exception e) {
	                Log.d("callJS", e.getLocalizedMessage());
	                e.printStackTrace();
                }
            }
        }
        this.runOnUiThread(new JSRunnable(mWebView,"Core.callJS(\'" + msg + "\');"));
    }

    public ScreenRecorder getScreenRecorder() {
        if (!ScreenRecorder.isDeviceSupport()) {
	        Toast.makeText(this, R.string.record_not_support, Toast.LENGTH_LONG);
	        return null;
        }
	    if (mScreenRecorder == null) {
	        mScreenRecorder = new ScreenRecorder(this);
        }
        return mScreenRecorder;
    }
}
