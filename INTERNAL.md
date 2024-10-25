Please put libraries here by using release script.

ailia/android/src/main/jniLibs/arm64-v8a/libailia_voice.so
ailia/ios/libailia_voice.a
ailia/macos/libailia_voice.dylib

Please put interface here.

native/ailia.h
native/ailia_voice.h
native/ailia_audio.h
native/ailia_call.h

Temporally add ffigen to pubspec.yaml
Add #include <stddef.h> to ailia.h

Please run below command for generation.

export PATH=$PATH:/Users/kyakuno/flutter_arm64/bin
dart run ffigen --config ffigen_ailia_voice.yaml

Output is ailia_voice.dart
