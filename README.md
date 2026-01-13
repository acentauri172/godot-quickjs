# godot-quickjs

A minimal GDExtension that embeds [QuickJS](https://bellard.org/quickjs/) JavaScript engine into Godot 4, allowing GDScript to evaluate JavaScript code.

## Features

- Load and execute JavaScript files
- Evaluate JavaScript expressions and statements
- Automatic conversion between JS and Godot types (numbers, strings, arrays, objects)
- Floating point determinism matching V8/Node.js

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

### QuickJS

- `load_file(path: String) -> bool` - Load and execute a JavaScript file
- `eval(code: String) -> Variant` - Evaluate JavaScript code and return result
- `get_error() -> String` - Get last error message

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

Requirements:
- CMake 3.20+
- Xcode (macOS)
- Android NDK (Android)
- MinGW-w64 (Windows cross-compile)

### macOS (universal binary)

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
cmake --build build
```

### iOS

```bash
cmake -B build-ios \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-ios
```

### Android

```bash
cmake -B build-android \
    -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-21 \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-android
```

### Windows (cross-compile from Mac)

```bash
cmake -B build-windows \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-windows
```

### Web (Emscripten/WASM)

```bash
# Install Emscripten first: brew install emscripten (macOS)
emcmake cmake -B build-web -DCMAKE_BUILD_TYPE=Release
cmake --build build-web
# Output: build-web/kbounce_quickjs.wasm
```

This ensures identical floating point behavior across all browsers (Chrome/V8, Firefox/SpiderMonkey, Safari/JSC).

## Installation

1. Copy the built library to your Godot project:
   ```
   addons/godot_quickjs/bin/kbounce_quickjs.<platform>.<config>.<ext>
   ```

2. Create or copy the `.gdextension` file to `addons/godot_quickjs/kbounce_quickjs.gdextension`

3. Restart Godot editor to load the extension

## License

MIT License

QuickJS is Copyright (c) 2017-2024 Fabrice Bellard and Charlie Gordon, licensed under MIT.
