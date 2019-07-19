//
//  MediaApple.h
//  FSLAVComponent
//
//  Created by Clear Hu on 2018/7/22.
//  Copyright © 2018年 tutu. All rights reserved.
//

#ifndef MediaApple_h
#define MediaApple_h

#include "MediaStruct.h"
#include "fslAVComponent_Utils.h"
#import <AVFoundation/AVFoundation.h>

namespace fslAVComponent {
    /** Apple音频数据 */
    class AppleAudioData{
    public:
        AppleAudioData(){}
        virtual ~AppleAudioData(){}
    public:
        /** 数据指针 */
        int8_t *ptr;
        /** 数据信息 */
        BufferInfo info;
    };
    
    /** Apple媒体缓存 */
    class MediaBufferApple : public MediaBuffer {
    public:
        /** Apple媒体缓存, 初始化byte大小 */
        MediaBufferApple(uint32_t capacity);
        
        /** Apple媒体缓存, 传入外部Buffer */
        MediaBufferApple(AppleAudioData * media);
        
        virtual ~MediaBufferApple() override;
        
    public:
        /** 是否读取到数据结尾 */
        virtual bool flagEndOfStream() override;
    private:
        bool _created = false;
    };
    
    /** lsqAudioBridgeBlock */
    typedef void(^lsqAudioBridgeBlock)(AppleAudioData *);
    
    /** Apple媒体监听对象 */
    class MediaAppleListener : public MediaListener {
    public:
        /** Apple媒体监听对象 */
        MediaAppleListener(lsqAudioBridgeBlock jListener);
        
        virtual ~MediaAppleListener() override;
        
    public:
        /** 媒体输出 */
        virtual void onMediaOutputBuffer(TBuffer buffer) override;
        
        /** 创建缓存 */
        virtual TBuffer createBuffer(uint32_t capacity) override;
        
    private:
        /** Apple监听对象 */
        lsqAudioBridgeBlock _jListener = nullptr;
    };
}

#endif /* MediaApple_h */
