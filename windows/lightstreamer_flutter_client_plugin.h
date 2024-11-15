#ifndef FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_
#define FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include "Lightstreamer/LightstreamerClient.h"
#include "Lightstreamer/Logger.h"

#include <memory>

namespace lightstreamer_flutter_client {

namespace LS = Lightstreamer;

class LightstreamerFlutterClientPlugin : public flutter::Plugin {
  /**
   * Maps a clientId (i.e. the `id` field of a MethodCall object) to a LightstreamerClient.
   * The mapping is created when any LightstreamerClient method is called by the Flutter component.
   * It is removed when the map is cleaned.
   */
  std::map<std::string, LS::LightstreamerClient*> _clientMap;
  LS::LightstreamerClient& getClient(const flutter::MethodCall<flutter::EncodableValue>& call);
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
