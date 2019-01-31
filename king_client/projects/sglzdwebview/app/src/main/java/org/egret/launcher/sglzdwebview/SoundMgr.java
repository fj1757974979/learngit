package org.egret.launcher.sglzdwebview;

import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.util.Log;

import java.io.IOException;
import java.security.spec.ECField;
import java.util.HashMap;

public class SoundMgr {
    private static SoundPool _soundPool;
    private static boolean _init = false;
    private static HashMap<String, Integer> _soundCache;
    private static MainActivity _mainActivity;
    private static MediaPlayer _musicPlayer;
    private static String _currentMusic = null;
    private static float _soundVolume = 1;
    private static float _musicVolume = 1;

    public static void init(MainActivity activity) {
        if (!_init) {
            _soundPool = new SoundPool(3, AudioManager.STREAM_SYSTEM, 5);
            _soundPool.setOnLoadCompleteListener(new SoundPool.OnLoadCompleteListener() {
                @Override
                public void onLoadComplete(SoundPool soundPool, int sampleId, int status) {
                    soundPool.play(sampleId, _soundVolume, _soundVolume, 1, 0, 1);
                }
            });

            _soundCache = new HashMap<String, Integer>();
            _mainActivity = activity;
            _init = true;

            _musicPlayer = new MediaPlayer();
            _musicPlayer.setAudioStreamType(AudioManager.STREAM_SYSTEM);
            _musicPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override
                public void onPrepared(MediaPlayer mediaPlayer) {
                    _musicPlayer.setVolume(_musicVolume, _musicVolume);
                    _musicPlayer.setLooping(true);
                    mediaPlayer.start();
                }
            });
        }
    }

    public static void destroy() {
        if (!_init) return;
        _soundPool.release();
        _soundPool = null;
        _init = false;
        _musicPlayer.release();
        _musicPlayer = null;
    }

    private static int getSoundId(String path, SoundPool pool) throws IOException {
        if (!_init) return 0;

        if (_soundCache.containsKey(path)) {
            return _soundCache.get(path);
        }
        AssetFileDescriptor file = _mainActivity.getAssets().openFd(path);
        int id = pool.load(file, 1);
        _soundCache.put(path, id);
        return id;
    }

    public static void playSound(String path, float volume) {
        _soundVolume = volume;
        if (!_init) return;
        try {
            int id = getSoundId(path, _soundPool);
            _soundPool.play(id, volume, volume, 1, 0, 1);
        } catch (Exception e) {
            Log.d("sound", e.getLocalizedMessage());
            e.printStackTrace();
        }
    }

    public static void playMusic(String path, float volume)  {
        _musicVolume = volume;
        if (!_init) return;

        if (_musicPlayer.isPlaying()) {
            _musicPlayer.stop();
            _musicPlayer.reset();
        }

        try {
            AssetFileDescriptor fd = _mainActivity.getAssets().openFd(path);
            _musicPlayer.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
            _musicPlayer.prepareAsync();
            //_musicPlayer.start();
        } catch (Exception e) {
            Log.e("sound", e.getLocalizedMessage());
            e.printStackTrace();
        }
    }

    public static void stopMusic() {
        if (!_init) return;
        _musicPlayer.stop();
        _musicPlayer.reset();
    }

    public static void setMusicVolume(float volume) {
        _musicVolume = volume;
        if (!_init) return;
        _musicPlayer.setVolume(volume, volume);
    }
}
