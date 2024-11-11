#ifndef FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_
#define FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace lightstreamer_flutter_client {

class LightstreamerFlutterClientPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LightstreamerFlutterClientPlugin();

  virtual ~LightstreamerFlutterClientPlugin();

  // Disallow copy and assign.
  LightstreamerFlutterClientPlugin(const LightstreamerFlutterClientPlugin&) = delete;
  LightstreamerFlutterClientPlugin& operator=(const LightstreamerFlutterClientPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace lightstreamer_flutter_client

#endif  // FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_
