# meson 1.2 未満では cuda dependency が cudart を動的リンクするため、
# 生成物が libcudart.so.* を要求してしまう。
# 配布バイナリを CUDA Toolkit 非依存にするため meson 1.2 以降を必須とする。
project('AviSynthCUDAFilters', 'cpp', 'cuda',
  version : '1.0.0',
  meson_version : '>= 1.2.0',
  default_options : [
    'cpp_std=c++17',
    'warning_level=0',
    'buildtype=release',
    'libdir=lib/avisynth'  # インストール先を指定
  ]
)

# 依存関係の確認
avisynth_dep = dependency('avisynth', required : true)
# static : true で cudart_static をリンクする (meson 1.2 以降の既定だが、明示しておく)
cuda_dep = dependency('cuda', version : '>=11.0', required : true, static : true)
threads_dep = dependency('threads')

# ビルド設定
cuda_args = [ '-DENABLE_CUDA=1' ]

# CUDAのコード生成対象。
# Windows版 (cudaver.props) と同じ範囲を対象にする。
# code=compute_XX (PTXのみ) にしているのもWindows版に揃えたもので、
# ここに無い新しい世代のGPUでもドライバのJITで動作する。
#
# 注意: CUDA 12 は compute_35 (Kepler) のサポートを打ち切ったため、
# Kepler対応の配布バイナリを作るにはCUDA 11.8が必要
# (docker/docker_ubuntu2004_cuda11 を参照)。
# 一方、利用者の環境でソースビルドする場合はCUDA 12しか無いこともあるため、
# nvccのバージョンを見てcompute_35を落とす。
nvcc = meson.get_compiler('cuda')
if nvcc.version().version_compare('< 12.0')
  cuda_args += [ '-gencode=arch=compute_35,code=compute_35' ]
else
  message('nvcc @0@ は compute_35 (Kepler) に対応しないため対象から外します'.format(nvcc.version()))
endif
cuda_args += [
  '-gencode=arch=compute_50,code=compute_50',
  '-gencode=arch=compute_61,code=compute_61',
  '-gencode=arch=compute_75,code=compute_75',
  '-gencode=arch=compute_86,code=compute_86',
]
cpp_args = [ '-DENABLE_CUDA=1' ]
link_args = []
is_x86 = host_machine.cpu_family() in ['x86', 'x86_64']
if is_x86
  cpp_args += ['-DENABLE_X86_SIMD=1']
  cuda_args += ['-DENABLE_X86_SIMD=1']
else
  cpp_args += ['-DENABLE_X86_SIMD=0']
  cuda_args += ['-DENABLE_X86_SIMD=0']
endif
if host_machine.system() == 'linux'
  # 各プラグインのAVS_linkageをAviSynth本体の同名シンボルから分離する
  link_args += [ '-Wl,-Bsymbolic' ]
  cpp_args += [ '-std=c++17',
    '-fno-operator-names',
    '-Wno-unused-variable',
    '-Wno-unused-function',
    '-Wno-unused-value',
    '-Wno-unused-label',
    '-Wno-unused-parameter',
    '-Wno-unused-type',
    '-Wno-unknown-pragmas',
    '-Wno-unused-but-set-variable',
    '-Wno-reorder',
    '-Wno-sign-conversion'
  ]
  cuda_args += [ '-std=c++17',
    '-Wno-deprecated-gpu-targets',
    '-allow-unsupported-compiler',
    '-Xcompiler=-Wno-unused-variable',
    '-Xcompiler=-Wno-unused-function',
    '-Xcompiler=-Wno-unused-value',
    '-Xcompiler=-Wno-unused-label',
    '-Xcompiler=-Wno-unused-parameter',
    '-Xcompiler=-Wno-unused-type',
    '-Xcompiler=-Wno-unknown-pragmas',
    '-Xcompiler=-Wno-unused-but-set-variable',
    '-Xcompiler=-Wno-sign-conversion',
    '-Xcompiler=-Wno-maybe-uninitialized',
    '-diag-suppress=177',  # 未使用変数の警告
    '-diag-suppress=550',  # 未初期化変数の警告
    '-diag-suppress=68',   # 符号変換の警告
    '-Xcompiler=-Wno-restrict'  # restrict修飾子の警告
  ]
endif

# SIMD 拡張命令セット用のコンパイルフラグ
sse2_args = cpp_args + ['-msse2']
ssse3_args = cpp_args + ['-mssse3']
sse41_args = cpp_args + ['-msse4.1']
avx_args = cpp_args + ['-mavx', '-mpopcnt']
avx2_args = cpp_args + ['-mavx2', '-mfma', '-mpopcnt', '-mbmi', '-mbmi2']
avx512_args = cpp_args + ['-mavx512f', '-mavx512bw', '-mpopcnt', '-mbmi', '-mbmi2']

# サブディレクトリのビルド設定
subdir('common')
subdir('KUtil')
subdir('KFM')
subdir('NNEDI3')
subdir('masktools')
subdir('KTGMC')
subdir('AvsCUDA')
