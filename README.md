# godot-quickjs

A minimal GDExtension that embeds [QuickJS](https://bellard.org/quickjs/) JavaScript engine into Godot 4, allowing GDScript to evaluate JavaScript code.

## Why?

This extension enables **deterministic JavaScript execution** across all platforms. This is useful when you need identical floating-point behavior everywhere - for example, running the same physics simulation on:

- Game client (Godot on macOS, iOS, Android, Windows, Web)
- Game server (Cloudflare Workers, Node.js)
- Replay verification

By using QuickJS everywhere (including compiled to WASM for web browsers), you avoid subtle floating-point differences between JavaScript engines (V8, SpiderMonkey, JavaScriptCore).

## Features

- Load and execute JavaScript files
- Evaluate JavaScript expressions and statements
- Automatic conversion between JS and Godot types
- Floating-point determinism across all platforms
- Small footprint (~1.6MB for WASM, ~3MB for native)

## Usage

```gdscript
var js = QuickJS.new()

# Evaluate JavaScript code
var result = js.eval("1 + 2")  # Returns 3.0

# Load a JavaScript file
if js.load_file("res://physics.js"):
    var data = js.eval("simulate(10000)")
else:
    print("Error: ", js.get_error())

# Access arrays and objects
var arr = js.eval("[1, 2, 3]")  # Returns Array
var obj = js.eval("({x: 10, y: 20})")  # Returns Dictionary
```

## API

### QuickJS class

| Method | Description |
|--------|-------------|
| `load_file(path: String) -> bool` | Load and execute a JavaScript file |
| `eval(code: String) -> Variant` | Evaluate JavaScript code and return result |
| `get_error() -> String` | Get last error message |

### Type Conversions

| JavaScript | Godot |
|-----------|-------|
| number | float |
| string | String |
| boolean | bool |
| array | Array |
| object | Dictionary |
| null/undefined | null |

## Building

### Requirements

- CMake 3.20+
- Xcode (macOS/iOS)
- Emscripten (Web) - `brew install emscripten`
- Android NDK (Android) - set `ANDROID_NDK` environment variable
- MinGW-w64 (Windows cross-compile) - `brew install mingw-w64`

### Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/sttts/godot-quickjs.git
cd godot-quickjs

# Build all platforms (macOS, iOS, Web)
make all

# Or build specific platforms
make macos    # macOS universal (arm64 + x86_64)
make ios      # iOS (arm64)
make web      # Web/WASM
make android  # Android (requires ANDROID_NDK)
make windows  # Windows (requires MinGW-w64)

# Install to your Godot project
make install GODOT_PROJECT=/path/to/your/godot/project
```

### Manual Build Commands

If you prefer not to use the Makefile:

**macOS (universal binary):**
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
cmake --build build
```

**iOS:**
```bash
cmake -B build-ios \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_OSX_SYSROOT=$(xcrun --sdk iphoneos --show-sdk-path) \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-ios
```

**Web/WASM:**
```bash
emcmake cmake -B build-web -DCMAKE_BUILD_TYPE=Release
cmake --build build-web
```

**Android:**
```bash
cmake -B build-android \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-21 \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-android
```

**Windows (cross-compile from Mac):**
```bash
cmake -B build-windows \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-windows
```

## Installation

1. Build for your target platforms (see above)

2. Copy files to your Godot project:
   ```
   your_project/
   └── addons/
       └── kbounce_quickjs/
           ├── kbounce_quickjs.gdextension
           └── bin/
               ├── kbounce_quickjs.macos.release.dylib
               ├── kbounce_quickjs.ios.release.dylib
               ├── kbounce_quickjs.web.release.wasm32.wasm
               ├── libkbounce_quickjs.android.release.arm64.so
               └── kbounce_quickjs.windows.release.x86_64.dll
   ```

3. Restart Godot editor to load the extension

Or use `make install GODOT_PROJECT=/path/to/project` to automate this.

## License

MIT License

QuickJS is Copyright (c) 2017-2024 Fabrice Bellard and Charlie Gordon, licensed under MIT.
