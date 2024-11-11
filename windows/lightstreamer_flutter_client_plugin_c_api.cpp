#include "include/lightstreamer_flutter_client/lightstreamer_flutter_client_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "lightstreamer_flutter_client_plugin.h"

void LightstreamerFlutterClientPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  lightstreamer_flutter_client::LightstreamerFlutterClientPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
