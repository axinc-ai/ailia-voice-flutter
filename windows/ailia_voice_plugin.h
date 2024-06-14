#ifndef FLUTTER_PLUGIN_AILIA_VOICE_PLUGIN_H_
#define FLUTTER_PLUGIN_AILIA_VOICE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace ailia_voice {

class AiliaVoicePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AiliaVoicePlugin();

  virtual ~AiliaVoicePlugin();

  // Disallow copy and assign.
  AiliaVoicePlugin(const AiliaVoicePlugin&) = delete;
  AiliaVoicePlugin& operator=(const AiliaVoicePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace ailia_voice

#endif  // FLUTTER_PLUGIN_AILIA_VOICE_PLUGIN_H_
