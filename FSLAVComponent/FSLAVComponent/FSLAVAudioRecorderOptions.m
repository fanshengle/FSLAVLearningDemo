//
//  FSLAVAudioRecorder_m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioRecorderOptions.h"

@implementation FSLAVAudioRecorderOptions

+ (instancetype)defaultOptions{
    return [super defaultOptions];
}

#pragma mark --- setter getter
- (void)setRecordQuality:(FSLAVAudioRecordQuality)recordQuality{
    if(_recordQuality == recordQuality) return;
    _recordQuality = recordQuality;
    
    switch (recordQuality)
    {
        case  FSLAVAudioRecordQuality_min:
        {
            self.recordSampleRate = FSLAVAudioRecordSampleRate_16000Hz;
            self.recordBitRate = _audioSetting.audioChannels == 1 ? FSLAVAudioRecordBitRate_32Kbps : FSLAVAudioRecordBitRate_48Kbps;
            self.recordBitDepth = FSLAVAudioRecordBitDepth_8d;
        }
            break;
        case  FSLAVAudioRecordQuality_Low:
        {
            self.recordSampleRate = FSLAVAudioRecordSampleRate_22050Hz;
            self.recordBitRate = _audioSetting.audioChannels == 1 ? FSLAVAudioRecordBitRate_48Kbps : FSLAVAudioRecordBitRate_64Kbps;
            self.recordBitDepth = FSLAVAudioRecordBitDepth_16d;
        }
            break;
        case  FSLAVAudioRecordQuality_Medium:
        {
            self.recordSampleRate = FSLAVAudioRecordSampleRate_32000Hz;
            self.recordBitRate = _audioSetting.audioChannels == 1 ? FSLAVAudioRecordBitRate_64Kbps : FSLAVAudioRecordBitRate_96Kbps;
            self.recordBitDepth = FSLAVAudioRecordBitDepth_16d;
            
        }
            break;
        case  FSLAVAudioRecordQuality_High:
        {
            self.recordSampleRate = FSLAVAudioRecordSampleRate_44100Hz;
            self.recordBitRate = _audioSetting.audioChannels == 1 ? FSLAVAudioRecordBitRate_96Kbps : FSLAVAudioRecordBitRate_128Kbps;
            self.recordBitDepth = FSLAVAudioRecordBitDepth_16d;
            
        }
            break;
        case  FSLAVAudioRecordQuality_Max:
        {
            self.recordSampleRate = FSLAVAudioRecordSampleRate_48000Hz;
            self.recordBitRate = _audioSetting.audioChannels == 1 ? FSLAVAudioRecordBitRate_96Kbps : FSLAVAudioRecordBitRate_128Kbps;
            self.recordBitDepth = FSLAVAudioRecordBitDepth_24d;
        }
            break;
        default:
            self.recordSampleRate = FSLAVAudioRecordSampleRate_32000Hz;
            self.recordBitRate = _audioSetting.audioChannels == 1 ? FSLAVAudioRecordBitRate_64Kbps : FSLAVAudioRecordBitRate_96Kbps;
            self.recordBitDepth = FSLAVAudioRecordBitDepth_16d;
            break;
    }
}

- (void)setAudioChannels:(NSUInteger)audioChannels{
    if(_audioChannels == audioChannels) return;
    _audioChannels = audioChannels;
    self.audioSetting.audioChannels = _audioChannels;
}
- (NSUInteger)audioChannels{
    if (!_audioChannels) {
        
        _audioChannels = _audioChannels ? _audioChannels : 1;
    }
    return _audioChannels;
}

- (void)setRecordSampleRate:(FSLAVAudioRecordSampleRate)recordSampleRate{
    if(_recordSampleRate == recordSampleRate) return;
    _recordSampleRate = recordSampleRate;
    self.audioSetting.audioSampleRat = _recordSampleRate;
}

- (void)setRecordBitDepth:(FSLAVAudioRecordBitDepth)recordBitDepth{
    if(_recordBitDepth == recordBitDepth) return;
    _recordBitDepth = recordBitDepth;
    self.audioSetting.audioLinearBitDepth = _recordBitDepth;
}

- (void)setRecordBitRate:(FSLAVAudioRecordBitRate)recordBitRate{
    if(_recordBitRate == recordBitRate) return;
    _recordBitRate = recordBitRate;
    self.audioSetting.encoderBitRate = _recordBitRate;
}

- (FSLAVEncodeAudioSetting *)audioSetting{
    if (!_audioSetting) {
        _audioSetting = [FSLAVEncodeAudioSetting PCMAudioSetting];
    }
    return _audioSetting;
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
    
    _isAcousticTimer = NO;

    //修改父类的默认项
    _meidaType = FSLAVMediaTypeAudio;
    _outputFileType = FSLAVAudioOutputFileTypeM4A;
    _outputFileName = @"audioRecordFile";
    _saveSuffixFormat = @"m4a";
    
    //设置该类的默认项
    self.audioChannels = 1;
    self.recordQuality = FSLAVAudioRecordQuality_Default;
}

@end
