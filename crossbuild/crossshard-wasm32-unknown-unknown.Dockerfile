INCLUDE crossbase-x64

# wasm32
FROM shard_builder as shard_wasm32-unknown-unknown
ENV compiler_target="wasm32-unknown-unknown"
INCLUDE lib/crossbuild/emscripten_native_install
