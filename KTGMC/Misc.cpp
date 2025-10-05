#define _CRT_SECURE_NO_WARNINGS
#include "avisynth.h"
#include "rgy_osdep.h"

#include "CommonFunctions.h"
#include "DeviceLocalData.h"
#include "DebugWriter.h"
#include "Misc.h"

#include <string>
#include <chrono>

// commonのcppを取り入れる
#include "DebugWriter.cpp"
#include "DeviceLocalData.cpp"

void AddFuncKernel(IScriptEnvironment* env);
void AddFuncMV(IScriptEnvironment* env);

static void init_console() {
#if defined(_WIN32) || defined(_WIN64)
    AllocConsole();
    freopen("CONOUT$", "w", stdout);
    freopen("CONIN$", "r", stdin);
#endif
}

void OnCudaError(cudaError_t err) {
#if 1 // デバッグ用（本番は取り除く）
    printf("[CUDA Error] %s (code: %d)\n", cudaGetErrorString(err), err);
#endif
}

int GetDeviceTypes(const PClip& clip) {
    int devtypes = (clip->GetVersion() >= 5) ? clip->SetCacheHints(CACHE_GET_DEV_TYPE, 0) : 0;
    if (devtypes == 0) {
        return DEV_TYPE_CPU;
    }
    return devtypes;
}

class Time : public GenericVideoFilter {
    std::string name;
public:
    Time(PClip _child, const char* name, IScriptEnvironment* env)
        : GenericVideoFilter(_child)
        , name(name) {}

    PVideoFrame __stdcall GetFrame(int n, IScriptEnvironment* env) {
        auto start = std::chrono::high_resolution_clock::now();

        PVideoFrame frame = child->GetFrame(n, env);

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
        double sec = duration.count() / 1000000.0;
        printf("[%5d] N:%5d %s: %.1f ms\n", GetCurrentThreadId(), n, name.c_str(), sec * 1000);

        return frame;
    }
};

AVSValue __cdecl Create_Time(AVSValue args, void* user_data, IScriptEnvironment* env) {
    return new Time(args[0].AsClip(), args[1].AsString("Time"), env);
}

const AVS_Linkage *AVS_linkage = 0;

extern "C" __declspec(dllexport) const char* __stdcall AvisynthPluginInit3(IScriptEnvironment* env, const AVS_Linkage* const vectors) {
    AVS_linkage = vectors;
    //init_console();

    AddFuncKernel(env);
    AddFuncMV(env);

    return "CUDA Accelerated QTGMC Plugin";
}
