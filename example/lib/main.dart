import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ailia_voice/ailia_voice.dart';
import 'package:ailia_voice/ailia_voice_model.dart';
import 'package:ailia/ailia_license.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:wav/wav.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'utils/download_model.dart';

import 'dart:io';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

Future<Directory> getDocumentsDirectory(String subFolder) async {
  var doc = await getApplicationDocumentsDirectory();
  var basePath = p.join(doc.path, 'ailia MODELS Flutter');
  final docDir = Directory(basePath);
  if (!docDir.existsSync()) {
    docDir.createSync();
  }
  basePath = p.join(basePath, subFolder);
  final subDir = Directory(basePath);
  if (!subDir.existsSync()) {
    subDir.createSync();
  }
  return subDir;
}

Future<String> ailiaCommonGetModelPath(String path) async {
  Directory tempDir = await getDocumentsDirectory("models");
  String tempPath = tempDir.path;
  var filePath = '$tempPath/$path';
  return filePath;
}

class Speaker {
  void play(AiliaTextToSpeechResult audio) async {
    print("pcm length ${audio.pcm.length}");

    Float64List channel = Float64List(audio.pcm.length);
    for (int i = 0; i < channel.length; i++) {
      channel[i] = audio.pcm[i];
    }

    List<Float64List> channels = List<Float64List>.empty(growable: true);
    channels.add(channel);

    Wav wav = Wav(channels, audio.sampleRate, WavFormat.pcm16bit);
    var filename = await ailiaCommonGetModelPath("temp.wav");

    print(filename);

    await wav.writeFile(filename);

    final player = AudioPlayer();
    await player.play(DeviceFileSource(filename));
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _predictText = 'Unknown';
  //final _ailiaVoicePlugin = AiliaVoice();
  final _ailiaVoiceModel = AiliaVoiceModel();
  final _speaker = Speaker();

  @override
  void initState() {
    super.initState();
    _ailiaVoiceTest();
  }

  void _ailiaVoiceTest() async {
    await AiliaLicense.checkAndDownloadLicense();

    // Load image
    ByteData data = await rootBundle.load("assets/demo.wav");
    final wav = await Wav.read(data.buffer.asUint8List());

    print("Downloading model...");
    downloadModel(
        "https://storage.googleapis.com/ailia-models/tacotron2/encoder.onnx",
        "encoder.onnx", (encoderFile) {
      downloadModel(
          "https://storage.googleapis.com/ailia-models/tacotron2/decoder_iter.onnx",
          "decoder_iter.onnx", (decoderFile) {
        print("Download model success");
      downloadModel(
          "https://storage.googleapis.com/ailia-models/tacotron2/postnet.onnx",
          "postnet.onnx", (postnetFile) {
        print("Download model success");
      downloadModel(
          "https://storage.googleapis.com/ailia-models/tacotron2/waveglow.onnx",
          "waveglow.onnx", (waveglowFile) {
        print("Download model success");


    final dicFolder ="";// await ailiaCommonCopyFolderFromAssets("open_jtalk_dic_utf_8-1.11");

    _ailiaVoiceModel.open(
      encoderFile,
      decoderFile,
      postnetFile,
      waveglowFile,
      dicFolder,
    );
    String targetText = "Hello world.";

          final audio = _ailiaVoiceModel.textToSpeech(targetText);
      _speaker.play(audio);

        _ailiaVoiceModel.close();

        print("Sueccess");

        setState(() {
          _predictText = "finish";
        });
      });
      });
      });

    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_predictText\n'),
        ),
      ),
    );
  }
}
