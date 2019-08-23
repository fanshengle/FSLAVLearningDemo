//
// Created by Clear Hu on 2018/6/30.
//

#ifndef DROID_SDK_JNI_MEDIASTRUCT_H
#define DROID_SDK_JNI_MEDIASTRUCT_H

#include <cstdio>
#include <cstdlib>
#include <memory>

using namespace std;

// 数据结构体
namespace fslAVComponent {
    /** 长整型 */
    typedef long long int64_llu;

    /** 重采样操作 */
    enum ResampleCommand {
        ResampleHard_Release = 0x0000000, // 释放资源
        ResampleHard_Rest = 0x0000010, // 重置
        ResampleHard_Flush = 0x0000020, // 刷新数据
        ResampleHard_NeedResample = 0x0000040, // 是否重采样
        ResampleHard_SetStartPrefixTimeUs = 0x0000050, // 开始时间戳 [微秒]
        ResampleHard_GetLastInputTimeUs = 0x0000060, // 获取最后输入时间 [微秒]
        ResampleHard_GetPrefixTimeUs = 0x0000070 // 获取前置时间 [微秒]
    };

    /** 变调操作 */
    enum PitchCommand {
        PitchHard_Release = 0x0000000, // 释放资源
        PitchHard_Rest = 0x0000010, // 重置
        PitchHard_Flush = 0x0000020, // 刷新数据
        PitchHard_NeedPitch = 0x0000040, // 是否变调
    };

    // 音频信息
    struct AudioInfo {
        /** 音频声道数 */
        uint8_t channel;
        /** 采样位宽 */
        uint8_t bitWidth;
        /** 音频采样率 */
        uint32_t sampleRate;
    };

    /** 缓存信息 */
    struct BufferInfo {
        uint32_t offset;
        uint32_t size;
        uint32_t flags;
        /** 时间戳 [微秒] */
        int64_llu timeUs;
    };

    /** 媒体缓存 */
    class MediaBuffer {
    public:
        MediaBuffer() {}

        virtual ~MediaBuffer() {}

    protected:
        /** 真实数据长度 */
        uint32_t _capacity = 0;
        /** 当前位置 */
        uint32_t _position = 0;
        /** 设置限制长度 */
        uint32_t _limit = 0;
        /** 缓存信息 */
        BufferInfo _info;
        /** 缓存指针 */
        int8_t *_bufferPtr = nullptr;
        /** 缓存对象 */
        void *_buffer = nullptr;
    public:
        /** 真实数据长度 */
        uint32_t capacity();

        /** 当前位置 */
        uint32_t position();

        /** 设置当前位置 */
        uint32_t position(uint32_t postion);

        /** 当前位置 */
        uint32_t limit();

        /** 剩余可读数据长度 */
        uint32_t remaining();

        /** 是否为数据结尾 */
        bool hasRemaining();

        /** 设置缓存界限 */
        void flip();

        /** 清除数据 */
        void clear();

        /** 移动位置, 返回移动后的位置 */
        uint32_t move(uint32_t offset);

        /** 是否可以移动到下一个位置 */
        bool allowMove(uint32_t offset);

        /** 缓存对象 */
        void *buffer();

        /** 当前缓存指针 */
        int8_t *currentPtr();

        /** 缓存指针 */
        int8_t *bufferPtr();

        /** 指定位置的缓存指针 */
        int8_t *bufferPtr(uint32_t postion);

        /** 读取缓存数据 */
        bool readBuffer(void *tmps, uint32_t length);

        /** 写入缓存数据 */
        bool writeBuffer(void *tmps, uint32_t length);

        /** 读取缓存数据 */
        bool readBuffer(void *tmps, uint32_t postion, uint32_t length);

        /** 写入缓存数据 */
        bool writeBuffer(void *tmps, uint32_t postion, uint32_t length);

    public:
        /** 缓存信息 */
        BufferInfo info();

        /** 缓存信息 */
        void setInfo(BufferInfo info);

        /** 缓存信息指针 */
        BufferInfo *infoPtr();

        /** 刷新缓存信息 */
        void freshInfo();

        /** 是否读取到数据结尾 */
        virtual bool flagEndOfStream() { return false; }
    };

    /** 媒体缓存定义 */
    typedef shared_ptr<MediaBuffer> TBuffer;

    /** 媒体监听对象 */
    class MediaListener {
    public:
        MediaListener() {}

        virtual ~MediaListener() {}

    public:
        /** 媒体输出 */
        virtual void onMediaOutputBuffer(TBuffer buffer) {}

        /** 创建缓存 */
        virtual TBuffer createBuffer(uint32_t capacity) { return nullptr; };
    };
}

#endif //DROID_SDK_JNI_MEDIASTRUCT_H
