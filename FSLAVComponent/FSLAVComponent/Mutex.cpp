//
// Created by Clear Hu on 2018/6/25.
//

#include "Mutex.h"
#include "fslAVComponent_Utils.h"

namespace fslAVComponent {

    Mutex::Mutex(void) {
        this->mutex = PTHREAD_MUTEX_INITIALIZER;
    }

    Mutex::~Mutex(void) {
        //保证对象被析构时候能够删除临界区
        pthread_mutex_destroy(&mutex);
    }

    void Mutex::lock() {
        pthread_mutex_lock(&mutex);
    }

    void Mutex::unLock() {
        pthread_mutex_unlock(&mutex);
    }

    Lock::Lock(Mutex &mutex) : m_mutex(mutex), m_locked(true) {
        m_mutex.lock();
    }

    Lock::~Lock(void) {
        // 一定要在析构函数中解锁，因为不管发生什么，只要对象离开他的生命周期（即离开大括号），都会调用其析构函数
        m_mutex.unLock();
    }

    void Lock::setUnlock() {
        m_locked = false;
    }

    Lock::operator bool() const {
        return m_locked;
    }
}
