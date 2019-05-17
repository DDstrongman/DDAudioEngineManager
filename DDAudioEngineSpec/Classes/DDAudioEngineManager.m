//
//  DDAudioEngineManager.m
//  DDAudioEngineManager
//
//  Created by DDLi on 2019/5/15.
//  Copyright © 2019 LittleLights. All rights reserved.
//

#import "DDAudioEngineManager.h"

@interface DDAudioEngineManager ()

@property (nonatomic, strong) NSURL *recordFileUrl;///< 音频存储接口
@property (nonatomic, copy) NSString *audioPath;

@end

@implementation DDAudioEngineManager

+ (TWAudioUtil *)ShareInstance {
    static DDAudioEngineManager *sharedDDAudioEngineManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedDDAudioEngineManagerInstance = [[self alloc] init];
    });
    return sharedDDAudioEngineManagerInstance;
}

- (void)initAudioEngine {
    if (!self.audioEngine) {
        self.audioEngine = [[AVAudioEngine alloc] init];
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    [audioSession setPreferredSampleRate:(double)44100.0 error:&error];
    
    NSString * path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    _audioPath = [path stringByAppendingPathComponent:@"temp.wav"];
    self.recordFileUrl = [NSURL fileURLWithPath:_audioPath];
}

- (void)releaseAudioEngine {
    [[self.audioEngine inputNode] removeTapOnBus:0];
    [self.audioEngine stop];
}

- (void)startAudioEngine:(void(^)(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when))engineBlock {
    [self initAudioEngine];
    
    NSError *fileError;
    //设置参数
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   //采样率  8000/11025/22050/44100/96000（影响音频的质量）
                                   [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                                   // 音频格式
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   //采样位数  8、16、24、32 默认为16
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                   // 音频通道数 1 或 2
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                   //录音质量
                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
                                   nil];
    AVAudioFile *file = [[AVAudioFile alloc]initForWriting:self.recordFileUrl settings:recordSetting error:&fileError];
//    DDLog(@"path=====%@,error=====%@",self.recordFileUrl,fileError);
    
    AVAudioFormat *recordingFormat = [[self.audioEngine inputNode] outputFormatForBus:0];
    [[self.audioEngine inputNode] installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        NSError *writingError;
        [file writeFromBuffer:buffer error:&writingError];
        if (engineBlock) {
            engineBlock(buffer,when);
        }
    }];
    [self.audioEngine prepare];
    NSError *error;
    [self.audioEngine startAndReturnError:&error];
}

- (void)playAudioEngine:(NSURL *)audioPath {
    [self initAudioEngine];
    NSError *error;
    // Create AVAudioFile
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:audioPath error:&error];
    //    // Create AVAudioPCMBuffer
    //    AVAudioFormat *format = file.processingFormat;
    //    AVAudioFrameCount capacity = (AVAudioFrameCount)file.length;
    //    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:capacity];
    //    // Read AVAudioFile -> AVAudioPCMBuffer
    //    [file readIntoBuffer:buffer error:nil];
    
    AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
    [self.audioEngine attachNode:player];
    // 4. Connect player node to engine's main mixer
    AVAudioMixerNode *mixer = self.audioEngine.mainMixerNode;
    [self.audioEngine connect:player to:mixer format:[mixer outputFormatForBus:0]];
    //    AVAudioFormat *processingFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:file.processingFormat.streamDescription->mSampleRate channels:1 interleaved:false];
    //    [self.audioEngine connect:player to:self.audioEngine.outputNode format:processingFormat];
    [self.audioEngine startAndReturnError:nil];
    [player scheduleFile:file atTime:nil completionHandler:nil];
    [player play];
}

@end
