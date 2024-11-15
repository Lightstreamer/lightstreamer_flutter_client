#include "lightstreamer_flutter_client_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include "Lightstreamer\LightstreamerClient.h"
#include "Lightstreamer\ConsoleLoggerProvider.h"
#include "Lightstreamer\Subscription.h"

#include <cassert>
#include <memory>
#include <sstream>

using std::string;
using std::vector;
using std::unique_ptr;
using flutter::MethodCall;
using flutter::MethodResult;
using flutter::EncodableValue;
using flutter::EncodableList;
using flutter::EncodableMap;

/**
 * A plugin manages the communication between the Flutter component (the Flutter app targeting Windows using the Lightstreamer Flutter Client SDK)
 * and this Windows component (the environment running the Lightstreamer C++ Client SDK
 * that performs the operations requested by the Flutter component).
 * See also: https://docs.flutter.dev/platform-integration/platform-channels
 */
namespace lightstreamer_flutter_client {

  static LS::Logger* channelLogger;

  static void Client_handle(string& method, const MethodCall<EncodableValue>& call, unique_ptr<MethodResult<EncodableValue>>& result);
  static void Client_setLoggerProvider(const MethodCall<EncodableValue>& call, unique_ptr<MethodResult<EncodableValue>>& result);
  static void Client_connect(const MethodCall<EncodableValue>& call, unique_ptr<MethodResult<EncodableValue>>& result);

  static inline EncodableMap getArguments(const MethodCall<EncodableValue>& call) {
    return std::get<EncodableMap>(*call.arguments());
  }

  template <typename T>
  static T getArg(const EncodableMap& arguments, const char* key) {
    EncodableValue val = arguments.at(EncodableValue(key));
    assert(std::holds_alternative<T>(val));
    return std::get<T>(val);
  }

  static inline int32_t getInt(const EncodableMap& arguments, const char* key) {
    return getArg<int32_t>(arguments, key);
  }

  static inline string getString(const EncodableMap& arguments, const char* key) {
    return getArg<string>(arguments, key);
  }

  template <typename T>
  static inline T* getValue(const std::map<string, T*>& map, const string& key) {
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

  auto plugin = std::make_unique<LightstreamerFlutterClientPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LightstreamerFlutterClientPlugin::LightstreamerFlutterClientPlugin() {}

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
  if (className == "LightstreamerClient") {
    Client_handle(methodName, call, result);
  }
  else {
    if (channelLogger->isErrorEnabled()) {
      channelLogger->error("Unknown method " + call.method_name());
    }
    result->NotImplemented();
  }
  /*if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else {
    result->NotImplemented();
  }*/
}

LS::LightstreamerClient& LightstreamerFlutterClientPlugin::getClient(const flutter::MethodCall<flutter::EncodableValue>& call) {
  /*String id = call.argument("id");
  LightstreamerClient ls = _clientMap.get(id);
  if (ls == null) {
    ls = new LightstreamerClient(null, null);
    _clientMap.put(id, ls);
    ls.addListener(new MyClientListener(id, ls, this));
  }
  return ls;*/
  auto arguments = getArguments(call);
  auto id = getString(arguments, "id");
  auto ls = getValue(_clientMap, id);
  if (ls == nullptr) {
    ls = new LS::LightstreamerClient("", "");
    _clientMap.insert({ id, ls });
    // TODO ...
  }
  return *ls;
}

static void Client_handle(string& method, const MethodCall<EncodableValue>& call, unique_ptr<MethodResult<EncodableValue>>& result) {
  // TODO complete
  if (method == "connect")
  {
    Client_connect(call, result);
  }
  /*else if (method == "disconnect")
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
  }*/
  else if (method == "setLoggerProvider")
  {
    Client_setLoggerProvider(call, result);
  }
  /*else if (method == "addCookies")
  {
    Client_addCookies(call, result);
  }
  else if (method == "getCookies")
  {
    Client_getCookies(call, result);
  }
  else if (method == "cleanResources")
  {
    Client_cleanResources(call, result);
  }*/
  else
  {
    if (channelLogger->isErrorEnabled())
    {
      channelLogger->error("Unknown method " + call.method_name());
    }
    result->NotImplemented();
  }
}

static void Client_setLoggerProvider(const MethodCall<EncodableValue>& call, unique_ptr<MethodResult<EncodableValue>>& result) {
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

static void Client_connect(const MethodCall<EncodableValue>& call, unique_ptr<MethodResult<EncodableValue>>& result) {
 /* LightstreamerClient client = getClient(call);
  Map<String, Object> details = call.argument("connectionDetails");
  client.connectionDetails.setAdapterSet((String)details.get("adapterSet"));
  client.connectionDetails.setServerAddress((String)details.get("serverAddress"));
  client.connectionDetails.setUser((String)details.get("user"));
  client.connectionDetails.setPassword((String)details.get("password"));
  Map<String, Object> options = call.argument("connectionOptions");
  client.connectionOptions.setContentLength((int)options.get("contentLength"));
  client.connectionOptions.setFirstRetryMaxDelay((int)options.get("firstRetryMaxDelay"));
  client.connectionOptions.setForcedTransport((String)options.get("forcedTransport"));
  client.connectionOptions.setHttpExtraHeaders((Map<String, String>) options.get("httpExtraHeaders"));
  client.connectionOptions.setIdleTimeout((int)options.get("idleTimeout"));
  client.connectionOptions.setKeepaliveInterval((int)options.get("keepaliveInterval"));
  client.connectionOptions.setPollingInterval((int)options.get("pollingInterval"));
  client.connectionOptions.setReconnectTimeout((int)options.get("reconnectTimeout"));
  client.connectionOptions.setRequestedMaxBandwidth((String)options.get("requestedMaxBandwidth"));
  client.connectionOptions.setRetryDelay((int)options.get("retryDelay"));
  client.connectionOptions.setReverseHeartbeatInterval((int)options.get("reverseHeartbeatInterval"));
  client.connectionOptions.setSessionRecoveryTimeout((int)options.get("sessionRecoveryTimeout"));
  client.connectionOptions.setStalledTimeout((int)options.get("stalledTimeout"));
  client.connectionOptions.setHttpExtraHeadersOnSessionCreationOnly((boolean)options.get("httpExtraHeadersOnSessionCreationOnly"));
  client.connectionOptions.setServerInstanceAddressIgnored((boolean)options.get("serverInstanceAddressIgnored"));
  client.connectionOptions.setSlowingEnabled((boolean)options.get("slowingEnabled"));
  client.connect();
  result.success(null);*/
}

}  // namespace lightstreamer_flutter_client
