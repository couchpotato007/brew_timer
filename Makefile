
ODIN=odin
APP=app
SRC=app

ANDROID_DIR=android
NDK=$(HOME)/Android/Sdk/ndk/30.0.14904198/
SDK=$(HOME)/Android/Sdk/
API=29
ABI=arm64-v8a

RAYLIB_DIR=external/raylib
CLAY_DIR=external/clay
RAYLIB_BUILD=build/raylib-android
BUILD_OBJ=build/android_obj

CC_ANDROID=$(NDK)toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android$(API)-clang
NDK_GLUE_SRC=$(NDK)sources/android/native_app_glue/android_native_app_glue.c
NDK_GLUE_INC=$(NDK)sources/android/native_app_glue

# Toolchain
CMAKE=$(NDK)/cmake/3.22.1/bin/cmake


desktop:
	$(ODIN) build $(SRC) -out:build/$(APP)_desktop

run:
	$(ODIN) run $(SRC)


raylib_android:
	mkdir -p $(RAYLIB_BUILD)/$(ABI)

	cmake -B $(RAYLIB_BUILD)/build \
		-S $(RAYLIB_DIR) \
		-G "Ninja" \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DCMAKE_TOOLCHAIN_FILE=$(NDK)/build/cmake/android.toolchain.cmake \
		-DPLATFORM=Android \
		-DANDROID_ABI=arm64-v8a \
		-DANDROID_PLATFORM=android-$(API) \
		-DBUILD_EXAMPLES=OFF

	cmake --build $(RAYLIB_BUILD)/build

	cp $(RAYLIB_BUILD)/build/raylib/libraylib.a $(RAYLIB_BUILD)/$(ABI)

odin_object:
	mkdir -p $(BUILD_OBJ)
	export ODIN_ANDROID_NDK=$(NDK); \
	$(ODIN) build $(SRC) \
		-target:linux_arm64 \
		-subtarget:android \
		-build-mode:obj \
		-no-entry-point \
		-debug \
		-out:$(BUILD_OBJ)/game.o

clay_android:
	cp $(CLAY_DIR)/clay.h $(BUILD_OBJ)/clay.c && \
	clang-21 -c -DCLAY_IMPLEMENTATION -o $(BUILD_OBJ)/clay.o -ffreestanding -static -target aarch64-linux-android21 $(BUILD_OBJ)/clay.c -fPIC -O3 && ar r $(SRC)/clay-odin/android/clay.a $(BUILD_OBJ)/clay.o


native_glue:
	mkdir -p $(BUILD_OBJ)
	$(CC_ANDROID) -c $(NDK_GLUE_SRC) \
		-I$(NDK_GLUE_INC) \
		-o $(BUILD_OBJ)/native_app_glue.o
	$(CC_ANDROID) -c native/main.c \
		-o $(BUILD_OBJ)/main.o


odin_android: raylib_android odin_object native_glue clay_android
	mkdir -p $(ANDROID_DIR)/lib/lib/$(ABI)
	$(CC_ANDROID) -shared \
		-o $(ANDROID_DIR)/lib/lib/$(ABI)/libmain.so \
		$(BUILD_OBJ)/*.o \
		$(SRC)/clay-odin/android/clay.a \
		-L$(RAYLIB_BUILD)/$(ABI) -lraylib \
		-lGLESv2 -llog -landroid -lEGL -lm -lOpenSLES -ldl \
		-Wl,--wrap,fopen \
		-Wl,-u,ANativeActivity_onCreate


apk: odin_android
	mkdir -p android/assets
	cp -r assets/ android/
	cd $(ANDROID_DIR)
	export ODIN_ANDROID_SDK=$(SDK); \
	export ODIN_ANDROID_NDK=$(NDK); \
	odin bundle android android -android-keystore:$(HOME)/.android/debug.keystore -android-keystore-password:"android"


clean:
	rm -rf build
	rm -rf $(RAYLIB_BUILD)
	rm -rf $(RAYLIB_DIR)/Build
	rm -rf $(ANDROID_DIR)/app/src/main/jniLibs
	rm -f $(SRC)/clay-odin/android/clay.a
