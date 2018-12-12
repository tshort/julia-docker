
# This installs Emscripten for compilation to wasm32-unknown-unknown using a recent LLVM.

# Note that this uses the latest version of stuff.

# LLVM
WORKDIR /src/llvm-emscripten
RUN git clone --depth 1 https://github.com/llvm-mirror/llvm.git .
WORKDIR /src/llvm-emscripten/tools
RUN git clone --depth 1 https://github.com/llvm-mirror/clang.git
RUN git clone --depth 1 https://github.com/llvm-mirror/lld.git

WORKDIR /src/llvm-emscripten-build    
RUN source /build.sh; \
    cmake -G "Unix Makefiles" \
        -DLLVM_TARGETS_TO_BUILD:STRING=WebAssembly \
        -DLLVM_PARALLEL_COMPILE_JOBS=$(($(nproc)+1)) \
        -DLLVM_PARALLEL_LINK_JOBS=$(($(nproc)+1)) \
        -DLLVM_BINDINGS_LIST="" \
        -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-unknown-unknown \
        -DDEFAULT_SYSROOT="$(get_sysroot)" \
        -DGCC_INSTALL_PREFIX="/opt/${compiler_target}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_ASSERTIONS=Off \
        -DCMAKE_INSTALL_PREFIX="/opt/${compiler_target}" \
        -DLIBCXX_HAS_MUSL_LIBC=On \
        -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
        -DLLVM_TARGET_TRIPLE_ENV=LLVM_TARGET \
        -DCOMPILER_RT_BUILD_SANITIZERS=Off \
        -DCOMPILER_RT_BUILD_PROFILE=Off \
        -DCOMPILER_RT_BUILD_LIBFUZZER=Off \
        -DCOMPILER_RT_BUILD_XRAY=Off \
        /src/llvm-emscripten
RUN make -j$(($(nproc)+1))
RUN make install
ENV LLVM_ROOT=/opt/${compiler_target}/bin

# Emscripten
WORKDIR /opt/${compiler_target}/lib
RUN git clone --depth 1 https://github.com/kripken/emscripten.git
ENV EMSCRIPTEN=/opt/${compiler_target}/lib/emscripten

# Binaryen
WORKDIR /src
RUN wget https://github.com/WebAssembly/binaryen/archive/version_58.tar.gz
RUN tar zxvf version_58.tar.gz
WORKDIR /src/binaryen-version_58
RUN source /build.sh; \
    cmake -DCMAKE_INSTALL_PREFIX=/opt/${compiler_target} -DCMAKE_BUILD_TYPE=Release
RUN make -j$(($(nproc)+1))
RUN make install
ENV BINARYEN_ROOT=/opt/${compiler_target}/
ENV BINARYEN=/opt/${compiler_target}/

RUN apk add nodejs

ENV CC=/opt/${compiler_target}/lib/emscripten/emcc \
    CXX=/opt/${compiler_target}/lib/emscripten/em++ \
    AR=/opt/${compiler_target}/lib/emscripten/emar \
    LD=/opt/${compiler_target}/lib/emscripten/emcc \
    NM=/opt/${compiler_target}/bin/llvm-nm \
    LDSHARED=/opt/${compiler_target}/lib/emscripten/emcc \
    RANLIB=/opt/${compiler_target}/lib/emscripten/emranlib \
    EMMAKEN_COMPILER=/opt/${compiler_target}/bin/clang++ \
    EMSCRIPTEN_TOOLS=/opt/${compiler_target}/lib/emscripten/tools \
    LLVM=/opt/${compiler_target}/bin \
    CFLAGS= \
    EMMAKEN_CFLAGS= \
    HOST_CC=/opt/${compiler_target}/bin/clang \
    HOST_CXX=/opt/${compiler_target}/bin/clang++ \
    HOST_CFLAGS=-W \
    HOST_CXXFLAGS=-W \
    PKG_CONFIG_LIBDIR=/opt/${compiler_target}/lib/emscripten/system/local/lib/pkgconfig:/opt/${compiler_target}/lib/emscripten/system/lib/pkgconfig \
    PKG_CONFIG_PATH= \
    CROSS_COMPILE=/opt/${compiler_target}/lib/emscripten/em \
    PATH=$PATH:$EMSCRIPTEN:$LLVM_ROOT 

WORKDIR $EMSCRIPTEN
RUN emcc
RUN python tests/runner.py test_loop

# Install cmake toolchain
COPY cmake_toolchains/${compiler_target}.toolchain /opt/${compiler_target}/

# Cleanup
# RUN rm -r /src/*
