cmake_minimum_required(VERSION 3.20)
project(kbounce_quickjs)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# macOS: set universal binary architectures BEFORE any targets are defined
if(APPLE AND NOT IOS)
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "Build architectures for macOS")
endif()

# Emscripten/WASM settings
if(EMSCRIPTEN)
    set(CMAKE_EXECUTABLE_SUFFIX ".wasm")
    add_compile_options(-pthread)
    add_link_options(-pthread -sSIDE_MODULE=1 -sWASM_BIGINT)
endif()

# godot-cpp
add_subdirectory(extern/godot-cpp)

# QuickJS as static library
add_library(quickjs STATIC
    extern/quickjs/quickjs.c
    extern/quickjs/libregexp.c
    extern/quickjs/libunicode.c
    extern/quickjs/cutils.c
    extern/quickjs/libbf.c
)
target_include_directories(quickjs PUBLIC extern/quickjs)
target_compile_definitions(quickjs PRIVATE
    CONFIG_VERSION="2024-01-13"
    _GNU_SOURCE
    CONFIG_BIGNUM
)

# Silence warnings for QuickJS C code
if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options(quickjs PRIVATE -w)
endif()


# Our GDExtension
add_library(kbounce_quickjs SHARED
    src/quickjs_gdextension.cpp
    src/quickjs_wrapper.cpp
)
target_link_libraries(kbounce_quickjs PRIVATE godot::cpp quickjs)
target_include_directories(kbounce_quickjs PRIVATE src extern/quickjs)

# Set output name without lib prefix on some platforms
set_target_properties(kbounce_quickjs PROPERTIES
    PREFIX ""
    OUTPUT_NAME "kbounce_quickjs"
)

