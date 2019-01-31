//
//  SoundMgr.h
//  lzdios
//
//  Created by 兰清 on 2018/7/27.
//  Copyright © 2018 egret. All rights reserved.
//

#ifndef SoundMgr_h
#define SoundMgr_h
#import <Foundation/Foundation.h>

@interface SoundMgr:NSObject {
    
}
+ (id)sharedMgr;
- (void)playSound:(NSString*)sound volume:(NSNumber *)volume;
- (void)playMusic:(NSString*)music volume:(NSNumber *)volume;
- (void)stopMusic;
- (void)setMusicVolume:(NSNumber *)volume;

@end
#endif /* SoundMgr_h */
