#include "lightstreamer_flutter_client_plugin.h"

#include "Lightstreamer\ClientListener.h"
#include "Lightstreamer\SubscriptionListener.h"
#include "Lightstreamer\ClientMessageListener.h"
#include "Lightstreamer\ItemUpdate.h"
#include "Lightstreamer\ConsoleLoggerProvider.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cassert>
#include <memory>
#include <sstream>

using flutter::EncodableValue;
using flutter::EncodableList;
using flutter::EncodableMap;
using MyChannel = flutter::MethodChannel<flutter::EncodableValue>;

/**
 * A plugin manages the communication between the Flutter component (the Flutter app targeting Windows using the Lightstreamer Flutter Client SDK)
 * and this Windows component (the environment running the Lightstreamer C++ Client SDK
 * that performs the operations requested by the Flutter component).
 * See also: https://docs.flutter.dev/platform-integration/platform-channels
 */
namespace lightstreamer_flutter_client {

  static LS::Logger* channelLogger;

  class MyClientListener : public LS::ClientListener {
    std::string clientId;
    std::shared_ptr<LS::LightstreamerClient> client;
    std::shared_ptr<MyChannel> plugin;
    void invoke(const std::string& method, flutter::EncodableMap& arguments);
  public:
    MyClientListener(const std::string& clientId, std::shared_ptr<LS::LightstreamerClient> client, std::shared_ptr<MyChannel> plugin) :
      clientId(clientId), client(client), plugin(plugin) {}
    ~MyClientListener() {}
    void onListenEnd() {}
    void onListenStart() {}
    void onServerError(int errorCode, const std::string& errorMessage);
    void onStatusChange(const std::string& status);
    void onPropertyChange(const std::string& property);
  };

  class MySubscriptionListener : public LS::SubscriptionListener {
    std::string _subId;
    std::shared_ptr<LS::Subscription> _sub;
    std::shared_ptr<MyChannel> _plugin;
    void invoke(const std::string& method, flutter::EncodableMap& arguments);
  public:
    MySubscriptionListener(const std::string& subId, std::shared_ptr<LS::Subscription> sub, std::shared_ptr<MyChannel> plugin) :
      _subId(subId), _sub(sub), _plugin(plugin) {}
    ~MySubscriptionListener() {}
    void onListenEnd() {}
    void onListenStart() {}
    void onClearSnapshot(const std::string& itemName, int itemPos);
    void onCommandSecondLevelItemLostUpdates(int lostUpdates, const std::string& key);
    void onCommandSecondLevelSubscriptionError(int code, const std::string& message, const std::string& key);
    void onEndOfSnapshot(const std::string& itemName, int itemPos);
    void onItemLostUpdates(const std::string& itemName, int itemPos, int lostUpdates);
    void onItemUpdate(LS::ItemUpdate& update);
    void onSubscription();
    void onSubscriptionError(int code, const std::string& message);
    void onUnsubscription();
    void onRealMaxFrequency(const std::string& frequency);
  };

  class MyClientMessageListener : public LS::ClientMessageListener {
    std::string _msgId;
    std::shared_ptr<MyChannel> _plugin;
    void invoke(const std::string& method, flutter::EncodableMap& arguments);
  public:
    MyClientMessageListener(const std::string& msgId, std::shared_ptr<MyChannel> plugin) 
      : _msgId(msgId), _plugin(plugin) {}
    ~MyClientMessageListener() {}
    void onAbort(const std::string& originalMessage, bool sentOnNetwork);
    void onDeny(const std::string& originalMessage, int code, const std::string& error);
    void onDiscarded(const std::string& originalMessage);
    void onError(const std::string& originalMessage);
    void onProcessed(const std::string& originalMessage, const std::string& response);
  };

  static inline flutter::EncodableMap getArguments(const flutter::MethodCall<flutter::EncodableValue>& call) {
    return std::get<EncodableMap>(*call.arguments());
  }

  static int32_t getInt(const flutter::EncodableMap& arguments, const char* key, int32_t orElse = -1) {
    EncodableValue val = arguments.at(EncodableValue(key));
    if (val.IsNull()) {
      return orElse;
    }
    assert(std::holds_alternative<int32_t>(val));
    return std::get<int32_t>(val);
  }

  /// null values are converted into empty strings
  static std::string getString(const flutter::EncodableMap& arguments, const char* key) {
    EncodableValue val = arguments.at(EncodableValue(key));
    if (val.IsNull()) {
      return "";
    }
    assert(std::holds_alternative<std::string>(val));
    return std::get<std::string>(val);
  }

  static bool getBool(const flutter::EncodableMap& arguments, const char* key, bool orElse = false) {
    EncodableValue val = arguments.at(EncodableValue(key));
    if (val.IsNull()) {
      return orElse;
    }
    assert(std::holds_alternative<bool>(val));
    return std::get<bool>(val);
  }

  /// null values are converted into empty maps
  static EncodableMap getMap(const flutter::EncodableMap& arguments, const char* key) {
    EncodableValue val = arguments.at(EncodableValue(key));
    if (val.IsNull()) {
      return EncodableMap();
    }
    assert(std::holds_alternative<EncodableMap>(val));
    return std::get<EncodableMap>(val);
  }

  /// null values are converted into empty lists
  static std::vector<std::string> getStringList(const flutter::EncodableMap& arguments, const char* key) {
    EncodableValue val = arguments.at(EncodableValue(key));
    if (val.IsNull()) {
      return std::vector<std::string>();
    }
    assert(std::holds_alternative<EncodableList>(val));
    EncodableList ls = std::get<EncodableList>(val);
    std::vector<std::string> ls_;
    for (auto& s : ls) {
      ls_.push_back(std::get<std::string>(s));
    }
    return ls_;
  }

  template <typename T>
  static inline T getValue(const std::map<std::string, T>& map, const std::string& key) {
    auto i = map.find(key);
    return i == map.end() ? nullptr : i->second;
  }

  // static
void LightstreamerFlutterClientPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {

   LS::LightstreamerClient::initialize([](const char* info) {
     std::cout << "Lightstreamer Internal Error - Cannot initialize the Flutter Plugin: " << info << std::endl;
     std::exit(1);
   });

  // TODO use LogManager
  auto loggerProvider = new LS::ConsoleLoggerProvider(LS::ConsoleLogLevel::Debug);
  channelLogger = loggerProvider->getLogger("lightstreamer.flutter");

  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.lightstreamer.flutter/methods",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LightstreamerFlutterClientPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LightstreamerFlutterClientPlugin::LightstreamerFlutterClientPlugin(flutter::PluginRegistrarWindows* registrar) 
  : _listenerChannel{ new flutter::MethodChannel<flutter::EncodableValue>(registrar->messenger(), "com.lightstreamer.flutter/listeners",
          &flutter::StandardMethodCodec::GetInstance()) } {}

LightstreamerFlutterClientPlugin::~LightstreamerFlutterClientPlugin() {}

void LightstreamerFlutterClientPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (channelLogger->isDebugEnabled()) {
    // TODO log arguments
    channelLogger->debug("Accepting " + call.method_name());
  }
  auto name = call.method_name();
  auto pos = name.find(".");
  // TODO check condition
  assert(pos != std::string::npos);
  auto className = name.substr(0, pos);
  auto methodName = name.substr(pos + 1);
  // TODO wrap in a try-catch
  if (className == "LightstreamerClient") {
    Client_handle(methodName, call, result);
  }
  else if (className == "ConnectionDetails") {
    // TODO ConnectionDetails_handle(methodName, call, result);
  }
  else if (className == "ConnectionOptions") {
    // TODO ConnectionOptions_handle(methodName, call, result);
  }
  else if (className == "Subscription") {
    // TODO Subscription_handle(methodName, call, result);
  }
  else {
    if (channelLogger->isErrorEnabled()) {
      channelLogger->error("Unknown method " + call.method_name());
    }
    result->NotImplemented();
  }
}

std::shared_ptr<LS::LightstreamerClient> LightstreamerFlutterClientPlugin::getClient(const flutter::MethodCall<flutter::EncodableValue>& call) {
  auto arguments = getArguments(call);
  auto id = getString(arguments, "id");
  auto ls = getValue(_clientMap, id);
  if (ls == nullptr) {
    ls = std::make_shared<LS::LightstreamerClient>("", "");
    _clientMap.insert({ id, ls });
    ls->addListener(new MyClientListener(id, ls, _listenerChannel));
  }
  return ls;
}

std::shared_ptr<LS::Subscription> LightstreamerFlutterClientPlugin::getSubscription(const std::string& subId) {
  auto sub = getValue(_subMap, subId);
  if (sub == nullptr) {
    auto errMsg = "Subscription " + subId + " doesn't exist";
    if (channelLogger->isErrorEnabled()) {
      channelLogger->error(errMsg);
    }
    // TODO throw IllegalStateException
    //throw new IllegalStateException(errMsg);
    throw "IllegalStateException: " + errMsg;
  }
  return sub;
}

static void invokeMethod(std::shared_ptr<MyChannel> channel, const std::string& method, flutter::EncodableMap& arguments) {
  if (channelLogger->isDebugEnabled()) {
    // TODO print arguments
    channelLogger->debug("Invoking " + method);
  }
  auto val = std::make_unique<flutter::EncodableValue>(arguments);
  // TODO call on the platform thread
  channel->InvokeMethod(method, std::move(val));
}

void LightstreamerFlutterClientPlugin::Client_handle(std::string& method, const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  if (method == "connect")
  {
    Client_connect(call, result);
  }
  else if (method == "disconnect")
  {
    Client_disconnect(call, result);
  }
  else if (method == "getStatus")
  {
    Client_getStatus(call, result);
  }
  else if (method == "subscribe")
  {
    Client_subscribe(call, result);
  }
  else if (method == "unsubscribe")
  {
    Client_unsubscribe(call, result);
  }
  else if (method == "getSubscriptions")
  {
    Client_getSubscriptions(call, result);
  }
  else if (method == "sendMessage")
  {
    Client_sendMessage(call, result);
  }
  else if (method == "setLoggerProvider")
  {
    Client_setLoggerProvider(call, result);
  }
  else if (method == "addCookies")
  {
    // TODO Client_addCookies(call, result);
  }
  else if (method == "getCookies")
  {
    // TODO Client_getCookies(call, result);
  }
  else if (method == "cleanResources")
  {
    Client_cleanResources(call, result);
  }
  else
  {
    if (channelLogger->isErrorEnabled())
    {
      channelLogger->error("Unknown method " + call.method_name());
    }
    result->NotImplemented();
  }
}

void LightstreamerFlutterClientPlugin::Client_setLoggerProvider(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto arguments = getArguments(call);
  auto level = getInt(arguments, "level");
  LS::ConsoleLogLevel level_;
  switch (level) {
  case  0: 
    level_ = LS::ConsoleLogLevel::Trace;
    break;
  case 10: 
    level_ = LS::ConsoleLogLevel::Debug;
    break;
  case 20: 
    level_ = LS::ConsoleLogLevel::Info;
    break;
  case 30: 
    level_ = LS::ConsoleLogLevel::Warn;
    break;
  case 40: 
    level_ = LS::ConsoleLogLevel::Error;
    break;
  case 50: 
    level_ = LS::ConsoleLogLevel::Fatal;
    break;
  default: 
    level_ = LS::ConsoleLogLevel::Error;
  }
  // TODO memory leak
  LS::LightstreamerClient::setLoggerProvider(new LS::ConsoleLoggerProvider(level_));
  result->Success();
}

void LightstreamerFlutterClientPlugin::Client_cleanResources(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  // TODO Client_cleanResources
  result->Success();
}

void LightstreamerFlutterClientPlugin::Client_connect(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto arguments = getArguments(call);
  auto client = getClient(call);
  auto details = getMap(arguments, "connectionDetails");
  client->connectionDetails.setAdapterSet(getString(details, "adapterSet"));
  client->connectionDetails.setServerAddress(getString(details, "serverAddress"));
  client->connectionDetails.setUser(getString(details, "user"));
  client->connectionDetails.setPassword(getString(details, "password"));
  auto options = getMap(arguments, "connectionOptions");
  client->connectionOptions.setContentLength(getInt(options, "contentLength"));
  client->connectionOptions.setFirstRetryMaxDelay(getInt(options, "firstRetryMaxDelay"));
  client->connectionOptions.setForcedTransport(getString(options, "forcedTransport"));
  // TODO httpExtraHeaders
  //client->connectionOptions.setHttpExtraHeaders((Map<String, String>) options.get("httpExtraHeaders"));
  client->connectionOptions.setIdleTimeout(getInt(options, "idleTimeout"));
  client->connectionOptions.setKeepaliveInterval(getInt(options, "keepaliveInterval"));
  client->connectionOptions.setPollingInterval(getInt(options, "pollingInterval"));
  client->connectionOptions.setReconnectTimeout(getInt(options, "reconnectTimeout"));
  client->connectionOptions.setRequestedMaxBandwidth(getString(options, "requestedMaxBandwidth"));
  client->connectionOptions.setRetryDelay(getInt(options, "retryDelay"));
  client->connectionOptions.setReverseHeartbeatInterval(getInt(options, "reverseHeartbeatInterval"));
  client->connectionOptions.setSessionRecoveryTimeout(getInt(options, "sessionRecoveryTimeout"));
  client->connectionOptions.setStalledTimeout(getInt(options, "stalledTimeout"));
  client->connectionOptions.setHttpExtraHeadersOnSessionCreationOnly(getBool(options, "httpExtraHeadersOnSessionCreationOnly"));
  client->connectionOptions.setServerInstanceAddressIgnored(getBool(options, "serverInstanceAddressIgnored"));
  client->connectionOptions.setSlowingEnabled(getBool(options, "slowingEnabled"));
  client->connect();
  result->Success();
}

void LightstreamerFlutterClientPlugin::Client_disconnect(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto client = getClient(call);
  client->disconnect();
  result->Success();
}

void LightstreamerFlutterClientPlugin::Client_getStatus(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto client = getClient(call);
  auto res = client->getStatus();
  result->Success(flutter::EncodableValue(res));
}

void LightstreamerFlutterClientPlugin::Client_subscribe(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto arguments = getArguments(call);
  auto client = getClient(call);
  auto options = getMap(arguments, "subscription");
  auto subId = getString(options, "id");
  auto mode = getString(options, "mode");
  auto items = getStringList(options, "items");
  auto fields = getStringList(options, "fields");
  auto group = getString(options, "group");
  auto schema = getString(options, "schema");
  auto dataAdapter = getString(options, "dataAdapter");
  auto bufferSize = getString(options, "bufferSize");
  auto snapshot = getString(options, "snapshot");
  auto requestedMaxFrequency = getString(options, "requestedMaxFrequency");
  auto selector = getString(options, "selector");
  auto dataAdapter2 = getString(options, "dataAdapter2");
  auto fields2 = getStringList(options, "fields2");
  auto schema2 = getString(options, "schema2");
  auto sub = getValue(_subMap, subId);
  if (sub == nullptr) {
    sub = std::make_shared<LS::Subscription>(mode, std::vector<std::string>(), std::vector<std::string>());
    sub->addListener(new MySubscriptionListener(subId, sub, _listenerChannel));
    _subMap.insert({ subId, sub });
  }
  if (sub->isActive()) {
    // TODO throw IllegalStateException
    //throw new IllegalStateException("Cannot subscribe to an active Subscription");
    throw "IllegalStateException: Cannot subscribe to an active Subscription";
  }
  if (!items.empty()) {
    sub->setItems(items);
  }
  if (!fields.empty()) {
    sub->setFields(fields);
  }
  if (!group.empty()) {
    sub->setItemGroup(group);
  }
  if (!schema.empty()) {
    sub->setFieldSchema(schema);
  }
  if (!dataAdapter.empty()) {
    sub->setDataAdapter(dataAdapter);
  }
  if (!bufferSize.empty()) {
    sub->setRequestedBufferSize(bufferSize);
  }
  if (!snapshot.empty()) {
    sub->setRequestedSnapshot(snapshot);
  }
  if (!requestedMaxFrequency.empty()) {
    sub->setRequestedMaxFrequency(requestedMaxFrequency);
  }
  if (!selector.empty()) {
    sub->setSelector(selector);
  }
  if (!dataAdapter2.empty()) {
    sub->setCommandSecondLevelDataAdapter(dataAdapter2);
  }
  if (!fields2.empty()) {
    sub->setCommandSecondLevelFields(fields2);
  }
  if (!schema2.empty()) {
    sub->setCommandSecondLevelFieldSchema(schema2);
  }
  // TODO memory leak?
  client->subscribe(sub.get());
  result->Success();
}

void LightstreamerFlutterClientPlugin::Client_unsubscribe(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto arguments = getArguments(call);
  auto client = getClient(call);
  auto subId = getString(arguments, "subId");
  auto sub = getSubscription(subId);
  // TODO memory leak?
  client->unsubscribe(sub.get());
  result->Success();
}

void LightstreamerFlutterClientPlugin::Client_getSubscriptions(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto client = getClient(call);
  std::vector<LS::Subscription*> subs = client->getSubscriptions();
  EncodableList res;
  for (auto& e : _subMap) {
    if (std::find(subs.begin(), subs.end(), e.second.get()) != subs.end()) {
      res.push_back(EncodableValue(e.first));
    }
  }
  result->Success(res);
}

void LightstreamerFlutterClientPlugin::Client_sendMessage(const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>& result) {
  auto arguments = getArguments(call);
  auto client = getClient(call);
  auto msgId = getString(arguments, "msgId");
  auto message = getString(arguments, "message");
  auto sequence = getString(arguments, "sequence");
  int delayTimeout = getInt(arguments, "delayTimeout", -1);
  bool enqueueWhileDisconnected = getBool(arguments, "enqueueWhileDisconnected", false);
  MyClientMessageListener* listener = nullptr;
  if (!msgId.empty()) {
    listener = new MyClientMessageListener(msgId, _listenerChannel);
  }
  client->sendMessage(message, sequence, delayTimeout, listener, enqueueWhileDisconnected);
  result->Success();
}

void MyClientListener::onServerError(int errorCode, const std::string& errorMessage) {
  EncodableMap arguments{
    { EncodableValue("errorCode"), EncodableValue(errorCode) },
    { EncodableValue("errorMessage"), EncodableValue(errorMessage) },
  };
  invoke("onServerError", arguments);
}

void MyClientListener::onStatusChange(const std::string& status) {
  EncodableMap arguments{
      { EncodableValue("status"), EncodableValue(status) },
  };
  invoke("onStatusChange", arguments);
}

void MyClientListener::onPropertyChange(const std::string& property) {
  EncodableMap arguments{
      { EncodableValue("property"), EncodableValue(property) },
  };
  if (property == "serverInstanceAddress") {
    arguments.insert({ "value", client->connectionDetails.getServerInstanceAddress() });
  }
  else if (property == "serverSocketName") {
    arguments.insert({ "value", client->connectionDetails.getServerSocketName() });
  }
  else if (property == "clientIp") {
    arguments.insert({ "value", client->connectionDetails.getClientIp() });
  }
  else if (property == "sessionId") {
    arguments.insert({ "value", client->connectionDetails.getSessionId() });
  }
  else if (property == "realMaxBandwidth") {
    arguments.insert({ "value", client->connectionOptions.getRealMaxBandwidth() });
  }
  else if (property == "idleTimeout") {
    arguments.insert({ "value", client->connectionOptions.getIdleTimeout() });
  }
  else if (property == "keepaliveInterval") {
    arguments.insert({ "value", client->connectionOptions.getKeepaliveInterval() });
  }
  else if (property == "pollingInterval") {
    arguments.insert({ "value", client->connectionOptions.getPollingInterval() });
  }
  invoke("onPropertyChange", arguments);
}

void MyClientListener::invoke(const std::string& method, EncodableMap& arguments) {
  arguments.insert({ EncodableValue("id"), EncodableValue(clientId) });
  invokeMethod(plugin, "ClientListener." + method, arguments);
}

void MySubscriptionListener::onClearSnapshot(const std::string& itemName, int itemPos) {
  EncodableMap arguments{
    { EncodableValue("itemName"), EncodableValue(itemName) },
    { EncodableValue("itemPos"), EncodableValue(itemPos) },
  };
  invoke("onClearSnapshot", arguments);
}

void MySubscriptionListener::onCommandSecondLevelItemLostUpdates(int lostUpdates, const std::string& key) {
  EncodableMap arguments{
    { EncodableValue("lostUpdates"), EncodableValue(lostUpdates) },
    { EncodableValue("key"), EncodableValue(key) },
  };
  invoke("onCommandSecondLevelItemLostUpdates", arguments);
}

void MySubscriptionListener::onCommandSecondLevelSubscriptionError(int code, const std::string& message, const std::string& key) {
  EncodableMap arguments{
    { EncodableValue("code"), EncodableValue(code) },
    { EncodableValue("message"), EncodableValue(message) },
    { EncodableValue("key"), EncodableValue(key) },
  };
  invoke("onCommandSecondLevelSubscriptionError", arguments);
}

void MySubscriptionListener::onEndOfSnapshot(const std::string& itemName, int itemPos) {
  EncodableMap arguments{
    { EncodableValue("itemName"), EncodableValue(itemName) },
    { EncodableValue("itemPos"), EncodableValue(itemPos) },
  };
  invoke("onEndOfSnapshot", arguments);
}

void MySubscriptionListener::onItemLostUpdates(const std::string& itemName, int itemPos, int lostUpdates) {
  EncodableMap arguments{
    { EncodableValue("itemName"), EncodableValue(itemName) },
    { EncodableValue("itemPos"), EncodableValue(itemPos) },
    { EncodableValue("lostUpdates"), EncodableValue(lostUpdates) },
  };
  invoke("onItemLostUpdates", arguments);
}

void MySubscriptionListener::onItemUpdate(LS::ItemUpdate& update) {
  EncodableMap arguments{
    { EncodableValue("itemName"), EncodableValue(update.getItemName()) },
    { EncodableValue("itemPos"), EncodableValue(update.getItemPos()) },
    { EncodableValue("isSnapshot"), EncodableValue(update.isSnapshot()) },
  };
  if (!_sub->getFields().empty() || !_sub->getCommandSecondLevelFields().empty()) {
    try {
      auto changedFields = update.getChangedFields();
      auto fields = update.getFields();

      EncodableMap changedFields_;
      for (auto p : changedFields) {
        changedFields_.insert({ EncodableValue(p.first), EncodableValue(p.second) });
      }
      EncodableMap fields_;
      for (auto p : fields) {
        fields_.insert({ EncodableValue(p.first), EncodableValue(p.second) });
      }

      arguments.insert({ EncodableValue("changedFields"), EncodableValue(changedFields_) });
      arguments.insert({ EncodableValue("fields"), EncodableValue(fields_) });
      // NB json fields are not supported by the C++ client library
      arguments.insert({ EncodableValue("jsonFields"), EncodableValue(EncodableMap()) });
    }
    catch(...) {
      // if the subscription doesn't have field names, the methods getChangedFields and
      // getFields may throw exceptions
    }
  }
  auto changedFieldsByPosition = update.getChangedFieldsByPosition();
  auto fieldsByPosition = update.getFieldsByPosition();

  EncodableMap changedFieldsByPosition_;
  for (auto p : changedFieldsByPosition) {
    changedFieldsByPosition_.insert({ EncodableValue(p.first), EncodableValue(p.second) });
  }
  EncodableMap fieldsByPosition_;
  for (auto p : fieldsByPosition) {
    fieldsByPosition_.insert({ EncodableValue(p.first), EncodableValue(p.second) });
  }

  arguments.insert({ EncodableValue("changedFieldsByPosition"), EncodableValue(changedFieldsByPosition_) });
  arguments.insert({ EncodableValue("fieldsByPosition"), EncodableValue(fieldsByPosition_) });
  // NB json fields are not supported by the C++ client library
  arguments.insert({ EncodableValue("jsonFieldsByPosition"), EncodableValue(EncodableMap()) });
  invoke("onItemUpdate", arguments);
}

void MySubscriptionListener::onSubscription() {
  EncodableMap arguments{};
  if ("COMMAND" == _sub->getMode()) {
    arguments.insert({ EncodableValue("commandPosition"), EncodableValue(_sub->getCommandPosition()) });
    arguments.insert({ EncodableValue("keyPosition"), EncodableValue(_sub->getKeyPosition()) });
  }
  invoke("onSubscription", arguments);
}

void MySubscriptionListener::onSubscriptionError(int code, const std::string& message) {
  EncodableMap arguments{
    { EncodableValue("errorCode"), EncodableValue(code) },
    { EncodableValue("errorMessage"), EncodableValue(message) },
  };
  invoke("onSubscriptionError", arguments);
}

void MySubscriptionListener::onUnsubscription() {
  EncodableMap arguments{};
  invoke("onUnsubscription", arguments);
}

void MySubscriptionListener::onRealMaxFrequency(const std::string& frequency) {
  EncodableMap arguments{
    { EncodableValue("frequency"), EncodableValue(frequency) },
  };
  invoke("onRealMaxFrequency", arguments);
}

void MySubscriptionListener::invoke(const std::string& method, EncodableMap& arguments) {
  arguments.insert({ EncodableValue("subId"), EncodableValue(_subId) });
  invokeMethod(_plugin, "SubscriptionListener." + method, arguments);
}

void MyClientMessageListener::onAbort(const std::string& originalMessage, bool sentOnNetwork) {
  EncodableMap arguments{
    { EncodableValue("originalMessage"), EncodableValue(originalMessage) },
    { EncodableValue("sentOnNetwork"), EncodableValue(sentOnNetwork) },
  };
  invoke("onAbort", arguments);
}

void MyClientMessageListener::onDeny(const std::string& originalMessage, int errorCode, const std::string& errorMessage) {
  EncodableMap arguments{
    { EncodableValue("originalMessage"), EncodableValue(originalMessage) },
    { EncodableValue("errorCode"), EncodableValue(errorCode) },
    { EncodableValue("errorMessage"), EncodableValue(errorMessage) },
  };
  invoke("onDeny", arguments);
}

void MyClientMessageListener::onDiscarded(const std::string& originalMessage) {
  EncodableMap arguments{
    { EncodableValue("originalMessage"), EncodableValue(originalMessage) },
  };
  invoke("onDiscarded", arguments);
}

void MyClientMessageListener::onError(const std::string& originalMessage) {
  EncodableMap arguments{
    { EncodableValue("originalMessage"), EncodableValue(originalMessage) },
  };
  invoke("onError", arguments);
}

void MyClientMessageListener::onProcessed(const std::string& originalMessage, const std::string& response) {
  EncodableMap arguments{
    { EncodableValue("originalMessage"), EncodableValue(originalMessage) },
    { EncodableValue("response"), EncodableValue(response) },
  };
  invoke("onProcessed", arguments);
}

void MyClientMessageListener::invoke(const std::string& method, EncodableMap& arguments) {
  arguments.insert({ EncodableValue("msgId"), EncodableValue(_msgId) });
  invokeMethod(_plugin, "ClientMessageListener." + method, arguments);
}

}  // namespace lightstreamer_flutter_client
