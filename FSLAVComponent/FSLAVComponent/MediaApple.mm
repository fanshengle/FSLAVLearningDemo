//
//  MediaApple.cpp
//  FSLAVComponent
//
//  Created by Clear Hu on 2018/7/22.
//  Copyright © 2018年 tutu. All rights reserved.
//

#include <stdio.h>
#include "MediaApple.h"

namespace fslAVComponent {
    /***************************** MediaBufferApple *************************************/
    /** Apple媒体缓存, 初始化byte大小 */
    MediaBufferApple::MediaBufferApple(uint32_t capacity) {
        AppleAudioData * media = new AppleAudioData();
        media->ptr = (int8_t *) calloc(capacity, sizeof(int8_t));
        _bufferPtr = media->ptr;
        _buffer = media;
        
        _capacity = capacity;
        setInfo({0, capacity, 0, -1});
        _created = true;
    }
    
    /** Apple媒体缓存, 传入外部Buffer */
    MediaBufferApple::MediaBufferApple(AppleAudioData * media) {
        if (!media || !media->ptr) return;
        _bufferPtr = media->ptr;
        _buffer = media;
        _capacity = media->info.size;
        
        setInfo(media->info);
        _created = false;
    }
    
    /** Apple媒体缓存, 传入外部Buffer */
    MediaBufferApple::~MediaBufferApple() {
        if (_buffer == nullptr) return;
        
        //LOGE("-------desss[%d], limit:[%d], capacity:[%d], size:[%d], %ld", _created, _limit, _capacity, _info.size,  (int64_t) (intptr_t) this);
        
        if (_bufferPtr != nullptr) {
            free(_bufferPtr);
        }
        
        delete (AppleAudioData *)_buffer;
        _buffer = nullptr;
        _bufferPtr = nullptr;
    }
    
    /** 是否读取到数据结尾 */
    bool MediaBufferApple::flagEndOfStream() {
        return ((_info.flags & 4) != 0);
    }
    
    /***************************** MediaAppleListener *************************************/
    /** Apple媒体监听对象 */
    MediaAppleListener::MediaAppleListener(lsqAudioBridgeBlock jListener) {
        _jListener = jListener;
    }
    
    MediaAppleListener::~MediaAppleListener() {
        if (_jListener == nullptr) return;
        _jListener = nullptr;
    }
    
    /** 媒体输出 */
    void MediaAppleListener::onMediaOutputBuffer(TBuffer buffer) {
        if (_jListener == nullptr){
            LOGE("onMediaOutputBuffer need set lsqAudioBridgeBlock");
            return;
        }

        AppleAudioData* result = (AppleAudioData *)buffer->buffer();
        result->info = buffer->info();
        _jListener(result);
    }
    
    /** 创建缓存 */
    TBuffer MediaAppleListener::createBuffer(uint32_t capacity) {
        return std::make_shared<MediaBufferApple>(capacity);
    };
}
