# godot-quickjs Makefile
# Build GDExtension for all platforms from macOS

.PHONY: all macos ios android windows web clean help

# Default target
all: macos ios web

# macOS universal binary (arm64 + x86_64)
macos:
	@echo "Building macOS (universal)..."
	cmake -B build-macos -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
	cmake --build build-macos -j$$(sysctl -n hw.ncpu)
	@echo "Output: build-macos/kbounce_quickjs.dylib"

# iOS (arm64)
ios:
	@echo "Building iOS..."
	cmake -B build-ios \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
		-DCMAKE_OSX_SYSROOT=$$(xcrun --sdk iphoneos --show-sdk-path) \
		-DCMAKE_BUILD_TYPE=Release
	cmake --build build-ios -j$$(sysctl -n hw.ncpu)
	@echo "Output: build-ios/kbounce_quickjs.dylib"

# Web/WASM (requires Emscripten)
web:
	@echo "Building Web/WASM..."
	@which emcc > /dev/null || (echo "Error: Emscripten not installed. Run: brew install emscripten" && exit 1)
	emcmake cmake -B build-web -DCMAKE_BUILD_TYPE=Release
	cmake --build build-web -j$$(sysctl -n hw.ncpu)
	@echo "Output: build-web/kbounce_quickjs.so"

# Android (requires ANDROID_NDK environment variable)
android:
	@echo "Building Android..."
	@test -n "$$ANDROID_NDK" || (echo "Error: ANDROID_NDK not set" && exit 1)
	cmake -B build-android \
		-DCMAKE_TOOLCHAIN_FILE=$$ANDROID_NDK/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=arm64-v8a \
		-DANDROID_PLATFORM=android-21 \
		-DCMAKE_BUILD_TYPE=Release
	cmake --build build-android -j$$(sysctl -n hw.ncpu)
	@echo "Output: build-android/libkbounce_quickjs.so"

# Windows (cross-compile, requires MinGW-w64)
windows:
	@echo "Building Windows (cross-compile)..."
	@which x86_64-w64-mingw32-gcc > /dev/null || (echo "Error: MinGW-w64 not installed. Run: brew install mingw-w64" && exit 1)
	cmake -B build-windows \
		-DCMAKE_SYSTEM_NAME=Windows \
		-DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
		-DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
		-DCMAKE_BUILD_TYPE=Release
	cmake --build build-windows -j$$(sysctl -n hw.ncpu)
	@echo "Output: build-windows/kbounce_quickjs.dll"

# Copy all built libraries to a Godot project addon folder
# Usage: make install GODOT_PROJECT=/path/to/godot/project
install:
	@test -n "$(GODOT_PROJECT)" || (echo "Error: GODOT_PROJECT not set. Usage: make install GODOT_PROJECT=/path/to/project" && exit 1)
	@mkdir -p $(GODOT_PROJECT)/addons/kbounce_quickjs/bin
	@cp kbounce_quickjs.gdextension $(GODOT_PROJECT)/addons/kbounce_quickjs/
	@test -f build-macos/kbounce_quickjs.dylib && cp build-macos/kbounce_quickjs.dylib $(GODOT_PROJECT)/addons/kbounce_quickjs/bin/kbounce_quickjs.macos.release.dylib || true
	@test -f build-ios/kbounce_quickjs.dylib && cp build-ios/kbounce_quickjs.dylib $(GODOT_PROJECT)/addons/kbounce_quickjs/bin/kbounce_quickjs.ios.release.dylib || true
	@test -f build-web/kbounce_quickjs.so && cp build-web/kbounce_quickjs.so $(GODOT_PROJECT)/addons/kbounce_quickjs/bin/kbounce_quickjs.web.release.wasm32.wasm || true
	@test -f build-android/libkbounce_quickjs.so && cp build-android/libkbounce_quickjs.so $(GODOT_PROJECT)/addons/kbounce_quickjs/bin/libkbounce_quickjs.android.release.arm64.so || true
	@test -f build-windows/kbounce_quickjs.dll && cp build-windows/kbounce_quickjs.dll $(GODOT_PROJECT)/addons/kbounce_quickjs/bin/kbounce_quickjs.windows.release.x86_64.dll || true
	@echo "Installed to $(GODOT_PROJECT)/addons/kbounce_quickjs/"

# Clean all build directories
clean:
	rm -rf build-macos build-ios build-web build-android build-windows

help:
	@echo "godot-quickjs build targets:"
	@echo ""
	@echo "  make all       - Build macOS, iOS, and Web (default)"
	@echo "  make macos     - Build macOS universal binary (arm64 + x86_64)"
	@echo "  make ios       - Build iOS (arm64)"
	@echo "  make web       - Build Web/WASM (requires Emscripten)"
	@echo "  make android   - Build Android (requires ANDROID_NDK)"
	@echo "  make windows   - Build Windows (requires MinGW-w64)"
	@echo "  make install GODOT_PROJECT=/path/to/project - Install to Godot project"
	@echo "  make clean     - Remove all build directories"
	@echo ""
	@echo "Requirements:"
	@echo "  - CMake 3.20+"
	@echo "  - Xcode (macOS/iOS)"
	@echo "  - Emscripten: brew install emscripten"
	@echo "  - Android NDK: set ANDROID_NDK environment variable"
	@echo "  - MinGW-w64: brew install mingw-w64"
