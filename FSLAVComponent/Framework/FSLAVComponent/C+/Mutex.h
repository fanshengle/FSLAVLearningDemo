//
// Created by Clear Hu on 2018/6/25.
//

#ifndef DROID_SDK_JNI_MUTEX_H
#define DROID_SDK_JNI_MUTEX_H

#include <pthread.h>

namespace fslAVComponent {
#define synchronized(M)  for(Lock M##_lock = M; M##_lock; M##_lock.setUnlock())

    /** 互斥锁 */
    class Mutex {
    public:
        Mutex(void);

        ~Mutex(void);

        Mutex(const Mutex &) = delete;

        Mutex &operator=(const Mutex &) = delete;

        void lock();

        void unLock();

    private:
        pthread_mutex_t mutex;
    };

    class Lock {
    public:
        Lock(Mutex &mutex);

        ~Lock(void);

        void setUnlock();

        operator bool() const;

    private:
        Mutex &m_mutex;
        bool m_locked;
    };
}

#endif //DROID_SDK_JNI_MUTEX_H
