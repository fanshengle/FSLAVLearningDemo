/*
 * fslAVComponent_Utils
 *
 *  Created on: 2016-3-12
 *      Author: Clear
 */

#ifndef FSLAVComponent_UTILS_H_
#define FSLAVComponent_UTILS_H_

#include <vector>
#include <string>

typedef unsigned long long int uint64_llu;

#define LOG_TAG "FSLAVComponet.h"

/** 关闭LOG */
#if defined(CR_DISABLE_LOG)
#define LOGD(...) NULL
#define LOGI(...) NULL
#define LOGE(...) NULL
// note: ANDROID is defined when using ndk_build, __ANDROID__ is defined when using a standalone toolchain.
#elif defined(__ANDROID__) || defined(ANDROID)

// other
#else

#define LOGD(...) NULL
#define LOGI(...) NULL
#define LOGE(...) NULL
#endif

/**
 注意：FSLAVLearningDemo中使用FSLAVComponent，因FSLAVComponent内有c++文件
 所以必须在FSLAVLearningDemo->build Phases->link binary with libraries中引入libc++.tbd文件
 */

/**
 命名空间的使用
 
 namesapce命名空间是在大型项目开发中，为了避免命名冲突而引入的一种机制，
 比如说，在一个大型项目中，要用到多家软件开发商提供的类库。
 在事先没有约定的情况下，两套类库可能存在同名的函数或者是全局变量而产生冲突。项目越大，用到的类库越多，开发人员越多，这样的冲突也就越明显。
 所以在C++中，为了避免这种问题的发生，引入了命名空间，namespace 是对全局区域的再次划分。
 */
namespace fslAVComponent {

    class Utils {
    public:
        Utils();

        virtual ~Utils();

        /**获取到当前时间毫秒 精确到微秒*/
        static double timeMs();
    };

} /* namespace fslAVComponent */
#endif /* FSLAVComponent_UTILS_H_ */
