/*
 * Copyright (C) 2022 Lightstreamer Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
  std::shared_ptr<LS::Subscription> getSubscription(const std::string& subId) const;
  void Client_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionDetails_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void ConnectionOptions_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_setLoggerProvider(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_addCookies(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_getCookies(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_cleanResources(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Client_reset(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
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
  void Subscription_getCommandPosition(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getKeyPosition(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_setRequestedMaxFrequency(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_isActive(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_isSubscribed(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getValueByItemNameAndFieldName(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getValueByItemNameAndFieldPos(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getValueByItemPosAndFieldName(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getValueByItemPosAndFieldPos(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getCommandValueByItemNameAndFieldName(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getCommandValueByItemNameAndFieldPos(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getCommandValueByItemPosAndFieldName(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
  void Subscription_getCommandValueByItemPosAndFieldPos(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result);
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
