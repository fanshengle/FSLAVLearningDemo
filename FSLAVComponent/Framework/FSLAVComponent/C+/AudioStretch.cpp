//
// Created by Clear Hu on 2018/6/25.
//

#include <math.h>
#include "AudioStretch.h"
#include "fslAVComponent_Utils.h"

namespace fslAVComponent {
    /** 声音变速对象 */
    AudioStretch::AudioStretch(uint32_t sampleRate, float speedRatio){
        prepare(sampleRate, speedRatio);
    }
    
    AudioStretch::~AudioStretch() {
        close();
    }
    
    /** 缓存时间长度[毫秒] */
    static uint32_t OLA_WIN_MS = 20;
    /** 抽取长度 [数值越小精度越高，性能越低] */
    static uint32_t OLA_DECIMATE = 3;
    
    /** 处理变调 */
    bool AudioStretch::process(TBuffer input, TBuffer output, bool eos){
        if (!input || input->limit() < 1 || !output || output->capacity() < 1) {
            LOGE("AudioStretch process invalid params: input[%d], output[%d], sampleRate[%d], speedRatio[%f]",
                 input->limit(), output->capacity(), _sampleRate, _speedRatio);
            return false;
        }
        
        output->clear();
        
        // if speed 1.0 just copy in to out and return
        if (_speedRatio == 1.0f) {
            int32_t limit = input->remaining();
            if (limit > output->capacity())limit = output->capacity();
            output->writeBuffer(input->currentPtr(), limit);
            output->flip();
            return true;
        }
        
        initData(input, output);
        
        // 第一次输入数据
        if (_totalProcessOlaWWin == 0) {
            if (_srcBufferSize < _olaWinLength) {
                return false;
            }
            
            int32_t copySize = _olaWinLength;
            int16_t *srcPtr = _srcBuffer;
            int16_t *dstPtr = _dstBuffer;
            float *hannPtr = _hann;
            
            for (int32_t copyIndex = 0; copyIndex < copySize; copyIndex++) {
                *(dstPtr + copyIndex) += *(srcPtr + copyIndex) * *(hannPtr + copyIndex);
            }
            
            _dstBufferSize += _olaStep;
            _totalOutputSize += _olaStep;
        }
        else{
            //_dstBuffer
        }
        
        uint64_t totalOlaWin = (uint64_t)floor(_totalInputSize / _speedRatio + 0.5) / _olaStep;
        uint64_t matchSrcIndex = _preMatchSrcIndex;
        
        for (uint64_t olaWinIndex = _totalProcessOlaWWin; olaWinIndex < totalOlaWin; olaWinIndex++) {
            // match search.
            uint64_t matchDstIndex = (uint64_t)(_totalOutputSize * _speedRatio);
            matchDstIndex = _srcBufferSize - (_totalInputSize - matchDstIndex);
            
            if (matchSrcIndex > _srcBufferSize - _olaWinLength)
                break;
            
            int32_t matchStartIndex = (int32_t)(matchDstIndex - _olaStep);
            matchStartIndex = (matchStartIndex < 0) ? 0 : matchStartIndex;
            int32_t matchEndIndex = (int32_t)(matchDstIndex + _olaStep);
            
            if (matchEndIndex > _srcBufferSize - _olaWinLength) {
                if (!eos) break;
                matchEndIndex = _srcBufferSize - _olaWinLength;
            }
            
            int32_t bestMatchVal = INT32_MAX;
            for (int32_t matchStep = matchStartIndex; matchStep < matchEndIndex; matchStep++) {
                int16_t *matchSrcPtr = _srcBuffer + matchSrcIndex;
                int16_t *matchDstPtr = _srcBuffer + matchStep;
                int32_t matchVal = 0;
                
                for (int32_t olaStep = 0; olaStep < _olaWinLength; olaStep += _decimate) {
                    matchVal += abs(*matchSrcPtr - *matchDstPtr);
                    matchSrcPtr += _decimate;
                    matchDstPtr += _decimate;
                }
                if (matchVal < bestMatchVal) {
                    bestMatchVal = matchVal;
                    matchDstIndex = matchStep;
                }
            }
            
            // hann copy.
            if (_srcBufferSize - matchDstIndex > _olaWinLength) {
                int16_t *srcPtr = _srcBuffer + matchDstIndex;
                int16_t *dstPtr = _dstBuffer + _dstBufferSize;
                float *hannPtr = _hann;
                
                for (int32_t copyIndex = 0; copyIndex < _olaWinLength; copyIndex++) {
                    *(dstPtr + copyIndex) += (int16_t)(*(srcPtr + copyIndex) * *(hannPtr + copyIndex));
                }
            }
            else {
                break;
            }
            
            matchSrcIndex = matchDstIndex + _olaStep;
            _dstBufferSize += _olaStep;
            _totalOutputSize += _olaStep;
            _totalProcessOlaWWin++;
        }
        
        if (!eos) {
            uint64_t usedSrcSize = 0;
            
            uint64_t matchStartIndex = (uint64_t)(_totalOutputSize * _speedRatio);
            matchStartIndex = _srcBufferSize - (_totalInputSize - matchStartIndex);
            matchStartIndex = matchStartIndex - _olaStep;
            
            if (matchSrcIndex < matchStartIndex) {
                usedSrcSize = matchSrcIndex;
                _preMatchSrcIndex = 0;
            }
            else {
                usedSrcSize = matchStartIndex;
                _preMatchSrcIndex = matchSrcIndex - matchStartIndex;
            }
            
            _totalInputSize -= (_srcBufferSize - usedSrcSize);
            
            if (_srcBufferSize < usedSrcSize) {
                _preSrcRemainingSize = 0;
            }
            else{
                _preSrcRemainingSize = (uint32_t)(_srcBufferSize - usedSrcSize);
                memmove(_srcBuffer, _srcBuffer + usedSrcSize, sizeof(int16_t) * _preSrcRemainingSize);
            }
        }
        
        fillOutput(output, eos);
        return true;
    }
    
    void AudioStretch::initData(TBuffer input, TBuffer output) {
        int32_t inputSize = input->limit() / 2;
        int32_t outputSize = output->limit() / 2;

        if (_srcBuffer == nullptr)
        {
            _srcBufferAllocSize = inputSize * 2;
            _srcBuffer = (int16_t *)calloc(_srcBufferAllocSize, sizeof(int16_t));
            memset(_srcBuffer, 0, sizeof(int16_t) * _srcBufferAllocSize);
            _preSrcRemainingSize = 0;
            
            _dstOutLimitSize = (uint32_t)ceil(inputSize / _speedRatio);
            _dstBufferAllocSize = outputSize * 2;
            _dstBuffer = (int16_t *)calloc(_dstBufferAllocSize, sizeof(int16_t));
            memset(_dstBuffer, 0, sizeof(int16_t) * _dstBufferAllocSize);
            _dstBufferSize = 0;
        }
        
        _srcBufferSize = inputSize + _preSrcRemainingSize;
        // 当前输入数据合并
        memcpy(_srcBuffer + _preSrcRemainingSize, (int16_t *)input->currentPtr(), sizeof(int16_t) * inputSize);
        _totalInputSize += _srcBufferSize;
    }
    
    /** 填充输出数据 */
    void AudioStretch::fillOutput(TBuffer output, bool eos) {
        if (eos) {
            output->writeBuffer(_dstBuffer, _dstOutLimitSize * 2);
        }
        else {
            if (_dstBufferSize > _dstOutLimitSize) {
                output->writeBuffer(_dstBuffer, _dstOutLimitSize * 2);
                
                _dstBufferSize -= _dstOutLimitSize;
                memmove(_dstBuffer, _dstBuffer + _dstOutLimitSize, sizeof(int16_t) * (_dstBufferSize + _olaStep));
                memset(_dstBuffer + (_dstBufferSize + _olaStep), 0, sizeof(int16_t) * (_dstBufferAllocSize - (_dstBufferSize + _olaStep)));
            }
            else {
                output->writeBuffer(_dstBuffer, _dstBufferSize * 2);
                
                memmove(_dstBuffer, _dstBuffer + _dstBufferSize, sizeof(int16_t) * _olaStep);
                _dstBufferSize = 0;
                memset(_dstBuffer + _olaStep, 0, sizeof(int16_t) * (_dstBufferAllocSize - _olaStep));
            }
        }
        
        output->flip();
    }
    
    /** 准备转换 */
    void AudioStretch::prepare(uint32_t sampleRate, float speedRatio){
        _sampleRate = sampleRate;
        _speedRatio = speedRatio;
        
        if (_sampleRate <= 0) {
            LOGE("AudioStretch prepare sampleRate need > 0: %d", _sampleRate);
            _sampleRate = 44100;
        }
        
        if (_speedRatio <= 0) {
            LOGE("AudioStretch prepare speedRatio need > 0: %f", _speedRatio);
            _speedRatio = 1.0f;
        }
        
        _decimate = OLA_DECIMATE;
        _totalInputSize = 0;
        _totalOutputSize = 0;
        _totalProcessOlaWWin = 0;
        _preMatchSrcIndex = 0;
        
        _srcBufferAllocSize = 0;
        _srcBuffer = nullptr;
        _preSrcRemainingSize = 0;
        
        _dstBuffer = nullptr;
        _dstBufferAllocSize = 0;
        _dstBufferSize = 0;
        _dstOutLimitSize = 0;

        // calc OLA window size:
        _olaWinLength = (OLA_WIN_MS * _sampleRate) / 1000;
        _olaStep = _olaWinLength / 2;
        // make even:
        _olaWinLength = _olaStep * 2;
        makeHann(_olaWinLength);
        
    }
    
    /** 关闭数据 */
    void AudioStretch::close() {
        if (_hann != nullptr) {
            free(_hann);
            _hann = nullptr;
        }
        
        if (_srcBuffer != nullptr){
            free(_srcBuffer);
            _srcBuffer = nullptr;
        }
        
        if (_dstBuffer != nullptr){
            free(_dstBuffer);
            _dstBuffer = nullptr;
        }
    }
    
    /** 创建Hann window */
    void AudioStretch::makeHann(int32_t length) {
        _hann = (float *) calloc(length, sizeof(float));
        
        float *pf = _hann;
        float fScale = (float) (2.0f * M_PI / length);
        for (int32_t k = 0; k < length; ++k, ++pf) {
            *pf = 0.5f * (1.0f - cosf(k * fScale));
        }
    }
}
