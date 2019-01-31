package com.openew.game.utils;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.icu.util.Output;
import android.media.MediaRecorder;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.SparseIntArray;
import android.view.Surface;
import android.widget.Toast;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import com.openew.game.sdkcommon.SDKShareListener;
import com.openew.launcher.R;

@TargetApi(Build.VERSION_CODES.LOLLIPOP)
public class ScreenRecorder {

    private Activity mContext;
    public static final int REQUEST_PER_CODE = 8965;
    public static final int REQUEST_PRJ_CODE = 8966;
    private String TAG = "ScreenRecorder";
    private final String FILE_NAME = "BattleVideo";
    private int mScreenDensity;
    private int mDisplayWidth;
    private int mDisplayHeight;
    private MediaProjectionManager mProjectionManager;
    private MediaProjection mMediaProjection;
    private VirtualDisplay mVirtualDisplay;
    private MediaProjection.Callback mMediaProjectionCallback;
    private MediaRecorder mMediaRecorder;
    private boolean mIsRecording;
    private static final SparseIntArray ORIENTATIONS = new SparseIntArray();

    static {
        ORIENTATIONS.append(Surface.ROTATION_0, 90);
        ORIENTATIONS.append(Surface.ROTATION_90, 0);
        ORIENTATIONS.append(Surface.ROTATION_180, 270);
        ORIENTATIONS.append(Surface.ROTATION_270, 180);
    }

    abstract public class StartRecordListener {
        public void onComplete(boolean Success) {}
    }

    private StartRecordListener mStartLsn = null;

    public ScreenRecorder(Activity context) {
        mContext = context;

        DisplayMetrics metrics = new DisplayMetrics();
        mContext.getWindowManager().getDefaultDisplay().getMetrics(metrics);
        mScreenDensity = metrics.densityDpi;
        mDisplayWidth = metrics.widthPixels;
        mDisplayHeight = metrics.heightPixels;

        mProjectionManager = (MediaProjectionManager) mContext
                .getSystemService(Context.MEDIA_PROJECTION_SERVICE);
        mMediaProjection = null;
        mVirtualDisplay = null;
        mMediaRecorder = null;

        mIsRecording = false;
    }

    public void startRecord(StartRecordListener startLsn) {
        if (mIsRecording) {
            startLsn.onComplete(false);
            return;
        }
        mStartLsn = startLsn;
        // 检查权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            String[] permissions = {
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    Manifest.permission.RECORD_AUDIO
            };
            boolean allGranted = true;
            for (String permission : permissions) {
                if (mContext.checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (!allGranted) {
                mContext.requestPermissions(permissions, ScreenRecorder.REQUEST_PER_CODE);
            } else {
                start();
            }
        } else {
            start();
        }
    }

    public void onPermissionGranted() {
        start();
    }

    public void onPermissionDenied() {
        Toast.makeText(mContext, R.string.record_permission_hint, Toast.LENGTH_SHORT).show();
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode != Activity.RESULT_OK) {
            Toast.makeText(mContext, R.string.record_permission_hint, Toast.LENGTH_SHORT).show();
            mStartLsn.onComplete(false);
            return;
        }
        mMediaProjectionCallback = new MediaProjection.Callback() {
            @Override
            public void onStop() {
                ScreenRecorder.this.stop();
            }
        };
        // Retrieve the MediaProjection obtained from a successful screen capture request.
        // Will be null if the result from the startActivityForResult() is anything other than RESULT_OK.
        mMediaProjection = mProjectionManager.getMediaProjection(resultCode, data);
        mMediaProjection.registerCallback(mMediaProjectionCallback, null);
        start();
    }

    private VirtualDisplay createVirtualDisplay() {
        return mMediaProjection.createVirtualDisplay(TAG, mDisplayWidth, mDisplayHeight,
                mScreenDensity, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mMediaRecorder.getSurface(), null, null);
    }

    private void initRecorder() {
        try {
            // 初始化recorder
            mMediaRecorder = new MediaRecorder();
            mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mMediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
            mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
            mMediaRecorder.setOutputFile(Environment.
                    getExternalStoragePublicDirectory(Environment.
                            DIRECTORY_DOWNLOADS) + FILE_NAME + ".mp4");
            mMediaRecorder.setVideoSize(mDisplayWidth, mDisplayHeight);
            mMediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
            mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            mMediaRecorder.setVideoEncodingBitRate(1024 * 1000);
            mMediaRecorder.setVideoFrameRate(60);
            int rotation = mContext.getWindowManager().getDefaultDisplay().getRotation();
            int orientation = ORIENTATIONS.get(rotation + 90);
            mMediaRecorder.setOrientationHint(orientation);
            mMediaRecorder.prepare();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    private void start() {
        if (mMediaProjection == null) {
            // A screen capture session can be started through MediaProjectionManager.createScreenCaptureIntent().
            // This grants the ability to capture screen contents, but not system audio.
            mContext.startActivityForResult(mProjectionManager.createScreenCaptureIntent(), REQUEST_PRJ_CODE);
            return;
        }
        initRecorder();
        mVirtualDisplay = createVirtualDisplay();
        mMediaRecorder.start();
        mIsRecording = true;
        if (mStartLsn != null) {
            mStartLsn.onComplete(true);
        }
    }

    public void stopRecord() {
        if (!mIsRecording) {
            return;
        }
        stop();
    }

    private void stop() {
        mMediaRecorder.stop();
        mMediaRecorder.release();
        mMediaRecorder = null;
        if (mVirtualDisplay != null) {
            mVirtualDisplay.release();
            mVirtualDisplay = null;
        }
        destroyMediaProjection();
        mIsRecording = false;
    }

    private void destroyMediaProjection() {
        if (mMediaProjection != null) {
            mMediaProjection.unregisterCallback(mMediaProjectionCallback);
            mMediaProjection.stop();
            mMediaProjection = null;
        }
        Log.i(TAG, "MediaProjection stopped");
    }

    public void saveToPhoto() {
        if (mIsRecording) {
            stop();
        }
        File videoFile = new File(Environment.
                getExternalStoragePublicDirectory(Environment.
                        DIRECTORY_DOWNLOADS) + FILE_NAME + ".mp4");
        String path = videoFile.getAbsolutePath();
        ContentValues values = new ContentValues(3);
        values.put(MediaStore.Video.Media.TITLE, mContext.getResources()
                        .getString(R.string.app_name));
        values.put(MediaStore.Video.Media.MIME_TYPE, "video/mp4");
        values.put(MediaStore.Video.Media.DATA,
                path.substring(0, path.length() - 4)
                        + (int)(Math.random() * 100000) + ".mp4");
        Uri mediaUri = mContext.getContentResolver().insert(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values);
        try {
            InputStream is = new FileInputStream(videoFile);
            OutputStream os = mContext.getContentResolver().openOutputStream(mediaUri);
            byte[] buffer = new byte[1024 * 1024];
            int len;
            while ((len = is.read(buffer)) != -1) {
                os.write(buffer, 0, len);
            }
            os.flush();
            is.close();
            os.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        mContext.sendBroadcast(new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, mediaUri));
    }

    public Uri getRecentVideoUri() {
        File videoFile = new File(Environment.
                getExternalStoragePublicDirectory(Environment.
                        DIRECTORY_DOWNLOADS) + FILE_NAME + ".mp4");
        return Uri.fromFile(videoFile);
    }

    public void onDestroy() {
        destroyMediaProjection();
    }

    public static boolean isDeviceSupport() {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP;
    }
}
