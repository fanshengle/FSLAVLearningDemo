/*
 * fslAVComponent.cpp
 *
 *  Created on: 2016-3-12
 *      Author: Clear
 */

#include "fslAVComponent_Utils.h"
#include <cctype>
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <iomanip>
#include <sstream>
#include <iostream>
#include <sys/time.h>

using namespace std;

namespace fslAVComponent {
    Utils::Utils() {

    }

    Utils::~Utils() {

    }

    /**获取到当前时间毫秒 精确到微秒*/
    double Utils::timeMs() {
        struct timeval xTime;
        gettimeofday(&xTime, NULL);
        double now = ((int64_t) xTime.tv_sec * 1000.0) + (xTime.tv_usec / 1000.0);
        return now;
    }

}
/* namespace fslAVComponent */
