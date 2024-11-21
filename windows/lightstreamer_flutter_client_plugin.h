#ifndef FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_
#define FLUTTER_PLUGIN_LIGHTSTREAMER_FLUTTER_CLIENT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include "Lightstreamer/LightstreamerClient.h"

#include <memory>

namespace lightstreamer_flutter_client {

namespace LS = Lightstreamer;

class LightstreamerFlutterClientPlugin : public flutter::Plugin {
  /**
   * Maps a clientId (i.e. the `id` field of a MethodCall object) to a LightstreamerClient.
   * The mapping is created when any LightstreamerClient method is called by the Flutter component.
   * It is removed when the map is cleaned.
   */
  std::map<std::string, std::shared_ptr<LS::LightstreamerClient>> _clientMap;

  /**
   * Maps a subId (i.e. the `subId` field of a MethodCall object) to a Subscription.
   * The mapping is created when `LightstreamerClient.subscribe` is called.
   * It is removed when the map is cleaned.
   */
  std::map<std::string, std::shared_ptr<LS::Subscription>> _subMap;

  /**
   * The channel through which the events fired by the listeners are communicated to the Flutter component.
   */
  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> _listenerChannel;

  std::shared_ptr<LS::LightstreamerClient> getClient(const flutter::MethodCall<flutter::EncodableValue>& call);
  std::shared_ptr<LS::Subscription> getSubscription(const std::string& subId);
  void Client_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionDetails_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionOptions_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_setLoggerProvider(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_addCookies(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_getCookies(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_cleanResources(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_connect(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_disconnect(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_getStatus(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_subscribe(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_unsubscribe(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_getSubscriptions(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_sendMessage(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Details_setServerAddress(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionOptions_setForcedTransport(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionOptions_setRequestedMaxBandwidth(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionOptions_setReverseHeartbeatInterval(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LightstreamerFlutterClientPlugin(flutter::PluginRegistrarWindows* registrar);

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
