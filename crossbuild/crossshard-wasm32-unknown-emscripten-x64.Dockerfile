INCLUDE crossbase-x64

# wasm32
FROM shard_builder as shard_wasm32-unknown-emscripten
ENV compiler_target="wasm32-unknown-emscripten"
INCLUDE lib/crossbuild/emscripten_install
