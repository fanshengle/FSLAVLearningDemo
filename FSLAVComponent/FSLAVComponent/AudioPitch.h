//
// Created by Clear Hu on 2018/6/25.
//

#ifndef DROID_SDK_JNI_AUDIOPITCH_H
#define DROID_SDK_JNI_AUDIOPITCH_H

#include <vector>
#include <memory>

#include "AudioConvert.h"
#include "MediaStruct.h"
#include "Mutex.h"
#include "AudioStretch.h"

using namespace std;

namespace fslAVComponent {
    /****************************** AudioPitchCalc *********************************/
    /** 变调计算类 */
    class AudioPitchCalc {
    public:
        /**
         * 变调计算类
         *
         * @param sampleRate 音频采样率
         * @param speedRatio 速度比例
         */
        AudioPitchCalc(uint32_t sampleRate, float speedRatio);
        virtual ~AudioPitchCalc();

    private:
        /** 不允许复制 */
        AudioPitchCalc(const AudioPitchCalc &) = delete;

        AudioPitchCalc &operator=(const AudioPitchCalc &) = delete;

    protected:
        /** 声音变速对象 */
        AudioStretch *_stretch;
        /** 音频采样率 */
        uint32_t _sampleRate;
        /** 速度比例 */
        float _speedRatio;
    protected:
        /** 处理变调 */
        void process(TBuffer input, TBuffer calBuffer, bool eos);

        /** 重采样后转换为输出数据 */
        static void resample(TBuffer input, TBuffer output, float scale);

    public:
        /** 计算变调 */
        virtual TBuffer
        calPitch(TBuffer input, TBuffer calBuffer, bool eos) = 0;
    };

    /****************************** AudioPitchInfo *********************************/
    /** 音频变调信息 */
    class AudioPitchInfo {
    public:
        AudioPitchInfo() = default;

        virtual ~AudioPitchInfo();

    private:
        /** 不允许复制 */
        AudioPitchInfo(const AudioPitchInfo &) = delete;

        AudioPitchInfo &operator=(const AudioPitchInfo &) = delete;

    public:
        /** 输入采样点宽度 */
        uint32_t inUnitLength;
        /** 输入采样率 */
        uint32_t inSampleRate;
        /** 输入缓存长度 */
        uint32_t inByteLength;
        /** 输出采样点宽度 */
        uint32_t outUnitLength;

        /** 缓存总数 */
        uint32_t tempCount = 0;
        /** 输入输出采样比例 */
        float scale;
        /** 是已经设置时间头 */
        bool prefixSeted = false;
        /** 第一帧前置处理时间 */
        int64_llu prefixTimeUs = -1;
        /** 计算的总帧数 */
        uint64_t frameCount = 0;
        /** 任务ID */
        double taskId = -1;
        /** 需要等待缓存次数 */
        uint32_t cacheTimes;
        /** 音频转换接口 */
        AudioConvert *convert;
        /** 变调模式 */
        AudioPitchCalc *pitchModel;
    };

    /** 音频变调信息定义 */
    typedef shared_ptr<AudioPitchInfo> TPitchInfo;

    /****************************** AudioPitch *********************************/
    /** 音频变调接口 */
    class AudioPitch {
    public:
        AudioPitch(AudioInfo info);

        virtual ~AudioPitch();

    public:
        /** 媒体监听对象 */
        void setMediaListener(MediaListener *listener);

        /** 切换采样格式 */
        void changeFormat(AudioInfo info);

        /**
         * 改变音频播放速度 [变速不变调, 音调设置将失效]
         *
         * @param speed 0 > speed
         */
        void changeSpeed(float speed);

        /**
         * 改变音频音调 [速度设置将失效]
         *
         * @param pitch 0 > pitch [大于1时声音升调，小于1时为降调]
         */
        void changePitch(float pitch);

        /** 是否正在处理变调 */
        bool needPitch();

        /** 重置时间戳 */
        void reset();

        /** 刷新数据 */
        void flush();

        /***
         * 入列缓存
         * @param inputBuffer 输入缓存
         * @param bufferInfo 缓存信息
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
        void rebuildCaches(TPitchInfo info);

        /** 通知监听器 */
        void notifyListener(TBuffer buffer);

        /** 计算时间戳 [微秒] */
        int64_llu calTimestampUs(TPitchInfo info);

        /** 没有处理完整的缓存 */
        TBuffer unfullBuffer();

        /** 返回没有处理完整的缓存 */
        void backUnfullBuffer(TBuffer cache, TPitchInfo info);

        /** 出列一个输入缓存 */
        TBuffer dequeueInputBuffer();

        /** 出列一个输入缓存 或创建一个新缓存 */
        TBuffer dequeueInputBufferOrBuild(TPitchInfo info);

        /** 添加到输出缓存队列 */
        void appendOutputQueue(TBuffer cache, TPitchInfo info);

        /** 处理变调 */
        bool process(TBuffer input, TPitchInfo info);

        /** 转换为输出数据 */
        bool convertToOutput(TBuffer buffer, TBuffer input, TPitchInfo info, bool isEos);

    private:
        /** 同步锁 */
        Mutex _mutex;
        /** 输出音频信息 */
        AudioInfo _outputInfo;
        /** 输入音频信息 */
        AudioInfo _inputInfo;
        /** 音频重采样信息 */
        TPitchInfo _sampleInfo;
        /** 播放速度 */
        float _speed = 1;
        /** 改变音频音调 */
        float _pitch = 1;
        /** 是否需要变调 */
        bool _needPitch = false;
        /** 当前任务ID */
        double _currentTaskId;
        /** 媒体监听对象 */
        MediaListener *_listener = nullptr;
        /** 正在处理的Cache */
        TBuffer _currentCache;
        /** 临时缓存队列 */
        vector<TBuffer> _tempCaches;
        /** 变调缩小数据缓存 */
        TBuffer _minBuffer;
        /** 变调扩充数据缓存 */
        TBuffer _maxBuffer;
    };
}

#endif //DROID_SDK_JNI_AUDIOPITCH_H
