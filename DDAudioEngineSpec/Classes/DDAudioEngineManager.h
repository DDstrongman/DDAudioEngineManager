//
//  DDAudioEngineManager.h
//  DDAudioEngineManager
//
//  Created by DDLi on 2019/5/15.
//  Copyright © 2019 LittleLights. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDAudioEngineManager : NSObject

@property (nonatomic, strong) AVAudioEngine *audioEngine;///< 音频engine
@property (nonatomic, copy, readonly) NSString *audioPath;///< 音频文件夹存储位置

/**
 创建单实例

 @return 返回单实例
 */
+ (DDAudioEngineManager *)ShareInstance;
/**
 初始化音频engine，不需要主动调用，开始录音或者播放都会自动调用
 */
- (void)initAudioEngine;
/**
 释放音频engine
 */
- (void)releaseAudioEngine;
/**
 开始音频录音并写入指定路径

 @param engineBlock engine的录音block
 */
- (void)startAudioEngine:(void(^)(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when))engineBlock;
/**
 播放指定路径的音频

 @param audioPath 指定的沙河路经
 */
- (void)playAudioEngine:(NSURL *)audioPath;

@end

NS_ASSUME_NONNULL_END
