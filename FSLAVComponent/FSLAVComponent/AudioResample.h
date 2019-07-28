//
// Created by Clear Hu on 2018/6/25.
//

#ifndef DROID_SDK_JNI_AUDIORESAMPLE_H
#define DROID_SDK_JNI_AUDIORESAMPLE_H

#include <vector>
#include <memory>

#include "AudioConvert.h"
#include "MediaStruct.h"
#include "Mutex.h"

using namespace std;

namespace fslAVComponent {

    /** 音频重采样信息 */
    class AudioResampleInfo {
    public:
        AudioResampleInfo() = default;

        virtual ~AudioResampleInfo();

    private:
        /** 不允许复制 */
        AudioResampleInfo(const AudioResampleInfo &) = delete;

        AudioResampleInfo &operator=(const AudioResampleInfo &) = delete;

    public:
        /** 输入采样点宽度 */
        uint32_t inUnitLength;
        /** 输出采样点宽度 */
        uint32_t outUnitLength;
        /** 输出采样率 */
        uint32_t outSampleRate;
        /** 输出缓存长度 */
        uint32_t outByteLength;
        /** 缓存总数 */
        uint32_t tempCount = 0;
        /** 输入输出采样比例 */
        float scale;
        /** 是已经设置时间头 */
        bool prefixSeted = false;
        /** 第一帧前置处理时间 */
        int64_llu prefixTimeUs = -1;
        /** 计算出的相对输入时间 */
        int64_llu inputTimeUs = 0;
        /** 前一个输入时间 */
        int64_llu preTimeUs = -1;
        /** 后一个输入时间 */
        int64_llu lastTimeUs = -1;
        /** 计算的总帧数 */
        uint64_t frameCount = 0;
        /** 任务ID */
        double taskId = -1;
        /** 音频转换接口 */
        AudioConvert *convert;
    };

    /** 音频重采样信息定义 */
    typedef shared_ptr<AudioResampleInfo> TResampleInfo;

    /** 音频重采样 */
    class AudioResample {
    public:
        AudioResample(AudioInfo info);

        virtual ~AudioResample();

    public:
        /** 媒体监听对象 */
        void setMediaListener(MediaListener *listener);

        /** 切换采样格式 */
        void changeFormat(AudioInfo info);

        /** 切换播放速度 */
        void changeSpeed(float speed);

        /** 改变音频序列 */
        void changeSequence(bool reverse);

        /** 设置开始时间戳 [微秒] */
        void setStartPrefixTimeUs(int64_llu startPrefixTimeUs);

        /** 是否需要重采样 */
        bool needResample();

        /** 重置时间戳 */
        void reset();

        /** 刷新数据 */
        void flush();

        /** 获取最后输入时间 [微秒] */
        int64_llu getLastInputTimeUs();

        /** 获取前置时间 [微秒] */
        int64_llu getPrefixTimeUs();

        /***
         * 入列缓存
         * @param inputBuffer 输入缓存 缓存信息
         * @return 是否已处理
         */
        bool queueInputBuffer(TBuffer inputBuffer);

        /**
         * 通知转换结束
         * @return 是否存在剩余数据
         */
        bool notifyEOS();

    private:
        /** 释放监听对象 */
        void releaseLister();

        /** 初始化 */
        void init();

        /** 重建缓存 */
        void rebuildCaches(TResampleInfo info);

        /** 通知监听器 */
        void notifyListener(TBuffer buffer);

        /** 反转数据 */
        TBuffer reverseBuffer(TBuffer inputBuffer);

        /** 处理重采样 */
        bool processResample(TBuffer input, TResampleInfo info);

        /** 计算时间戳 [微秒] */
        int64_llu calTimestampUs(TResampleInfo info);

        /** 没有处理完整的缓存 */
        TBuffer unfullBuffer();

        /** 返回没有处理完整的缓存 */
        void backUnfullBuffer(TBuffer cache, TResampleInfo info);

        /** 出列一个输入缓存 */
        TBuffer dequeueInputBuffer();

        /** 出列一个输入缓存 或创建一个新缓存 */
        TBuffer dequeueInputBufferOrBuild(TResampleInfo info);

        /** 添加到输出缓存队列 */
        void appendOutputQueue(TBuffer cache, TResampleInfo info);

        /** 计算输出数据的结束时间 */
        int64_llu getOutputCacheEndTimeUs(TBuffer cache, TResampleInfo info);

        /** 填充静音数据 */
        TBuffer fillMute(TBuffer cache, TResampleInfo info, uint32_t muteCount);

        /** 重采样数据 */
        void resample(TBuffer input, TBuffer cache, TResampleInfo info);

    private:
        /** 同步锁 */
        Mutex _mutex;
        /** 输出音频信息 */
        AudioInfo _outputInfo;
        /** 输入音频信息 */
        AudioInfo _inputInfo;
        /** 音频重采样信息 */
        TResampleInfo _sampleInfo;
        /** 播放速度 */
        float _speed = 1;
        /** 是否倒序播放 */
        bool _reverse = false;
        /** 是否需要重采样 */
        bool _needResample = false;
        /** 当前任务ID */
        double _currentTaskId;
        /** 开始时间戳 [微秒] */
        int64_llu _startPrefixTimeUs = -1;
        /** 媒体监听对象 */
        MediaListener *_listener = nullptr;
        /** 输入缓存 */
        TBuffer _inputCache;
        /** 正在处理的Cache */
        TBuffer _currentCache;
        /** 临时缓存队列 */
        vector<TBuffer> _tempCaches;
    };
}

#endif //DROID_SDK_JNI_AUDIORESAMPLE_H
