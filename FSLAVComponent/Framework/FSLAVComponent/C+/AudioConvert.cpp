//
// Created by Clear Hu on 2018/7/1.
//

#include "AudioConvert.h"
#include "fslAVComponent_Utils.h"

namespace fslAVComponent {
    /********************************* AudioConvert **************************************/
    AudioConvert::~AudioConvert() {
        if (_inputConvert != nullptr) {
            delete _inputConvert;
            _inputConvert = nullptr;
        }
    }

    /** 添加输入转换器 */
    void AudioConvert::appendInput(AudioConvert *input) {
        this->_inputConvert = input;
        if (input->_inputConvert)this->_needRestore = true;
    }

    /** 按输入格式倒序排列数据 */
    void AudioConvert::inputReverse(TBuffer src, TBuffer dst) {
        this->_inputConvert->reverse(src, dst);
    }

    /** 输出数据转换为输入数据 */
    void AudioConvert::o2i(TBuffer src, TBuffer dst, uint32_t count) {
        if (!_needRestore) return;
        _inputConvert->i2o(src, dst, count);
    }
    /********************************* AudioConvertPCM8Mono **************************************/
    /** 单声道8bit */
    class AudioConvertPCM8Mono : public AudioConvert {
    public:
        /** PCM8 Mono 转换为 PCM8 Mono */
        virtual void toPCM8Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            dst->writeBuffer(src->currentPtr(), count);
            src->move(count);
        }

        /** PCM8 Mono 转换为 PCM8 Stereo */
        virtual void toPCM8Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            int8_t *inPtr = src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr++, outPtr += 2) {
                outPtr[0] = *inPtr;
                outPtr[1] = *inPtr;
            }
            src->move(count);
            dst->move(count * 2);
        }

        /** PCM8 Mono 转换为 PCM16 Mono */
        virtual void toPCM16Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            int8_t *inPtr = src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr++, outPtr++) {
                *outPtr = (int16_t) (*inPtr * 256);
            }
            src->move(count);
            dst->move(count * 2);
        }

        /** PCM8 Mono 转换为 PCM16 Stereo */
        virtual void toPCM16Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            int8_t *inPtr = src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr++, outPtr += 2) {
                outPtr[0] = outPtr[1] = (int16_t) (*inPtr * 256);
            }
            src->move(count);
            dst->move(count * 4);
        }

    public:
        /** 输入数据转换为输出数据 */
        virtual void i2o(TBuffer src, TBuffer dst, uint32_t count) override {
            _inputConvert->toPCM8Mono(src, dst, count);
        }

    public:
        /** 倒序排列数据 */
        virtual void reverse(TBuffer src, TBuffer dst) override {
            int8_t *inPtr = src->bufferPtr(src->limit() - 1);
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0, j = src->remaining(); i < j; i++, outPtr++, inPtr--) {
                *outPtr = *inPtr;
            }
            dst->move(src->remaining());
        }

        /** 数据重采样 */
        virtual void i2oResamle(TBuffer src, TBuffer dst, float diff) override {
            int8_t *inPtr = src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            // 插值运算
            *outPtr = (int8_t) (inPtr[0] + (inPtr[1] - inPtr[0]) * diff);
            dst->move(1);
        }
    };

    /********************************* AudioConvertPCM8Stereo **************************************/
    /** 双声道8bit */
    class AudioConvertPCM8Stereo : public AudioConvert {
    public:
        /** PCM8 Stereo 转换为 PCM8 Mono */
        virtual void toPCM8Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            int8_t *inPtr = src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr += 2, outPtr++) {
                *outPtr = (int8_t) (inPtr[0] / 2 + inPtr[1] / 2);
            }
            src->move(count * 2);
            dst->move(count);
        }

        /** PCM8 Stereo 转换为 PCM8 Stereo */
        virtual void toPCM8Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            dst->writeBuffer(src->currentPtr(), count * 2);
            src->move(count * 2);
        }

        /** PCM8 Stereo 转换为 PCM16 Mono */
        virtual void toPCM16Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            int8_t *inPtr = src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr += 2, outPtr++) {
                *outPtr = (int16_t) ((inPtr[0] + inPtr[1]) * 128);
            }
            src->move(count * 2);
            dst->move(count * 2);
        }

        /** PCM8 Stereo 转换为 PCM16 Stereo */
        virtual void toPCM16Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            int8_t *inPtr = src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr += 2, outPtr += 2) {
                outPtr[0] = (int16_t) (inPtr[0] * 256);
                outPtr[1] = (int16_t) (inPtr[1] * 256);
            }
            src->move(count * 2);
            dst->move(count * 4);
        }

    public:
        /** 输入数据转换为输出数据 */
        virtual void i2o(TBuffer src, TBuffer dst, uint32_t count) override {
            _inputConvert->toPCM8Stereo(src, dst, count);
        }

    public:
        /** 倒序排列数据 */
        virtual void
        reverse(TBuffer src, TBuffer dst) override {
            int16_t *inPtr = (int16_t *) src->bufferPtr(src->limit() - 2);
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0, j = src->remaining() / 2; i < j; i++, outPtr++, inPtr--) {
                *outPtr = *inPtr;
            }
            dst->move(src->remaining());
        }

        /** 数据重采样 */
        virtual void i2oResamle(TBuffer src, TBuffer dst, float diff) override {
            int8_t *inPtr = src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            // 插值运算
            outPtr[0] = (int8_t) (inPtr[0] + (inPtr[2] - inPtr[0]) * diff);
            outPtr[1] = (int8_t) (inPtr[1] + (inPtr[3] - inPtr[1]) * diff);
            dst->move(2);
        }
    };

    /********************************* AudioConvertPCM16Mono **************************************/
    /** 单声道16bit */
    class AudioConvertPCM16Mono : public AudioConvert {
    public:
        /** PCM16 Mono 转换为 PCM8 Mono */
        virtual void toPCM8Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr++, outPtr++) {
                *outPtr = (int8_t) (*inPtr / 256);
            }
            src->move(count * 2);
            dst->move(count);
        }

        /** PCM16 Mono 转换为 PCM8 Stereo */
        virtual void toPCM8Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr++, outPtr += 2) {
                outPtr[0] = outPtr[1] = (int8_t) (*inPtr / 256);
            }
            src->move(count * 2);
            dst->move(count * 2);
        }

        /** PCM16 Mono 转换为 PCM16 Mono */
        virtual void toPCM16Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            dst->writeBuffer(src->currentPtr(), count * 2);
            src->move(count * 2);
        }

        /** PCM16 Mono 转换为 PCM16 Stereo */
        virtual void toPCM16Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr++, outPtr += 2) {
                outPtr[0] = outPtr[1] = *inPtr;
            }
            src->move(count * 2);
            dst->move(count * 4);
        }

    public:
        /** 输入数据转换为输出数据 */
        virtual void i2o(TBuffer src, TBuffer dst, uint32_t count) override {
            _inputConvert->toPCM16Mono(src, dst, count);
        }

    public:
        /** 倒序排列数据 */
        virtual void
        reverse(TBuffer src, TBuffer dst) override {
            int16_t *inPtr = (int16_t *) src->bufferPtr(src->limit() - 2);
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0, j = src->remaining() / 2; i < j; i++, outPtr++, inPtr--) {
                *outPtr = *inPtr;
            }
            dst->move(src->remaining());
        }

        /** 数据重采样 */
        virtual void i2oResamle(TBuffer src, TBuffer dst, float diff) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            // 插值运算
            *outPtr = (int16_t) (inPtr[0] + (inPtr[1] - inPtr[0]) * diff);
            dst->move(2);
        }
    };

    /********************************* AudioConvertPCM16Stereo **************************************/
    /** 双声道16bit */
    class AudioConvertPCM16Stereo : public AudioConvert {
    public:
        /** PCM16 Stereo 转换为 PCM8 Mono */
        virtual void toPCM8Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr += 2, outPtr++) {
                *outPtr = (int8_t) ((inPtr[0] + inPtr[1]) / 512);
            }
            src->move(count * 4);
            dst->move(count);
        }

        /** PCM16 Stereo 转换为 PCM8 Stereo */
        virtual void toPCM8Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int8_t *outPtr = dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr += 2, outPtr += 2) {
                outPtr[0] = (int8_t) (inPtr[0] / 256);
                outPtr[1] = (int8_t) (inPtr[1] / 256);
            }
            src->move(count * 4);
            dst->move(count * 2);
        }

        /** PCM16 Stereo 转换为 PCM16 Mono */
        virtual void toPCM16Mono(TBuffer src, TBuffer dst, uint32_t count) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            for (int i = 0; i < count; ++i, inPtr += 2, outPtr++) {
                *outPtr = (int16_t) (inPtr[0] / 2 + inPtr[1] / 2);
            }
            src->move(count * 4);
            dst->move(count * 2);
        }

        /** PCM16 Stereo 转换为 PCM16 Stereo */
        virtual void toPCM16Stereo(TBuffer src, TBuffer dst, uint32_t count) override {
            dst->writeBuffer(src->currentPtr(), count * 4);
            src->move(count * 4);
        }

    public:
        /** 输入数据转换为输出数据 */
        virtual void i2o(TBuffer src, TBuffer dst, uint32_t count) override {
            _inputConvert->toPCM16Stereo(src, dst, count);
        }

    public:
        /** 倒序排列数据 */
        virtual void
        reverse(TBuffer src, TBuffer dst) override {
            int32_t *inPtr = (int32_t *) src->bufferPtr(src->limit() - 4);
            int32_t *outPtr = (int32_t *) dst->currentPtr();

            for (int i = 0, j = src->remaining() / 4; i < j; i++, outPtr++, inPtr--) {
                *outPtr = *inPtr;
            }
            dst->move(src->remaining());
        }

        /** 数据重采样 */
        virtual void i2oResamle(TBuffer src, TBuffer dst, float diff) override {
            int16_t *inPtr = (int16_t *) src->currentPtr();
            int16_t *outPtr = (int16_t *) dst->currentPtr();

            // 插值运算
            outPtr[0] = (int16_t) (inPtr[0] + (inPtr[2] - inPtr[0]) * diff);
            outPtr[1] = (int16_t) (inPtr[1] + (inPtr[3] - inPtr[1]) * diff);
            dst->move(4);
        }
    };

    /********************************* AudioConvertFactory **************************************/
    /** 创建音频转换器 */
    bool AudioConvertFactory::build(AudioInfo input, AudioInfo output, AudioConvert *&convert) {
        AudioConvert *inputConvert = nullptr;
        if (!build(input, inputConvert)) {
            LOGE("AudioConvert build unsupport inputInfo: bitWidth[%d], channel[%d], sampleRate[%d]",
                 (uint32_t)input.bitWidth, (uint32_t)input.channel, (uint32_t)input.sampleRate);
            return false;
        }

        AudioConvert *outputConvert = nullptr;
        if (!build(output, outputConvert)) {
            delete inputConvert;
            LOGE("AudioConvert build unsupport outputInfo: bitWidth[%d], channel[%d], sampleRate[%d]",
                 (uint32_t)input.bitWidth, (uint32_t)input.channel, (uint32_t)input.sampleRate);
            return false;
        }

        // 反向输出
        AudioConvert *restore = nullptr;
        build(output, restore);
        inputConvert->appendInput(restore);

        outputConvert->appendInput(inputConvert);

        convert = outputConvert;
        return true;
    }

    /** 创建音频转换器 */
    bool AudioConvertFactory::build(AudioInfo input, AudioConvert *&convert) {

        uint32_t bitWidth = input.bitWidth;
        uint32_t channel = input.channel;

        switch (bitWidth) {
            case 16: {
                switch (channel) {
                    case 1: {
                        convert = new AudioConvertPCM16Mono();
                        return true;
                    }
                    case 2: {
                        convert = new AudioConvertPCM16Stereo();
                        return true;
                    }
                    default:
                        break;
                }
            }
            case 8: {
                switch (channel) {
                    case 1: {
                        convert = new AudioConvertPCM8Mono();
                        return true;
                    }
                    case 2: {
                        convert = new AudioConvertPCM8Stereo();
                        return true;
                    }
                    default:
                        break;
                }
            }
            default:
                break;
        }
        return false;
    }
}
