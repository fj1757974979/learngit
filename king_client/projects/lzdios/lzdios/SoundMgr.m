//
//  SoundMgr.m
//  lzdios
//
//  Created by 兰清 on 2018/7/27.
//  Copyright © 2018 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SoundMgr.h"
#import <AVFoundation/AVFoundation.h>

@interface SoundMgr ()<AVAudioPlayerDelegate>{
}
@end

static SoundMgr *mgr = nil;
@implementation SoundMgr {
    AVAudioPlayer *_audioPlayer;
    NSString *_currentMusic;
    NSMutableDictionary *_soundMap;
    NSCountedSet<AVAudioPlayer *> *_releaseSet;
}

+ (id) sharedMgr {
    if (!mgr) {
        mgr = [[SoundMgr alloc] init];
    }
    return mgr;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        _currentMusic = nil;
        _audioPlayer = nil;
        _soundMap = [[NSMutableDictionary alloc] init];
        _releaseSet = [[NSCountedSet<AVAudioPlayer *> alloc] init];
    }
    return self;
}

- (void)dealloc{
    _currentMusic = nil;
    _currentMusic = nil;
    [_soundMap removeAllObjects];
    [_releaseSet removeAllObjects];
    _soundMap = nil;
    _releaseSet = nil;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if ([_releaseSet countForObject:player] > 0) {
        [_releaseSet removeObject:player];
    }
}

- (void)playSound:(NSString*)sound volume:(NSNumber *)volume {
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    
    AVAudioPlayer *audioPlayer = [_soundMap objectForKey:sound];
    if (audioPlayer && ![audioPlayer isPlaying]) {
        audioPlayer.volume = volume.floatValue;
        [audioPlayer play];
        return;
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"sound/%@", sound]
                                                         ofType:@"mp3"];
    if (!filePath) {
        NSLog(@"没找到声音文件 %@", sound);
        return;
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    
    if (error) {
        NSLog(@"初始化播放器错误,错误：%@",error.localizedDescription);
        return;
    }
    audioPlayer.numberOfLoops = 0;//设置循环次数，0表示不循环
    audioPlayer.volume = volume.floatValue;
    audioPlayer.delegate = self;
    [audioPlayer prepareToPlay];//加载音乐文件到缓存，还不会播放
    [audioPlayer play];
    if (![_soundMap objectForKey:sound]) {
        [_soundMap setObject:audioPlayer forKey:sound];
    } else {
        [_releaseSet addObject:audioPlayer];
    }
}

- (void)playMusic:(NSString*)music volume:(NSNumber *)volume {
    
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    
    if (_audioPlayer && _currentMusic && [music isEqualToString:_currentMusic]) {
        if (![_audioPlayer isPlaying]) {
            [_audioPlayer play];
        }
        _audioPlayer.volume = volume.floatValue;
        return;
    }
    
    if (_audioPlayer && ![music isEqualToString:_currentMusic]) {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    
    _currentMusic = [NSString stringWithString:music];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"sound/%@", music]
                                                         ofType:@"mp3"];
    if (!filePath) {
        NSLog(@"没找到声音文件 %@", music);
        return;
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&error];
    
    if (error) {
        NSLog(@"初始化播放器错误,错误：%@",error.localizedDescription);
        return;
    }
    
    _audioPlayer.numberOfLoops = -1;//设置循环次数，0表示不循环
    _audioPlayer.volume = volume.floatValue;
    [_audioPlayer prepareToPlay];//加载音乐文件到缓存，还不会播放
    [_audioPlayer play];
}

- (void)stopMusic {
    if (_audioPlayer && [_audioPlayer isPlaying]) {
        [_audioPlayer pause];
    }
}

- (void)setMusicVolume:(NSNumber *)volume {
    if (_audioPlayer) {
        _audioPlayer.volume = volume.floatValue;
    }
}



@end
