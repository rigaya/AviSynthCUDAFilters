#include "avisynth.h"

#include "rgy_osdep.h"
#if (defined(_WIN32) || defined(_WIN64))
#include "psapi.h"
#endif
#include <iostream>
#include <string>
#include <algorithm>
#include "KUtil.h"

bool hasEnding(std::string const &fullString, std::string const &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare(fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}

AVSValue WINAPI_CDECL IsProcess(AVSValue args, void* user_data, IScriptEnvironment* env) {
    std::string exe = args[0].AsString("");
    if (exe.empty()) {
        env->ThrowError("IsProcess: exe is empty!");
    }

#if defined(_WIN32) || defined(_WIN64)
    char buf[MAX_PATH];
    if (GetProcessImageFileName(GetCurrentProcess(), buf, MAX_PATH)) {
        std::string name(buf);
        std::transform(name.begin(), name.end(), name.begin(), ::tolower);
        std::transform(exe.begin(), exe.end(), exe.begin(), ::tolower);
        return hasEnding(name, exe);
    }
#else
    char buf[KFM_MAX_PATH];
    ssize_t len = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
    if (len != -1) {
        buf[len] = '\0';
        std::string name(buf);
        std::transform(name.begin(), name.end(), name.begin(), ::tolower);
        std::transform(exe.begin(), exe.end(), exe.begin(), ::tolower);
        return hasEnding(name, exe);
    }
#endif
    return false;
}

const AVS_Linkage *AVS_linkage = 0;

extern "C" KFM_API const char* __stdcall AvisynthPluginInit3(IScriptEnvironment* env, const AVS_Linkage* const vectors) {
    AVS_linkage = vectors;
    env->AddFunction("IsProcess", "s", IsProcess, 0);
    return "IsProcess?";
}
