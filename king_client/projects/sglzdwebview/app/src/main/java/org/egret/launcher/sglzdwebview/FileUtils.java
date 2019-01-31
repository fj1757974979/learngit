package org.egret.launcher.sglzdwebview;
import android.content.res.AssetManager;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.io.InputStream;

/**
 * 创建文件 和 文件夹
 * Created by yu on 2016/8/21.
 */
public class FileUtils {

    private static final String TAG = "FileUtils";

    public static final int FLAG_SUCCESS = 1;//创建成功
    public static final int FLAG_EXISTS = 2;//已存在
    public static final int FLAG_FAILED = 3;//创建失败


    /**
     * 创建 单个 文件
     * @param filePath 待创建的文件路径
     * @return 结果码
     */
    public static int createFile(String filePath) {
        File file = new File(filePath);
        if (file.exists()) {
            Log.e(TAG,"The file [ " + filePath + " ] has already exists");
            return FLAG_EXISTS;
        }
        if (filePath.endsWith(File.separator)) {// 以 路径分隔符 结束，说明是文件夹
            Log.e(TAG,"The file [ " + filePath + " ] can not be a directory");
            return FLAG_FAILED;
        }

        //判断父目录是否存在
        if (!file.getParentFile().exists()) {
            //父目录不存在 创建父目录
            Log.d(TAG,"creating parent directory...");
            if (!file.getParentFile().mkdirs()) {
                Log.e(TAG,"created parent directory failed.");
                return FLAG_FAILED;
            }
        }

        //创建目标文件
        try {
            if (file.createNewFile()) {//创建文件成功
                Log.i(TAG, "create file [ " + filePath + " ] success");
                return FLAG_SUCCESS;
            }
        } catch (IOException e) {
            e.printStackTrace();
            Log.e(TAG,"create file [ " + filePath + " ] failed");
            return FLAG_FAILED;
        }

        return FLAG_FAILED;
    }

    public static boolean fileExists(String dirPath) {
        File dir = new File(dirPath);
        return dir.exists();
    }

    /**
     * 创建 文件夹
     * @param dirPath 文件夹路径
     * @return 结果码
     */
    public static int createDir (String dirPath) {

        File dir = new File(dirPath);
        //文件夹是否已经存在
        if (dir.exists()) {
            Log.w(TAG,"The directory [ " + dirPath + " ] has already exists");
            return FLAG_EXISTS;
        }
        if (!dirPath.endsWith(File.separator)) {//不是以 路径分隔符 "/" 结束，则添加路径分隔符 "/"
            dirPath = dirPath + File.separator;
        }
        //创建文件夹
        if (dir.mkdirs()) {
            Log.d(TAG,"create directory [ "+ dirPath + " ] success");
            return FLAG_SUCCESS;
        }

        Log.e(TAG,"create directory [ "+ dirPath + " ] failed");
        return FLAG_FAILED;
    }

    public static void copyFileOrDir(AssetManager mgr, String path, String dest) {
        //AssetManager assetManager = this.getAssets();
        String assets[] = null;
        try {
            assets = mgr.list(path);
            if (assets.length == 0) {
                copyFile(mgr, path, dest);
            } else {
                //String fullPath = "/data/data/" + this.getPackageName() + "/" + path;
                String fullPath = dest + "/" + path;
                File dir = new File(fullPath);
                if (!dir.exists())
                    dir.mkdir();
                for (int i = 0; i < assets.length; ++i) {
                    copyFileOrDir(mgr, path + "/" + assets[i], dest);
                }
            }
        } catch (IOException ex) {
            Log.e(TAG, "I/O Exception", ex);
        }
    }

    public static void copyFile(AssetManager mgr, String filename, String dest) {
        //AssetManager assetManager = this.getAssets();

        InputStream in = null;
        OutputStream out = null;
        try {
            in = mgr.open(filename);
            //String newFileName = "/data/data/" + this.getPackageName() + "/" + filename;
            String newFileName = dest + "/" + filename;
            out = new FileOutputStream(newFileName);

            byte[] buffer = new byte[1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
            in.close();
            in = null;
            out.flush();
            out.close();
            out = null;
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }

    }
}