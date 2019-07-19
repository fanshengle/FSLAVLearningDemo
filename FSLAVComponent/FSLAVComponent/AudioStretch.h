//
// Created by Clear Hu on 2018/6/25.
//

#ifndef DROID_SDK_JNI_AUDIOSTRETCH_H
#define DROID_SDK_JNI_AUDIOSTRETCH_H

#include "MediaStruct.h"

namespace fslAVComponent {
    /** 声音变速对象 */
    class AudioStretch {
    public:
        /**
         * 声音变速对象
         *
         * @param sampleRate 音频采样率
         * @param speedRatio 速度比例
         */
        AudioStretch(uint32_t sampleRate, float speedRatio);
        
        virtual ~AudioStretch();
        
    private:
        /** 不允许复制 */
        AudioStretch(const AudioStretch &) = delete;
        
        AudioStretch &operator=(const AudioStretch &) = delete;
        
    public:
        /** 处理变调 */
        bool process(TBuffer input, TBuffer output, bool eos);
    private:
        /** 准备转换 */
        void prepare(uint32_t sampleRate, float speedRatio);
        /** 初始化数据 */
        void initData(TBuffer input, TBuffer output);
        /** 填充输出数据 */
        void fillOutput(TBuffer output, bool eos);
        /** 创建Hann window */
        void makeHann(int32_t length);
        /** 关闭数据 */
        void close();
    private:
        /** 音频采样率 */
        uint32_t _sampleRate;
        /** 速度比例 */
        float _speedRatio;
        /** ola长度 */
        uint32_t _olaWinLength;
        /** ola步进 */
        uint32_t _olaStep;
        /** Hann window */
        float *_hann;
        
        /** 输入数据 */
        int16_t *_srcBuffer;
        uint32_t _srcBufferAllocSize;

        /** 输入数据长度 */
        uint32_t _srcBufferSize;
        /** 前一次剩余缓存使用长度 */
        uint32_t _preSrcRemainingSize;
        
        /** 处理后数据 */
        int16_t *_dstBuffer;
        uint32_t _dstBufferAllocSize;
        uint32_t _dstOutLimitSize;

        /** 处理后数据长度 */
        uint32_t _dstBufferSize;
        
        
        /** 抽取长度 */
        uint32_t _decimate;
        /** 总输入数据长度 */
        uint64_t _totalInputSize;
        /** 总输出数据长度 */
        uint64_t _totalOutputSize;
        /** 步进总数 */
        uint64_t _totalProcessOlaWWin;
        /** 前一次匹配索引 */
        uint64_t _preMatchSrcIndex;
    };
}

#endif //DROID_SDK_JNI_AUDIOSTRETCH_H
