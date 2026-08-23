avscuda_filters_headers = [
  'resample.h',
  'resample_avx2.h',
  'resample_functions.h',
  'turn.h',
  'convert_avx.h',
  'convert_avx2.h',
  'focus.h',
  'merge.h',
  'merge_avx2.h',
]

# AVX2ファイルのリスト
avx2_sources = [
  'resample_avx2.cpp',
  'convert_avx2.cpp',
  'focus_avx2.cpp',
  'merge_avx2.cpp',
]

# AVXファイルのリスト
avx_sources = [
  'convert_avx.cpp',
]

# 通常のソースファイルのリスト
normal_sources = [
  'resample_functions.cpp',
  'turn.cpp',
  'SupportFilters.cpp',
  'focus.cpp',
  'resample.cu',
  'ConditionalFunctions.cu',
  'Convert.cu',
  'Filters.cu',
  'merge.cu',
]

avscuda_filters_lib = static_library('avscuda_filters',
  normal_sources,
  include_directories : include_directories('..', '../../KUtil', '../../common'),
  dependencies : [avisynth_dep, cuda_dep, threads_dep, common_dep],
  cpp_args : cpp_args,
  cuda_args : cuda_args,
  pic : true,
)

avscuda_filters_link_with = [avscuda_filters_lib]
if is_x86
  # AVX2ファイル用のライブラリ
  avx2_lib = static_library('avscuda_filters_avx2',
    avx2_sources,
    include_directories : include_directories('..', '../../KUtil', '../../common'),
    dependencies : [avisynth_dep, cuda_dep, threads_dep, common_dep],
    cpp_args : avx2_args,
    cuda_args : cuda_args,
    pic : true,
  )

  # AVXファイル用のライブラリ
  avx_lib = static_library('avscuda_filters_avx',
    avx_sources,
    include_directories : include_directories('..', '../../KUtil', '../../common'),
    dependencies : [avisynth_dep, cuda_dep, threads_dep, common_dep],
    cpp_args : avx_args,
    cuda_args : cuda_args,
    pic : true,
  )
  avscuda_filters_link_with += [avx2_lib, avx_lib]
endif

avscuda_filters_dep = declare_dependency(
  link_with : avscuda_filters_link_with,
  include_directories : include_directories('.')
)
