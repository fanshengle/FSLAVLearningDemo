//
// Created by Clear Hu on 2018/6/30.
//

#include "MediaStruct.h"

namespace fslAVComponent {
    /** 真实数据长度 */
    uint32_t MediaBuffer::capacity() {
        return _capacity;
    }

    /** 当前位置 */
    uint32_t MediaBuffer::position() {
        return _position;
    }

    /** 设置当前位置 */
    uint32_t MediaBuffer::position(uint32_t postion) {
        if (postion > _limit) postion = _limit;
        else if (postion < 0) postion = 0;
        _position = postion;
        return _position;
    }

    /** 当前位置 */
    uint32_t MediaBuffer::limit() {
        return _limit;
    }

    /** 剩余可读数据长度 */
    uint32_t MediaBuffer::remaining() {
        return _limit - _position;
    }

    /** 是否为数据结尾 */
    bool MediaBuffer::hasRemaining() {
        return _position < _limit;
    }

    /** 设置缓存界限 */
    void MediaBuffer::flip(){
        _limit = _position;
        _position = 0;
    }

    /** 清除数据 */
    void MediaBuffer::clear() {
        _info = {0, _capacity, 0, -1};
        _limit = _capacity;
        _position = 0;
    }

    /** 移动位置 */
    uint32_t MediaBuffer::move(uint32_t offset) {
        uint32_t pos = _position + offset;
        return position(pos);
    }

    /** 是否可以移动到下一个位置 */
    bool MediaBuffer::allowMove(uint32_t offset) {
        return !(_bufferPtr == nullptr || _position + offset > _limit);
    }

    /** 当前指针 */
    int8_t *MediaBuffer::currentPtr() {
        return &_bufferPtr[_position];
    }

    /** 缓存对象 */
    void *MediaBuffer::buffer() {
        return _buffer;
    }

    /** 缓存指针 */
    int8_t *MediaBuffer::bufferPtr() {
        return _bufferPtr;
    }

    /** 指定位置的缓存指针 */
    int8_t *MediaBuffer::bufferPtr(uint32_t postion) {
        return &_bufferPtr[postion];
    }

    /** 读取缓存数据 */
    bool MediaBuffer::readBuffer(void *tmps, uint32_t length) {
        bool result = readBuffer(tmps, _position, length);
        if (result) _position += length;
        return result;
    }

    /** 写入缓存数据 */
    bool MediaBuffer::writeBuffer(void *tmps, uint32_t length) {
        bool result = writeBuffer(tmps, _position, length);
        if (result) _position += length;
        return result;
    }

    /** 读取缓存数据 */
    bool MediaBuffer::readBuffer(void *tmps, uint32_t postion, uint32_t length) {
        if (_bufferPtr == nullptr || tmps == nullptr || postion < 0 || postion + length > _limit)
            return false;

        memcpy(tmps, &_bufferPtr[postion], length);
        return true;
    }

    /** 写入缓存数据 */
    bool MediaBuffer::writeBuffer(void *tmps, uint32_t postion, uint32_t length) {
        if (_bufferPtr == nullptr || tmps == nullptr || postion < 0 || postion + length > _limit)
            return false;

        memcpy(&_bufferPtr[postion], tmps, length);
        return true;
    }

    /** 缓存信息 */
    BufferInfo MediaBuffer::info() {
        return _info;
    }

    /** 缓存信息 */
    void MediaBuffer::setInfo(BufferInfo info) {
        _info = info;
        _limit = info.offset + info.size;
        _position = info.offset;
    }

    /** 缓存信息指针 */
    BufferInfo *MediaBuffer::infoPtr() {
        return &_info;
    }

    /** 刷新缓存信息 */
    void MediaBuffer::freshInfo() {
        _info.size = _position;
        _info.offset = 0;
    }
}
