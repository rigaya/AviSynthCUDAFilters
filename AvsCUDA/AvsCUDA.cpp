// AvsCUDA.cpp : DLL アプリケーション用にエクスポートされる関数を定義します。
//

#include <stdio.h>
#include <avisynth.h>
#include <cuda_runtime_api.h>

#include "AvsCUDA.h"

extern const FuncDefinition conditonal_functions[];
extern const FuncDefinition support_filters[];
extern const FuncDefinition generic_filters[];
extern const FuncDefinition Merge_filters[];
extern const FuncDefinition Convert_filters[];
extern const FuncDefinition Resample_filters[];

const FuncDefinition* functions[] = {
     conditonal_functions,
     support_filters,
     generic_filters,
     Merge_filters,
     Convert_filters,
     Resample_filters
};

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

const AVS_Linkage *AVS_linkage = 0;

extern "C" __declspec(dllexport) const char* __stdcall AvisynthPluginInit3(IScriptEnvironment* env, const AVS_Linkage* const vectors) {
    AVS_linkage = vectors;

    for (int f = 0; f < (int)(sizeof(functions) / sizeof(functions[0])); ++f) {
        const FuncDefinition* list = functions[f];
        for (int i = 0; list[i].name; ++i) {
            auto def = list[i];
            env->AddFunction(def.name, def.params, def.func, def.user_data);
        }
    }

    return "Avisynth CUDA Filters Plugin";
}
