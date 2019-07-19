//
// Created by Clear Hu on 2018/6/25.
//

#include <math.h>
#include "AudioPitch.h"
#include "fslAVComponent_Utils.h"

namespace fslAVComponent {
    /****************************** AudioPitchCalc *********************************/
    /**
     * 变调计算类
     *
     * @param sampleRate 音频采样率
     * @param speedRatio 速度比例
     */
    AudioPitchCalc::AudioPitchCalc(uint32_t sampleRate, float speedRatio){
        _sampleRate = sampleRate;
        _speedRatio = speedRatio;
    }

    AudioPitchCalc::~AudioPitchCalc() {
        if (_stretch == nullptr) return;
        delete _stretch;
        _stretch = nullptr;
    }

    /** 处理变调 */
    void
    AudioPitchCalc::process(TBuffer input, TBuffer calBuffer, bool eos) {
        _stretch->process(input, calBuffer, eos);
    }

    /** 重采样后转换为输出数据 */
    void AudioPitchCalc::resample(TBuffer input, TBuffer output, float scale) {
        input->position(0);

        // 输入采样点数
        uint32_t inSamples = input->remaining() / 2;
        uint32_t outSamples = output->remaining() / 2;

        // 需要的输出采样点数
        uint32_t needOutSamples;
        if (scale < 1) {
            needOutSamples = (uint32_t) floor(inSamples / scale);
        } else {
            needOutSamples = (uint32_t) ceil(inSamples / scale);
        }

        int16_t *inPtr = (int16_t *) input->currentPtr();
        int16_t *outPtr = (int16_t *) output->currentPtr();
        int16_t start, end;
        float reduce;

        uint32_t j = min(needOutSamples, outSamples);

        for (uint32_t i = 0, m = j - 1; i < j; i++, outPtr++) {
            // 输入绝对小数位
            float inPosUnitF = i * scale;
            uint32_t inPreUnitPos = (uint32_t) floor(inPosUnitF);
            uint32_t inNextUnitPos = (uint32_t) ceil(inPosUnitF);

            // 整数位和结尾，直接填充
            if (i == m || inPreUnitPos == inNextUnitPos || inNextUnitPos == inSamples) {
                *outPtr = inPtr[inPreUnitPos];
                continue;
            }

            start = inPtr[inPreUnitPos];
            end = inPtr[inNextUnitPos];
            reduce = start + (end - start) * (inPosUnitF - inPreUnitPos);

            *outPtr = (int16_t) max(min((int32_t) reduce, 32767), -32768);
        }

        input->clear();
        output->move(j * 2);
        output->flip();
    }

    /** 变速不变调计算类 */
    class AudioPitchSpeed : public AudioPitchCalc {
    public:
        AudioPitchSpeed(uint32_t sampleRate, float speedRatio):AudioPitchCalc(sampleRate, speedRatio){
            _stretch = new AudioStretch(sampleRate, speedRatio);
        }
        /** 计算变调 */
        virtual TBuffer
        calPitch(TBuffer input, TBuffer calBuffer, bool eos) override {
            process(input, calBuffer, eos);
            input->clear();
            return calBuffer;
        }
    };
    
    /** 升调计算类 处理升调 = 减速(增加数据) + 下采样(抽取) -> 先减速后采样 (传入原始采样率) */
    class AudioPitchUp : public AudioPitchCalc {
    public:
        AudioPitchUp(uint32_t sampleRate, float speedRatio):AudioPitchCalc(sampleRate, speedRatio){
            _stretch = new AudioStretch(sampleRate, 1.0f / speedRatio);
        }
        
        /** 计算变调 */
        virtual TBuffer
        calPitch(TBuffer input, TBuffer calBuffer, bool eos) override {
            process(input, calBuffer, eos);
            input->clear();
            resample(calBuffer, input, _speedRatio);
            return input;
        }
    };
    
    /** 降调计算类 处理降调 = 加速(减少数据) + 上采样(插值) -> 先采样后加速 (传入采样后采样率) */
    class AudioPitchDown : public AudioPitchCalc {
    public:
        AudioPitchDown(uint32_t sampleRate, float speedRatio):AudioPitchCalc(sampleRate, speedRatio){
            _stretch = new AudioStretch(sampleRate, 1.0f / speedRatio);
        }
        /** 计算变调 */
        virtual TBuffer
        calPitch(TBuffer input, TBuffer calBuffer, bool eos) override {
            resample(input, calBuffer, _speedRatio);
            process(calBuffer, input, eos);
            calBuffer->clear();
            return input;
        }
    };

    AudioPitchInfo::~AudioPitchInfo() {
        if (pitchModel != nullptr) {
            delete pitchModel;
            pitchModel = nullptr;
        }

        if (convert != nullptr) {
            delete convert;
            convert = nullptr;
        }
    }

    /****************************** AudioPitch *********************************/
    /** 音频变调接口 */
    AudioPitch::AudioPitch(AudioInfo info) {
        _inputInfo = info;
    }

    AudioPitch::~AudioPitch() {
        releaseLister();
        flush();
        _minBuffer = nullptr;
        _maxBuffer = nullptr;
    }

    /** 释放监听对象 */
    void AudioPitch::releaseLister() {
        if (_listener == nullptr) return;

        delete _listener;
        _listener = nullptr;
    }

    /** 媒体监听对象 */
    void AudioPitch::setMediaListener(MediaListener *listener) {
        releaseLister();
        _listener = listener;
    }

    /** 切换采样格式 */
    void AudioPitch::changeFormat(AudioInfo info) {
        _inputInfo = info;
        init();
    }

    /**
     * 改变音频播放速度 [变速不变调, 音调设置将失效]
     *
     * @param speed 0 > speed
     */
    void AudioPitch::changeSpeed(float speed) {
        if (speed <= 0 || _speed == speed) return;
        _speed = speed;
        _pitch = 1;
        init();
    }

    /**
     * 改变音频音调 [速度设置将失效]
     *
     * @param pitch 0 > pitch [大于1时声音升调，小于1时为降调]
     */
    void AudioPitch::changePitch(float pitch) {
        if (pitch <= 0 || _pitch == pitch) return;
        _pitch = pitch;
        _speed = 1;
        init();
    }

    /** 是否正在处理变调 */
    bool AudioPitch::needPitch() {
        return _needPitch;
    }

    /** 重置时间戳 */
    void AudioPitch::reset() {
        _pitch = 1;
        _speed = 1;
        init();
    }

    /** 刷新数据 */
    void AudioPitch::flush() {
        _currentTaskId = Utils::timeMs();
        synchronized(_mutex) {
            if (_sampleInfo) _sampleInfo.reset();
            _sampleInfo = nullptr;
            _currentCache = nullptr;
            _tempCaches.clear();
        }
    }

    /** 重建缓存 */
    void AudioPitch::rebuildCaches(TPitchInfo info) {
        if (!info || _listener == nullptr) return;
        synchronized(_mutex) {
            _currentCache = nullptr;
            _minBuffer = _listener->createBuffer(info->cacheTimes * 1024 * 2);
            _maxBuffer = _listener->createBuffer(_minBuffer->capacity() * info->cacheTimes);
            _tempCaches.clear();
            for (int i = 0, j = info->tempCount; i < j; ++i) {
                TBuffer ptr = _listener->createBuffer(info->inByteLength);
                _tempCaches.push_back(ptr);
            }
        }
    }

    /** 初始化 */
    void AudioPitch::init() {
        flush();
        _needPitch = (_speed != 1 || _pitch != 1);
        if (!_needPitch) return;

        // 升调 = 减速(增加数据) + 下采样(抽取) -> 先减速后采样 (传入原始采样率)
        // 降调 = 加速(减少数据) + 上采样(插值) -> 先采样后加速 (传入采样后采样率)

        TPitchInfo info = make_shared<AudioPitchInfo>();
        info->taskId = _currentTaskId;
        // mPitch和mSpeed两个有一个为1，互斥关系
        info->scale = _pitch * _speed;

        _outputInfo = {(uint8_t) 1, (uint8_t) 16, (uint32_t) (_inputInfo.sampleRate / info->scale)};

        if (!AudioConvertFactory::build(_inputInfo, _outputInfo, info->convert)) {
            LOGE("AudioPitch unsupport audio format.");
            return;
        }

        info->inSampleRate = _inputInfo.sampleRate;
        info->inUnitLength = (uint32_t) _inputInfo.channel * (_inputInfo.bitWidth / 8);
        info->inByteLength = (uint32_t) (1024 * (_inputInfo.channel * (_inputInfo.bitWidth / 8)));
        info->outUnitLength = (uint32_t) _outputInfo.channel * (_outputInfo.bitWidth / 8);
        info->cacheTimes = (uint32_t) ceil(info->scale < 1 ? 1 / info->scale : info->scale);
        info->tempCount = info->cacheTimes * 4;

        if (_speed != 1)info->pitchModel = new AudioPitchSpeed(info->inSampleRate, info->scale);
        else if (_pitch > 1)info->pitchModel = new AudioPitchUp(info->inSampleRate, info->scale);
        else if (_pitch < 1)info->pitchModel = new AudioPitchDown(info->inSampleRate, info->scale);
        else {
            _needPitch = false;
            LOGE("AudioPitch incorrect args: pitch[%f], speed[%f]", _pitch, _speed);
            return;
        }

        rebuildCaches(info);
        _sampleInfo = info;
    }

    /** 通知监听器 */
    void AudioPitch::notifyListener(TBuffer buffer) {
        if (_listener == nullptr) return;
        _listener->onMediaOutputBuffer(buffer);
    }

    /** 计算时间戳 [微秒] */
    int64_llu AudioPitch::calTimestampUs(TPitchInfo info) {
        // 原始时间戳
        int64_llu orginUs =
                ((int64_llu) info->frameCount * 1024000000) / info->inSampleRate +
                info->prefixTimeUs;
        return orginUs;
    }

    /** 没有处理完整的缓存 */
    TBuffer AudioPitch::unfullBuffer() {
        TBuffer cache = nullptr;
        synchronized(_mutex) {
            cache = _currentCache;
            _currentCache = nullptr;
        }
        return cache;
    }

    /** 返回没有处理完整的缓存 */
    void AudioPitch::backUnfullBuffer(TBuffer cache, TPitchInfo info) {
        if (!cache || info->taskId != _currentTaskId) return;
        synchronized(_mutex) {
            _currentCache = cache;
        }
    }

    /** 出列一个输入缓存 */
    TBuffer AudioPitch::dequeueInputBuffer() {
        TBuffer cache = nullptr;
        synchronized(_mutex) {
            if (_tempCaches.size() > 0) {
                cache = _tempCaches.front();
                _tempCaches.erase(_tempCaches.begin());
                cache->clear();
            }
        }
        return cache;
    }

    /** 出列一个输入缓存 或创建一个新缓存 */
    TBuffer AudioPitch::dequeueInputBufferOrBuild(TPitchInfo info) {
        if (info->taskId != _currentTaskId) return nullptr;

        TBuffer cache = dequeueInputBuffer();
        if (cache) {
            cache->infoPtr()->timeUs = calTimestampUs(info);
        }
        return cache;
    }

    /** 添加到输出缓存队列 */
    void AudioPitch::appendOutputQueue(TBuffer cache, TPitchInfo info) {
        if (info->taskId != _currentTaskId) return;

        synchronized (_mutex) {
            cache->freshInfo();
            notifyListener(cache);
            _tempCaches.push_back(cache);
            info->frameCount++;
        }
    }

    /**
     * 通知转换结束
     * @return 是否存在剩余数据
     */
    bool AudioPitch::notifyEOS() {
        if (!_needPitch) return false;

        // 防止线程外数据修改
        TPitchInfo info = _sampleInfo;
        if (!info || info->taskId != _currentTaskId) return false;

        if (_minBuffer->position() < 1) return false;

        _minBuffer->flip();
        convertToOutput(_minBuffer, nullptr, info, true);
        return true;
    }

    /***
     * 入列缓存
     * @param inputBuffer 输入缓存
     * @param bufferInfo 缓存信息
     * @return 是否已处理
     */
    bool AudioPitch::queueInputBuffer(TBuffer input) {
        if (!_needPitch) {
            // 直接传递采样数据
            notifyListener(input);
            return true;
        }

        // 防止线程外数据修改
        TPitchInfo info = _sampleInfo;
        if (input->buffer() == nullptr || input->infoPtr()->size < 1 || !info ||
            info->taskId != _currentTaskId)
            return true;

        // 为第一帧
        if (!info->prefixSeted) {
            info->prefixSeted = true;
            info->frameCount = 0;
            info->prefixTimeUs = input->infoPtr()->timeUs;
        }

        return process(input, info);
    }

    /** 处理变调 */
    bool AudioPitch::process(TBuffer input, TPitchInfo info) {
        if (!input->hasRemaining()) return true;

        // 输入采样点数
        uint32_t inSamples = input->remaining() / info->inUnitLength;
        // 输出采样点数
        uint32_t outSamples = _minBuffer->remaining() / info->outUnitLength;

        // 转换为Short缓存
        info->convert->i2o(input, _minBuffer, min(inSamples, outSamples));

        bool isEos = false;
        // 是否到结尾
        if (!input->hasRemaining()) isEos = input->flagEndOfStream();

        // 累积缓存已经用完，开始执行变速
        if (!_minBuffer->hasRemaining() || isEos) {
            _minBuffer->flip();
            TBuffer buffer = info->pitchModel->calPitch(_minBuffer, _maxBuffer, isEos);
            if (!convertToOutput(buffer, input, info, isEos)) return true;
        }

        return process(input, info);
    }

    /** 转换为输出数据 */
    bool AudioPitch::convertToOutput(TBuffer buffer, TBuffer input, TPitchInfo info, bool isEos) {
        TBuffer cache = unfullBuffer();
        if (!cache) cache = dequeueInputBufferOrBuild(info);

        if (!cache) {
            LOGE("AudioPitch can not queueInputBuffer, is forgot releaseOutputBuffer?");
            return false;
        }

        // 输入输出采样点数
        uint32_t inSamples, outSamples;

        buffer->position(0);
        while (buffer->hasRemaining()) {
            // 输入采样点数
            inSamples = buffer->remaining() / info->outUnitLength;
            // 输出采样点数
            outSamples = cache->remaining() / info->inUnitLength;

            info->convert->o2i(buffer, cache, min(inSamples, outSamples));

            // 理论应该输出缓存全部写完，如果还有空余说明输入数据已经读完，或者出现了总数不一致BUG
            if (cache->hasRemaining()) {
                if (buffer->hasRemaining()) {
                    LOGE("AudioPitch convertToOutput count error: input[%d], output[%d]",
                         buffer->remaining(), cache->remaining());
                }
                break;
            }

            // 刚好两个数据结尾一致
            if (!buffer->hasRemaining()) break;

            appendOutputQueue(cache, info);
            cache = dequeueInputBufferOrBuild(info);
            // 无法获取缓存 证明被flush
            if (!cache) return true;
        }

        buffer->clear();
        // 缓存还没有处理完成

        if (isEos || !cache->hasRemaining()) {
            if (input) cache->infoPtr()->flags = input->infoPtr()->flags;
            appendOutputQueue(cache, info);
            return true;
        }

        backUnfullBuffer(cache, info);
        return true;
    }
}
