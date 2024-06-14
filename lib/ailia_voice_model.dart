// ailia SDKとTacotron2を使用して入力されたテキストから音声を生成する

import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart'; // malloc
import 'package:ailia_voice/ailia_voice.dart' as ailia_voice_dart;

String _ailiaCommonGetPath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libailia.so';
  }
  if (Platform.isMacOS) {
    return 'libailia.dylib';
  }
  if (Platform.isWindows) {
    return 'ailia.dll';
  }
  return 'internal';
}

String _ailiaCommonGetVoicePath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libailia_voice.so';
  }
  if (Platform.isMacOS) {
    return 'libailia_voice.dylib';
  }
  if (Platform.isWindows) {
    return 'ailia_voice.dll';
  }
  return 'internal';
}

ffi.DynamicLibrary _ailiaCommonGetLibrary(String path) {
  final ffi.DynamicLibrary library;
  if (Platform.isIOS) {
    library = ffi.DynamicLibrary.process();
  } else {
    library = ffi.DynamicLibrary.open(path);
  }
  return library;
}

class AiliaTextToSpeechResult {
  final int sampleRate;
  final int nChannels;
  final List<double> pcm;

  AiliaTextToSpeechResult({
    required this.sampleRate,
    required this.nChannels,
    required this.pcm,
  });
}

class AiliaVoiceModel {
  ffi.DynamicLibrary? ailia;
  dynamic ailiaVoice;
  ffi.Pointer<ffi.Pointer<ailia_voice_dart.AILIAVoice>>? ppAilia;
  bool available = false;
  bool debug = false;

  // DLLから関数ポインタを取得
  // ailia_audio.dartから取得できるポインタはPrivate関数であり取得できないので、DLLから直接取得する
  ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> getCallback() {
    ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> callback =
        malloc<ailia_voice_dart.AILIAVoiceApiCallback>();

    callback.ref.ailiaCreate = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ffi.Pointer<ailia_voice_dart.AILIANetwork>>,
              ffi.Int32,
              ffi.Int32,
            )>>('ailiaCreate');
    callback.ref.ailiaOpenWeightFileA = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Int8>,
            )>>('ailiaOpenWeightFileA');
    callback.ref.ailiaOpenWeightFileW = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.wchar_t>,
            )>>('ailiaOpenWeightFileW');
    callback.ref.ailiaOpenWeightMem = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.Uint32,
            )>>('ailiaOpenWeightMem');
    callback.ref.ailiaSetMemoryMode = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Uint32,
            )>>('ailiaSetMemoryMode');
    callback.ref.ailiaDestroy = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Void Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaDestroy');
    callback.ref.ailiaUpdate = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaUpdate');

    callback.ref.ailiaGetBlobIndexByInputIndex = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Uint32>,
              ffi.Uint32,
            )>>('ailiaGetBlobIndexByInputIndex');

    callback.ref.ailiaGetBlobIndexByOutputIndex = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Uint32>,
              ffi.Uint32,
            )>>('ailiaGetBlobIndexByOutputIndex');
    callback.ref.ailiaGetBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.Uint32,
              ffi.Uint32,
            )>>('ailiaGetBlobData');

    callback.ref.ailiaSetInputBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.Uint32,
              ffi.Uint32,
            )>>('ailiaSetInputBlobData');

    callback.ref.ailiaSetInputBlobShape = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.AILIAShape>,
              ffi.Uint32,
              ffi.Uint32,
            )>>('ailiaSetInputBlobShape');

    callback.ref.ailiaGetBlobShape = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int32 Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.AILIAShape>,
              ffi.Uint32,
              ffi.Uint32,
            )>>('ailiaGetBlobShape');

    callback.ref.ailiaGetErrorDetail = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Pointer<ffi.Int8> Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaGetErrorDetail');

    return callback;
  }

  // モデルを開く
  String open(
    File encoder,
    File decoder,
    File postnet,
    File waveglow,
    String dicFolder,
  ) {
    ailiaVoice = ailia_voice_dart.ailiaVoiceFFI(
      _ailiaCommonGetLibrary(_ailiaCommonGetVoicePath()),
    );
    ailia = _ailiaCommonGetLibrary(_ailiaCommonGetPath());

    ppAilia = malloc<ffi.Pointer<ailia_voice_dart.AILIAVoice>>();

    ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> callback =
        getCallback();

    int memoryMode = ailia_voice_dart.AILIA_MEMORY_REDUCE_CONSTANT |
        ailia_voice_dart.AILIA_MEMORY_REDUCE_CONSTANT_WITH_INPUT_INITIALIZER |
        ailia_voice_dart.AILIA_MEMORY_REUSE_INTERSTAGE;
    int flag = ailia_voice_dart.AILIA_VOICE_FLAG_NONE;

    int status = ailiaVoice.ailiaVoiceCreate(
      ppAilia,
      ailia_voice_dart.AILIA_ENVIRONMENT_ID_AUTO,
      ailia_voice_dart.AILIA_MULTITHREAD_AUTO,
      memoryMode,
      flag,
      callback.ref,
      ailia_voice_dart.AILIA_VOICE_API_CALLBACK_VERSION,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceCreate failed $status");
      return "Error";
    }

    status = ailiaVoice.ailiaVoiceOpenDictionaryFileA(
      ppAilia!.value,
      dicFolder.toNativeUtf8().cast<ffi.Int8>(),
      ailia_voice_dart.AILIA_VOICE_DICTIONARY_TYPE_OPEN_JTALK,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceOpenDictionaryFileA Error $status");
      return "Error";
    }

    status = ailiaVoice.ailiaVoiceOpenModelFileA(
      ppAilia!.value,
      encoder.path.toNativeUtf8().cast<ffi.Int8>(),
      decoder.path.toNativeUtf8().cast<ffi.Int8>(),
      postnet.path.toNativeUtf8().cast<ffi.Int8>(),
      waveglow.path.toNativeUtf8().cast<ffi.Int8>(),
      ailia_voice_dart.AILIA_VOICE_MODEL_TYPE_TACOTRON2,
      ailia_voice_dart.AILIA_VOICE_CLEANER_TYPE_BASIC,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceOpenModelFileA Error $status");
      return "Error";
    }

    malloc.free(callback);

    print("ailia Voice initialize success");

    available = true;

    return "Success";
  }

  void close() {
    ffi.Pointer<ailia_voice_dart.AILIAVoice> net = ppAilia!.value;
    ailiaVoice.ailiaVoiceDestroy(net);
    malloc.free(ppAilia!);

    available = false;
  }

  AiliaTextToSpeechResult textToSpeech(String inputText) {
    AiliaTextToSpeechResult result = AiliaTextToSpeechResult(
      sampleRate: 0,
      nChannels: 0,
      pcm: List<double>.empty(),
    );

    if (!available) {
      print("Model not opened");
      return result;
    }

    print("ailiaVoiceGraphemeToPhoeneme $inputText");

    int status = ailiaVoice.ailiaVoiceGraphemeToPhoeneme(
      ppAilia!.value,
      inputText.toNativeUtf8().cast<ffi.Int8>(),
      ailia_voice_dart.AILIA_VOICE_TEXT_POST_PROCESS_APPEND_ACCENT,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceGraphemeToPhoeneme error $status");
      return result;
    }

    print("ailiaVoiceGetFeatureLength");

    final ffi.Pointer<ffi.Uint32> len = malloc<ffi.Uint32>();
    status = ailiaVoice.ailiaVoiceGetFeatureLength(ppAilia!.value, len);
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceGetFeatureLength error $status");
      return result;
    }

    print("length ${len.value}");

    final ffi.Pointer<ffi.Int8> features = malloc<ffi.Int8>(len.value);
    status = ailiaVoice.ailiaVoiceGetFeatures(
      ppAilia!.value,
      features,
      len.value,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceGetFeatures error $status");
      return result;
    }

    ffi.Pointer<Utf8> p = features.cast<Utf8>();
    String s = p.toDartString();
    print("g2p output $s");

    malloc.free(len);

    print("ailiaVoiceInference");

    status = ailiaVoice.ailiaVoiceInference(ppAilia!.value, features);
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceInference error $status");
      return result;
    }
    malloc.free(features);

    print("ailiaVoiceGetWaveInfo");

    final ffi.Pointer<ffi.Uint32> samples = malloc<ffi.Uint32>();
    final ffi.Pointer<ffi.Uint32> channels = malloc<ffi.Uint32>();
    final ffi.Pointer<ffi.Uint32> samplingRate = malloc<ffi.Uint32>();

    status = ailiaVoice.ailiaVoiceGetWaveInfo(
      ppAilia!.value,
      samples,
      channels,
      samplingRate,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceGetWaveInfo error $status");
      return result;
    }

    print("ailiaVoiceGetWaves");

    final ffi.Pointer<ffi.Float> buf =
        malloc<ffi.Float>(samples.value * channels.value);

    int sizeofFloat = 4;
    status = ailiaVoice.ailiaVoiceGetWaves(
      ppAilia!.value,
      buf,
      samples.value * channels.value * sizeofFloat,
    );
    if (status != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      print("ailiaVoiceGetWaves error  $status");
      return result;
    }

    List<double> pcm = List<double>.empty(growable: true);
    for (int i = 0; i < samples.value * channels.value; i++) {
      pcm.add(buf[i]);
    }

    AiliaTextToSpeechResult resultPcm = AiliaTextToSpeechResult(
      sampleRate: samplingRate.value,
      nChannels: channels.value,
      pcm: pcm,
    );

    print(
        "ailiaVoice output ${samples.value} ${samplingRate.value} ${channels.value}");

    malloc.free(buf);
    malloc.free(samples);
    malloc.free(channels);
    malloc.free(samplingRate);

    return resultPcm;
  }
}
