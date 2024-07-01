import 'package:flutter/material.dart';

import 'package:ailia/ailia_license.dart';

import 'utils/download_model.dart';
import 'text_to_speech.dart';

import 'package:ailia_voice/ailia_voice.dart' as ailia_voice_dart;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _predictText = 'Model Downloading...';
  final _textToSpeech = TextToSpeech();

  @override
  void initState() {
    super.initState();

    _ailiaVoiceDownloadModel();
  }

  int _downloadCnt = 0;
  List<String> modelList = List<String>.empty(growable: true);

  //int modelType = TextToSpeech.MODEL_TYPE_TACOTRON2;
  int modelType = TextToSpeech.MODEL_TYPE_GPT_SOVITS_JA;
  //int modelType = TextToSpeech.MODEL_TYPE_GPT_SOVITS_EN;

  void _ailiaVoiceDownloadModel() {
    modelList = _textToSpeech.getModelList(modelType);
    _ailiaVoiceDownloadModelOne();
  }

  void _ailiaVoiceDownloadModelOne() {
    String url =
        "https://storage.googleapis.com/ailia-models/${modelList[_downloadCnt + 0]}/${modelList[_downloadCnt + 1]}";
    downloadModel(url, modelList[_downloadCnt + 1], (file) {
      _downloadCnt = _downloadCnt + 2;
      if (_downloadCnt >= modelList.length) {
        _ailiaVoiceTest();
      } else {
        _ailiaVoiceDownloadModelOne();
      }
    });
  }

  void _ailiaVoiceTest() async {
    // Check and download ailia SDK license
    await AiliaLicense.checkAndDownloadLicense();

    // Prepare model file
    String encoderFile = "";
    String decoderFile = "";
    String postnetFile = "";
    String waveglowFile = "";
    String? sslFile;

    if (modelType == TextToSpeech.MODEL_TYPE_TACOTRON2){
      encoderFile = await getModelPath("encoder.onnx");
      decoderFile = await getModelPath("decoder_iter.onnx");
      postnetFile = await getModelPath("postnet.onnx");
      waveglowFile = await getModelPath("waveglow.onnx");
    }

    if (modelType == TextToSpeech.MODEL_TYPE_GPT_SOVITS_JA || modelType == TextToSpeech.MODEL_TYPE_GPT_SOVITS_EN) {
      encoderFile = await getModelPath("t2s_encoder.onnx");
      decoderFile = await getModelPath("t2s_fsdec.onnx");
      postnetFile = await getModelPath("t2s_sdec.opt.onnx");
      waveglowFile = await getModelPath("vits.onnx");
      sslFile = await getModelPath("cnhubert.onnx");
    }

    String? dicFolderOpenJtalk;
    String? dicFolderG2PEn;
    if (modelType == TextToSpeech.MODEL_TYPE_GPT_SOVITS_JA || modelType == TextToSpeech.MODEL_TYPE_GPT_SOVITS_EN) {
      dicFolderOpenJtalk = await getModelPath("open_jtalk_dic_utf_8-1.11/");
    }
    if (modelType == TextToSpeech.MODEL_TYPE_GPT_SOVITS_EN){
      dicFolderG2PEn = await getModelPath("/");
    }

    String targetText = "Hello world.";
    String outputPath = await getModelPath("temp.wav");

    await _textToSpeech.inference(targetText, outputPath, encoderFile,
        decoderFile, postnetFile, waveglowFile, sslFile, dicFolderOpenJtalk, dicFolderG2PEn, modelType);

    setState(() {
      _predictText = "finish";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ailia Voice Sample'),
        ),
        body: Center(
          child: Text('Running on: $_predictText\n'),
        ),
      ),
    );
  }
}
