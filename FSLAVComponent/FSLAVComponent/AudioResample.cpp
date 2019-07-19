//
// Created by Clear Hu on 2018/6/25.
//

#include <math.h>
#include "AudioResample.h"
#include "fslAVComponent_Utils.h"

namespace fslAVComponent {

    AudioResampleInfo::~AudioResampleInfo() {
        if (convert != nullptr) {
            delete convert;
            convert = nullptr;
        }
    }

    AudioResample::AudioResample(AudioInfo info) {
        _outputInfo = info;
    }

    AudioResample::~AudioResample() {
        releaseLister();
        flush();
    }

    /** 释放监听对象 */
    void AudioResample::releaseLister() {
        if (_listener == nullptr) return;

        delete _listener;
        _listener = nullptr;
    }

    /** 媒体监听对象 */
    void AudioResample::setMediaListener(MediaListener *listener) {
        releaseLister();
        _listener = listener;
    }

    /** 切换采样格式 */
    void AudioResample::changeFormat(AudioInfo info) {
        _inputInfo = info;
        init();
    }

    /** 切换播放速度 */
    void AudioResample::changeSpeed(float speed) {
        if (speed <= 0 || _speed == speed) return;
        _speed = speed;
        init();
    }

    /** 改变音频序列 */
    void AudioResample::changeSequence(bool reverse) {
        if (_reverse == reverse) return;
        _reverse = reverse;
        init();
    }

    /** 设置开始时间戳 [微秒] */
    void AudioResample::setStartPrefixTimeUs(int64_llu startPrefixTimeUs) {
        _startPrefixTimeUs = startPrefixTimeUs;
        init();
    }

    /** 重置时间戳 */
    void AudioResample::reset() {
        _startPrefixTimeUs = -1;
        _reverse = false;
        _speed = 1.0f;
        init();
    }

    /** 是否需要重采样 */
    bool AudioResample::needResample() {
        return _needResample;
    }

    /** 获取最后输入时间 [微秒] */
    int64_llu AudioResample::getLastInputTimeUs() {
        if (!_sampleInfo) return -1;
        return _sampleInfo->lastTimeUs;
    }

    /** 获取前置时间 [微秒] */
    int64_llu AudioResample::getPrefixTimeUs() {
        if (!_sampleInfo) return -1;
        return _sampleInfo->prefixTimeUs;
    }

    /** 刷新数据 */
    void AudioResample::flush() {
        _currentTaskId = Utils::timeMs();
        synchronized(_mutex) {
            if (_sampleInfo) _sampleInfo.reset();
            _sampleInfo = nullptr;
            _currentCache = nullptr;
            _tempCaches.clear();
        }
    }

    /** 重建缓存 */
    void AudioResample::rebuildCaches(TResampleInfo info) {
        if (!info || _listener == nullptr) return;
        synchronized(_mutex) {
            _currentCache = nullptr;
            _tempCaches.clear();
            for (int i = 0, j = info->tempCount; i < j; ++i) {
                TBuffer ptr = _listener->createBuffer(info->outByteLength);
                _tempCaches.push_back(ptr);
            }
        }
    }

    /** 初始化 */
    void AudioResample::init() {
        flush();

        if (_inputInfo.sampleRate < 1 || _inputInfo.bitWidth < 1 || _inputInfo.channel < 1) {
            _inputInfo = {_outputInfo.channel, _outputInfo.bitWidth, _outputInfo.sampleRate};
        }

        _needResample = (_inputInfo.sampleRate != _outputInfo.sampleRate
                         || _inputInfo.channel != _outputInfo.channel
                         || _inputInfo.bitWidth != _outputInfo.bitWidth
                         || _speed != 1
                         || _reverse
        );

        if (!_needResample) return;

        TResampleInfo info = make_shared<AudioResampleInfo>();

        info->taskId = _currentTaskId;
        info->scale = (_inputInfo.sampleRate * _speed) / _outputInfo.sampleRate;

        if (!AudioConvertFactory::build(_inputInfo, _outputInfo, info->convert)) {
            LOGE("AudioResample unsupport audio format.");
            return;
        }

        info->inUnitLength = (uint32_t) _inputInfo.channel * (_inputInfo.bitWidth / 8);
        info->outSampleRate = _outputInfo.sampleRate;
        info->outUnitLength = (uint32_t) _outputInfo.channel * (_outputInfo.bitWidth / 8);
        info->outByteLength = 1024 * info->outUnitLength;

        // 48000 -> 96000 => 2
        // 96000 -> 48000 => 1
        // 44100 -> 48000 => 2
        // 12000 -> 44100 => 4
        info->tempCount = (uint32_t) ceil(1 / info->scale) * 4;
        rebuildCaches(info);
        _sampleInfo = info;
    }

    /** 通知监听器 */
    void AudioResample::notifyListener(TBuffer buffer) {
        if (_listener == nullptr) return;
        _listener->onMediaOutputBuffer(buffer);
    }

    /** 反转数据 */
    TBuffer AudioResample::reverseBuffer(TBuffer inputBuffer) {
        if (!_reverse || !inputBuffer || _listener == nullptr) return inputBuffer;

        if (!_inputCache || _inputCache->capacity() < inputBuffer->capacity()) {
            _inputCache = _listener->createBuffer(inputBuffer->capacity());
        }

        BufferInfo info = inputBuffer->info();
        info.offset = 0;
        _inputCache->setInfo(info);

        if (_sampleInfo) {
            _sampleInfo->convert->inputReverse(inputBuffer, _inputCache);
        }
        return _inputCache;
    }

    /** 计算时间戳 [微秒] */
    int64_llu AudioResample::calTimestampUs(TResampleInfo info) {
        // 原始时间戳
        int64_llu orginUs =
                ((int64_llu) info->frameCount * 1024000000) / info->outSampleRate +
                info->prefixTimeUs;
        return orginUs;
    }

    /** 没有处理完整的缓存 */
    TBuffer AudioResample::unfullBuffer() {
        TBuffer cache = nullptr;
        synchronized(_mutex) {
            cache = _currentCache;
            _currentCache = nullptr;
        }
        return cache;
    }

    /** 返回没有处理完整的缓存 */
    void AudioResample::backUnfullBuffer(TBuffer cache, TResampleInfo info) {
        if (!cache || info->taskId != _currentTaskId) return;
        synchronized(_mutex) {
            _currentCache = cache;
        }
    }

    /** 出列一个输入缓存 */
    TBuffer AudioResample::dequeueInputBuffer() {
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
    TBuffer
    AudioResample::dequeueInputBufferOrBuild(TResampleInfo info) {
        if (info->taskId != _currentTaskId) return nullptr;

        TBuffer cache = dequeueInputBuffer();
        if (cache) {
            cache->infoPtr()->timeUs = calTimestampUs(info);
        }
        return cache;
    }

    /** 添加到输出缓存队列 */
    void AudioResample::appendOutputQueue(TBuffer cache, TResampleInfo info) {
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
    bool AudioResample::notifyEOS() {
        if (!_needResample) return false;

        // 防止线程外数据修改
        TResampleInfo info = _sampleInfo;
        if (!info || info->taskId != _currentTaskId) return false;

        TBuffer cache = unfullBuffer();
        if (!cache) return false;
        else if(cache->position() < 1){
            backUnfullBuffer(cache, info);
            return false;
        }

        appendOutputQueue(cache, info);
        
        return true;
    }

    /**
     * 入列缓存
     * @param inputBuffer 输入缓存
     * @param bufferInfo 缓存信息
     * @return 是否已处理
     */
    bool AudioResample::queueInputBuffer(TBuffer inputBuffer) {
        TBuffer cache = reverseBuffer(inputBuffer);
        if (!_needResample) {
            // 直接传递重采样数据
            notifyListener(cache);
            return true;
        }

        // 防止线程外数据修改
        TResampleInfo info = _sampleInfo;
        if (cache->buffer() == nullptr || cache->infoPtr()->size < 1 || !info ||
            info->taskId != _currentTaskId)
            return true;

        return processResample(cache, info);
    }

    /** 计算输出数据的结束时间 */
    int64_llu AudioResample::getOutputCacheEndTimeUs(TBuffer cache, TResampleInfo info) {
        // 已写入点数
        uint32_t writeSamples = cache->position() / info->outUnitLength;
        int64_llu endTimeUs = (writeSamples * 1000000) / info->outSampleRate;
        endTimeUs += cache->infoPtr()->timeUs;

//        LOGE("---------- writeSamples: %d, position: %d, outUnitLength: %d, endTimeUs: %lld, outSampleRate: %d, timeUs: %lld"
//        , writeSamples, cache->position(), info->outUnitLength, endTimeUs, info->outSampleRate, cache->infoPtr()->timeUs);

        return endTimeUs;
    }

    /***
     * 填充静音数据
     * @param cache 缓存信息
     * @param info 采样信息
     * @param muteCount 静音数据点数
     * @return 缓存对象
     */
    TBuffer
    AudioResample::fillMute(TBuffer cache, TResampleInfo info, uint32_t muteCount) {
        if (muteCount < 1 || info->taskId != _currentTaskId) return cache;

        // 输出采样点数
        uint32_t outSamples = cache->remaining() / info->outUnitLength;
        // 当前缓存可以写入的点数
        uint32_t useSamples = min(muteCount, outSamples);
        uint32_t length = useSamples * info->outUnitLength;

        int8_t *ptr = cache->currentPtr();
        memset(ptr, 0, length);
        cache->move(length);

        // 防止数据末尾不对齐，造成死循环
        if (cache->hasRemaining() && cache->remaining() < info->outUnitLength) {
            ptr = cache->currentPtr();
            memset(ptr, 0, cache->remaining());
            // 防止数据末尾不对齐，造成死循环
            cache->move(cache->remaining());
            useSamples++;
        }

        // 填充完一个数据缓存
        if (!cache->hasRemaining()) {
            appendOutputQueue(cache, info);
            // 对于静音数据只能创建新的对象
            cache = dequeueInputBufferOrBuild(info);
            // 无法获取缓存 证明被flush
            if (!cache) return nullptr;
        }

        muteCount -= useSamples;
        // 递归填充数据
        return fillMute(cache, info, muteCount);
    }

    /** 处理重采样 */
    bool AudioResample::processResample(TBuffer input, TResampleInfo info) {
        TBuffer cache = unfullBuffer();
        if (!cache) {
            cache = dequeueInputBuffer();
        }

        if (!cache) {
            LOGE("Resample can not queueInputBuffer, is forgot releaseOutputBuffer?");
            return false;
        }

        // 为第一帧
        if (!info->prefixSeted) {
            info->prefixSeted = true;
            info->frameCount = 0;
            info->prefixTimeUs =
                    _startPrefixTimeUs < 0 ? input->infoPtr()->timeUs : _startPrefixTimeUs;
            info->lastTimeUs = info->prefixTimeUs;
            info->inputTimeUs = info->prefixTimeUs;
            cache->clear();
            cache->infoPtr()->timeUs = info->prefixTimeUs;
        }

        // 新获取的缓存
        if (cache->infoPtr()->timeUs < 0) {
            cache->infoPtr()->timeUs = calTimestampUs(info);
        }

        info->preTimeUs = info->lastTimeUs;
        info->lastTimeUs = input->infoPtr()->timeUs;

        // 相对输入时间
        info->inputTimeUs += (int64_llu) fabs((info->lastTimeUs - info->preTimeUs) / _speed);

        // 输出起始帧时间小于输入帧时间，需要进行补帧操作，插入静音数据
        int64_llu cacheEndTimeUs = getOutputCacheEndTimeUs(cache, info);

//        LOGE("-------------- cacheEndTimeUs: %lld, prefixTimeUs: %lld, preTimeUs: %lld, lastTimeUs: %lld, mSpeed: %f, mReverse: %d,outputTimeUs: %lld, buffer: %lld"
//        , cacheEndTimeUs, info->prefixTimeUs, info->preTimeUs, info->lastTimeUs, _speed, _reverse, info->inputTimeUs, cache->infoPtr()->timeUs);


        if (cacheEndTimeUs < info->inputTimeUs) {
            uint32_t muteCount = (uint32_t) ((info->inputTimeUs - cacheEndTimeUs) *
                                             info->outSampleRate / 1000000);
            // 大于100采样点才补点
            if (muteCount > 100) {
//                LOGE("--------------22 cacheEndTimeUs: %lld, prefixTimeUs: %lld, muteCount: %d, preTimeUs: %lld, lastTimeUs: %lld, mSpeed: %f, outputTimeUs: %lld"
//                , cacheEndTimeUs, info->prefixTimeUs, muteCount, info->preTimeUs, info->lastTimeUs, _speed, info->inputTimeUs);

                cache = fillMute(cache, info, muteCount);
            }
        }

        input->position(0);
        resample(input, cache, info);
        return true;
    }

    /** 重采样数据 */
    void AudioResample::resample(TBuffer input, TBuffer cache, TResampleInfo info) {
        // cache为空代表重采样已释放或被Flush
        if (!cache) return;

        // 输入数据读取完成
        if (!input->hasRemaining()) {
            uint32_t flags = input->infoPtr()->flags;
            cache->infoPtr()->flags = flags;

            // 数据写到结尾
            if (cache->flagEndOfStream()) {
                appendOutputQueue(cache, info);
            }
                // 输出缓存还没有写到结尾
            else if (cache->hasRemaining()) {
                backUnfullBuffer(cache, info);
            }
            return;
        }

        // 避免智能指针性能消耗
        float scale = info->scale;
        uint32_t inUnitLength = info->inUnitLength;
        uint32_t outUnitLength = info->outUnitLength;


        // 输入采样点数
        uint32_t inSamples = input->remaining() / inUnitLength;
        uint32_t inStartPos = input->position();

        // 输出采样点数
        uint32_t outSamples = cache->remaining() / outUnitLength;
        // 需要的输出采样点数
        uint32_t needOutSamples;
        if (scale < 1) {
            needOutSamples = (uint32_t) floor(inSamples / scale);
        } else {
            needOutSamples = (uint32_t) ceil(inSamples / scale);
        }

        // 低转高一个变两个
        // 高转低两个合成一个
        // 48000 -> 96000 => 2 => scale: 2,  needInSamples = 1024 / 2 = 512,    inPos = 8 / 2 = 4
        // 96000 -> 48000 => 1 => scale: 0.5 needInSamples = 1024 / 0.5 = 2048  inPos = 8 / 0.5 = 16
        // 44100 -> 48000 => 2
        // 12000 -> 44100 => 4
        TBuffer tmp = _listener->createBuffer(outUnitLength * 2);
        AudioConvert *convert = info->convert;

        for (uint32_t i = 0, j = min(needOutSamples, outSamples), m = j - 1; i < j; i++) {
            // 输入绝对小数位
            float inPosUnitF = i * scale;
            uint32_t inPreUnitPos = (uint32_t) floor(inPosUnitF);
            uint32_t inNextUnitPos = (uint32_t) ceil(inPosUnitF);
            // 输入数据开始位置
            uint32_t inPrePos = inPreUnitPos * inUnitLength + inStartPos;
            input->position(inPrePos);

            // 整数位和结尾，直接填充
            if (i == m || inPreUnitPos == inNextUnitPos || inNextUnitPos >= inSamples) {
                // 没有数据可读
                if (!input->allowMove(inUnitLength)) {
                    backUnfullBuffer(cache, info);
                    //LOGE("----------222---, i: %d, position: %d", min(needOutSamples, outSamples), cache->position());
                    return;
                }
                convert->i2o(input, cache, 1);
                continue;
            }

            convert->i2o(input, tmp, 2);
            tmp->position(0);

            convert->i2oResamle(tmp, cache, inPosUnitF - inPreUnitPos);
        }

        // LOGE("----------222, i: %d, position: %d", min(needOutSamples, outSamples), cache->position());

        // 当前数据写到结尾
        if (!cache->hasRemaining()) {
            appendOutputQueue(cache, info);
            cache = dequeueInputBufferOrBuild(info);
            // 无法获取缓存
            if (!cache) return;
        }
        resample(input, cache, info);
    }
}
