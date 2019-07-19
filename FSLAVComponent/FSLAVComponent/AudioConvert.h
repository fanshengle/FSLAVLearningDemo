//
// Created by Clear Hu on 2018/7/1.
//

#ifndef DROID_SDK_JNI_AUDIOCONVERT_H
#define DROID_SDK_JNI_AUDIOCONVERT_H

#include "MediaStruct.h"

using namespace std;

namespace fslAVComponent {
    /** 音频转换接口 */
    class AudioConvert {
    public:
        AudioConvert() = default;

        virtual ~AudioConvert();

    private:
        /** 不允许复制 */
        AudioConvert(const AudioConvert &) = delete;

        AudioConvert &operator=(const AudioConvert &) = delete;

    protected:
        /** 是否需要反向输出 */
        bool _needRestore = false;
        /** 输入音频信息 */
        AudioConvert *_inputConvert;
    public:
        /** 添加输入转换器 */
        void appendInput(AudioConvert *input);

        /** 输出数据转换为输入数据 */
        void o2i(TBuffer src, TBuffer dst, uint32_t count);

    public:
        /** 转换为PCM8 Mono */
        virtual void toPCM8Mono(TBuffer src, TBuffer dst, uint32_t count) = 0;

        /** 转换为PCM8 Stereo */
        virtual void toPCM8Stereo(TBuffer src, TBuffer dst, uint32_t count) = 0;

        /** 转换为PCM16 Mono */
        virtual void toPCM16Mono(TBuffer src, TBuffer dst, uint32_t count) = 0;

        /** 转换为PCM16 Stereo */
        virtual void toPCM16Stereo(TBuffer src, TBuffer dst, uint32_t count) = 0;

    public:
        /** 输入数据转换为输出数据 */
        virtual void i2o(TBuffer src, TBuffer dst, uint32_t count) = 0;

    public:
        /** 倒序排列数据 */
        virtual void reverse(TBuffer src, TBuffer dst) = 0;

        /** 按输入格式倒序排列数据 */
        void inputReverse(TBuffer src, TBuffer dst);

    public:
        /** 数据重采样 */
        virtual void i2oResamle(TBuffer src, TBuffer dst, float diff) = 0;
    };

    /** 音频转换工厂 */
    class AudioConvertFactory {
    public:
        /** 创建音频转换器 */
        static bool build(AudioInfo input, AudioInfo output, AudioConvert *& convert);

        /** 创建音频转换器 */
        static bool build(AudioInfo input, AudioConvert *& convert);
    };
}

#endif //DROID_SDK_JNI_AUDIOCONVERT_H
