// Generate voice from text

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

String _ailiaCommonGetAudioPath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libailia_audio.so';
  }
  if (Platform.isMacOS) {
    return 'libailia_audio.dylib';
  }
  if (Platform.isWindows) {
    return 'ailia_audio.dll';
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

class AiliaVoiceResult {
  final int sampleRate;
  final int nChannels;
  final List<double> pcm;

  AiliaVoiceResult({
    required this.sampleRate,
    required this.nChannels,
    required this.pcm,
  });
}

class AiliaVoiceModel {
  ffi.DynamicLibrary? ailia;
  ffi.DynamicLibrary? ailiaAudio;
  dynamic ailiaVoice;
  ffi.Pointer<ffi.Pointer<ailia_voice_dart.AILIAVoice>>? ppAilia;
  bool available = false;
  bool debug = false;

  void throwError(String funcName, int code) {
    if (code != ailia_voice_dart.AILIA_STATUS_SUCCESS) {
      ffi.Pointer<Utf8> p =
          ailiaVoice.ailiaVoiceGetErrorDetail(ppAilia!.value).cast<Utf8>();
      String errorDetail = p.toDartString();
      throw Exception("$funcName failed $code \n detail $errorDetail");
    }
  }

  // DLLから関数ポインタを取得
  // ailia_audio.dartから取得できるポインタはPrivate関数であり取得できないので、DLLから直接取得する
  ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> getCallback() {
    ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> callback =
        malloc<ailia_voice_dart.AILIAVoiceApiCallback>();

    callback.ref.ailiaAudioResample = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Void>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Int,
            )>>('ailiaAudioResample');
    callback.ref.ailiaAudioGetResampleLen = ailiaAudio!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Int>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
            )>>('ailiaAudioGetResampleLen');
    callback.ref.ailiaCreate = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ffi.Pointer<ailia_voice_dart.AILIANetwork>>,
              ffi.Int,
              ffi.Int,
            )>>('ailiaCreate');
    callback.ref.ailiaOpenWeightFileA = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Char>,
            )>>('ailiaOpenWeightFileA');
    callback.ref.ailiaOpenWeightFileW = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.WChar>,
            )>>('ailiaOpenWeightFileW');
    callback.ref.ailiaOpenWeightMem = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.UnsignedInt,
            )>>('ailiaOpenWeightMem');
    callback.ref.ailiaSetMemoryMode = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.UnsignedInt,
            )>>('ailiaSetMemoryMode');
    callback.ref.ailiaDestroy = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Void Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaDestroy');
    callback.ref.ailiaUpdate = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaUpdate');

    callback.ref.ailiaGetBlobIndexByInputIndex = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobIndexByInputIndex');

    callback.ref.ailiaGetBlobIndexByOutputIndex = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobIndexByOutputIndex');
    callback.ref.ailiaGetBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobData');

    callback.ref.ailiaSetInputBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.Void>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaSetInputBlobData');

    callback.ref.ailiaSetInputBlobShape = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.AILIAShape>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaSetInputBlobShape');

    callback.ref.ailiaGetBlobShape = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ailia_voice_dart.AILIAShape>,
              ffi.UnsignedInt,
              ffi.UnsignedInt,
            )>>('ailiaGetBlobShape');

    callback.ref.ailiaGetInputBlobCount = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>t,
            )>>('ailiaGetInputBlobCount');
    callback.ref.ailiaGetOutputBlobCount = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.Pointer<ffi.UnsignedInt>,
            )>>('ailiaGetOutputBlobCount');

    callback.ref.ailiaGetErrorDetail = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Pointer<ffi.Char> Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
            )>>('ailiaGetErrorDetail');

    callback.ref.ailiaCopyBlobData = ailia!.lookup<
        ffi.NativeFunction<
            ffi.Int Function(
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.UnsignedInt,
              ffi.Pointer<ailia_voice_dart.AILIANetwork>,
              ffi.UnsignedInt,
            )>>('ailiaCopyBlobData');

    return callback;
  }

  // モデルを開く
  void openModel(
    String encoder,
    String decoder1,
    String decoder2,
    String wave,
    String? ssl,
    int modelType,
    int cleanerType,
    int envId,
  ) {
    close();

    ailiaVoice = ailia_voice_dart.ailiaVoiceFFI(
      _ailiaCommonGetLibrary(_ailiaCommonGetVoicePath()),
    );
    ailia = _ailiaCommonGetLibrary(_ailiaCommonGetPath());
    ailiaAudio = _ailiaCommonGetLibrary(_ailiaCommonGetAudioPath());

    ppAilia = malloc<ffi.Pointer<ailia_voice_dart.AILIAVoice>>();

    ffi.Pointer<ailia_voice_dart.AILIAVoiceApiCallback> callback =
        getCallback();

    int memoryMode = ailia_voice_dart.AILIA_MEMORY_REDUCE_CONSTANT |
        ailia_voice_dart.AILIA_MEMORY_REDUCE_CONSTANT_WITH_INPUT_INITIALIZER |
        ailia_voice_dart.AILIA_MEMORY_REUSE_INTERSTAGE;
    int flag = ailia_voice_dart.AILIA_VOICE_FLAG_NONE;

    int status = ailiaVoice.ailiaVoiceCreate(
      ppAilia,
      envId,
      ailia_voice_dart.AILIA_MULTITHREAD_AUTO,
      memoryMode,
      flag,
      callback.ref,
      ailia_voice_dart.AILIA_VOICE_API_CALLBACK_VERSION,
    );
    throwError("ailiaVoiceCreate", status);

    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenModelFileW(
        ppAilia!.value,
        encoder.toNativeUtf16().cast<ffi.WChar>(),
        decoder1.toNativeUtf16().cast<ffi.WChar>(),
        decoder2.toNativeUtf16().cast<ffi.WChar>(),
        wave.toNativeUtf16().cast<ffi.WChar>(),
        (ssl != null) ? ssl.toNativeUtf16().cast<ffi.WChar>():ffi.nullptr,
        modelType,
        cleanerType,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenModelFileA(
        ppAilia!.value,
        encoder.toNativeUtf8().cast<ffi.Char>(),
        decoder1.toNativeUtf8().cast<ffi.Char>(),
        decoder2.toNativeUtf8().cast<ffi.Char>(),
        wave.toNativeUtf8().cast<ffi.Char>(),
        (ssl != null) ? ssl.toNativeUtf8().cast<ffi.Char>():ffi.nullptr,
        modelType,
        ailia_voice_dart.AILIA_VOICE_CLEANER_TYPE_BASIC,
      );
    }
    throwError("ailiaVoiceOpenModelFile", status);

    malloc.free(callback);

    if (debug){
      print("ailia Voice initialize success");
    }

    available = true;
  }

  // ユーザ辞書を設定する
  void setUserDictionary(
    String dicFile,
    int dictionaryType,
  ) {
    int status = 0;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceSetUserDictionaryFileW(
        ppAilia!.value,
        dicFile.toNativeUtf16().cast<ffi.WChar>(),
        dictionaryType,
      );
    }else{
      status = ailiaVoice.ailiaVoiceSetUserDictionaryFileA(
        ppAilia!.value,
        dicFile.toNativeUtf8().cast<ffi.Char>(),
        dictionaryType,
      );
    }
    throwError("ailiaVoiceSetUserDictionaryFile", status);
  }

  // 辞書を開く
  void openDictionary(
    String dicFolder,
    int dictionaryType,
  ) {
    int status = 0;
    if (Platform.isWindows){
      status = ailiaVoice.ailiaVoiceOpenDictionaryFileW(
        ppAilia!.value,
        dicFolder.toNativeUtf16().cast<ffi.WChar>(),
        dictionaryType,
      );
    }else{
      status = ailiaVoice.ailiaVoiceOpenDictionaryFileA(
        ppAilia!.value,
        dicFolder.toNativeUtf8().cast<ffi.Char>(),
        dictionaryType,
      );
    }
    throwError("ailiaVoiceOpenDictionaryFile", status);
  }

  // モデルと辞書を開く（互換性用）
  void open(
    String encoder,
    String decoder1,
    String decoder2,
    String wave,
    String? ssl,
    String dicFolder,
    int modelType,
    int cleanerType,
    int dictionaryType,
    int envId,
  ) {
    openModel(encoder, decoder1, decoder2, wave, ssl, modelType, cleanerType, envId);
    openDictionary(dicFolder, dictionaryType);
  }

  // モデルを閉じる
  void close() {
    if (!available){
      return;
    }

    ffi.Pointer<ailia_voice_dart.AILIAVoice> net = ppAilia!.value;
    ailiaVoice.ailiaVoiceDestroy(net);
    malloc.free(ppAilia!);

    available = false;
  }

  // G2Pの実行
  String g2p(String inputText, int g2pType){
    if (debug){
      print("ailiaVoiceGraphemeToPhoeneme $inputText");
    }

    int status = ailiaVoice.ailiaVoiceGraphemeToPhoneme(
      ppAilia!.value,
      inputText.toNativeUtf8().cast<ffi.Char>(),
      g2pType,
    );
    throwError("ailiaVoiceGraphemeToPhoneme", status);

    final ffi.Pointer<ffi.UnsignedInt> len = malloc<ffi.UnsignedInt>();
    status = ailiaVoice.ailiaVoiceGetFeatureLength(ppAilia!.value, len);
    throwError("ailiaVoiceGetFeatureLength", status);
    if (debug){
      print("length ${len.value}");
    }

    final ffi.Pointer<ffi.Char> features = malloc<ffi.Char>(len.value);
    status = ailiaVoice.ailiaVoiceGetFeatures(
      ppAilia!.value,
      features,
      len.value,
    );
    throwError("ailiaVoiceGetFeatures", status);

    ffi.Pointer<Utf8> p = features.cast<Utf8>();
    String s = p.toDartString();
    if (debug){
      print("g2p output $s");
    }

    malloc.free(len);
    malloc.free(features);

    return s;
  }

  // リファレンスとなる音声を登録
  void setReference(List<double> pcm, int sampleRate, int nChannels, String referenceFeature){
    if (!available) {
      throw Exception("Model not opened yet. wait one second and try again.");
    }

    ffi.Pointer<ffi.Float> waveBuf = malloc<ffi.Float>(pcm.length);
    for (int i = 0; i < pcm.length; i++) {
      waveBuf[i] = pcm[i];
    }

    int status = ailiaVoice.ailiaVoiceSetReference(
      ppAilia!.value,
      waveBuf,
      pcm.length * 4,
      nChannels,
      sampleRate,
      referenceFeature.toNativeUtf8().cast<ffi.Char>()
    );
    throwError("ailiaVoiceSetReference", status);

    malloc.free(waveBuf);
  }

  // 音声合成の実行
  AiliaVoiceResult inference(String inputFeature) {
    AiliaVoiceResult result = AiliaVoiceResult(
      sampleRate: 0,
      nChannels: 0,
      pcm: List<double>.empty(),
    );

    if (!available) {
      print("Model not opened");
      return result;
    }

    if (debug){
      print("ailiaVoiceInference");
    }

    int status = ailiaVoice.ailiaVoiceInference(ppAilia!.value, inputFeature.toNativeUtf8().cast<ffi.Char>());
    throwError("ailiaVoiceInference", status);

    if (debug){
      print("ailiaVoiceGetWaveInfo");
    }

    final ffi.Pointer<ffi.UnsignedInt> samples = malloc<ffi.UnsignedInt>();
    final ffi.Pointer<ffi.UnsignedInt> channels = malloc<ffi.UnsignedInt>();
    final ffi.Pointer<ffi.UnsignedInt> samplingRate = malloc<ffi.UnsignedInt>();

    status = ailiaVoice.ailiaVoiceGetWaveInfo(
      ppAilia!.value,
      samples,
      channels,
      samplingRate,
    );
    throwError("ailiaVoiceGetWaveInfo", status);

    if (debug){
      print("ailiaVoiceGetWaves");
    }

    final ffi.Pointer<ffi.Float> buf =
        malloc<ffi.Float>(samples.value * channels.value);

    int sizeofFloat = 4;
    status = ailiaVoice.ailiaVoiceGetWave(
      ppAilia!.value,
      buf,
      samples.value * channels.value * sizeofFloat,
    );
    throwError("ailiaVoiceGetWaves", status);

    List<double> pcm = List<double>.empty(growable: true);
    for (int i = 0; i < samples.value * channels.value; i++) {
      pcm.add(buf[i]);
    }

    AiliaVoiceResult resultPcm = AiliaVoiceResult(
      sampleRate: samplingRate.value,
      nChannels: channels.value,
      pcm: pcm,
    );

    if (debug){
      print(
          "ailiaVoice output ${samples.value} ${samplingRate.value} ${channels.value}");
    }

    malloc.free(buf);
    malloc.free(samples);
    malloc.free(channels);
    malloc.free(samplingRate);

    return resultPcm;
  }
}
