#include "include/ailia_voice/ailia_voice_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "ailia_voice_plugin.h"

void AiliaVoicePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  ailia_voice::AiliaVoicePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
