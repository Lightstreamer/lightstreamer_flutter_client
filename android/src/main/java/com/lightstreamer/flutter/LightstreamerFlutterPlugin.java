package com.lightstreamer.flutter;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.lightstreamer.client.ClientListener;
import com.lightstreamer.client.ItemUpdate;
import com.lightstreamer.client.LightstreamerClient;
import com.lightstreamer.client.Subscription;
import com.lightstreamer.client.SubscriptionListener;
import com.lightstreamer.log.ConsoleLogLevel;
import com.lightstreamer.log.ConsoleLoggerProvider;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class LightstreamerFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    static final String TAG = "LightstreamerClient";

    // WARNING: Potential memory leak. Clients are added to the map but not removed.
    final Map<String, LightstreamerClient> _clientMap = new HashMap<>();
    final Map<String, Subscription> _subMap = new HashMap<>();
    MethodChannel _methodChannel;
    MethodChannel _listenerChannel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        // TODO disable the logger
        LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

        _methodChannel = new MethodChannel(binding.getBinaryMessenger(), "com.lightstreamer.flutter/methods");
        _methodChannel.setMethodCallHandler(this);
        _listenerChannel = new MethodChannel(binding.getBinaryMessenger(), "com.lightstreamer.flutter/listeners");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        _methodChannel.setMethodCallHandler(null);
    }

//    final Map<String> _methods = Map.ofEntries(
//            "LightstreamerClient.create", create,
//            "LightstreamerClient.connect", connect
//            "LightstreamerClient.disconnect",
//            "ConnectionDetails.getAdapterSet",
//            "ConnectionDetails.setAdapterSet",
//            "ConnectionDetails.getServerAddress",
//            "ConnectionDetails.setServerAddress"
//    );

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        logMethod(call);
        switch (call.method) {
            case "LightstreamerClient.create":
                create(call, result);
                break;
            case "LightstreamerClient.connect":
                connect(call, result);
                break;
            case "LightstreamerClient.disconnect":
                disconnect(call, result);
                break;
            case "LightstreamerClient.getStatus":
                getStatus(call, result);
                break;
            case "LightstreamerClient.subscribe":
                subscribe(call, result);
                break;
            case "LightstreamerClient.unsubscribe":
                unsubscribe(call, result);
                break;
            case "LightstreamerClient.getSubscriptions":
                getSubscriptions(call, result);
                break;
            case "ConnectionDetails.getServerInstanceAddress":
                Details_getServerInstanceAddress(call, result);
                break;
            case "ConnectionDetails.getServerSocketName":
                Details_getServerSocketName(call, result);
                break;
            case "ConnectionDetails.getClientIp":
                Details_getClientIp(call, result);
                break;
            case "ConnectionDetails.getSessionId":
                Details_getSessionId(call, result);
                break;
            case "ConnectionOptions.getRealMaxBandwidth":
                ConnectionOptions_getRealMaxBandwidth(call, result);
                break;
            default:
                Log.e(TAG, "Unknown method " + call.method);
                result.notImplemented();
        }
    }

    void create(MethodCall call, MethodChannel.Result result) {
        // TODO check that id is not in the map yet
        LightstreamerClient client = getClient(call);
        String serverAddress = call.argument("serverAddress");
        String adapterSet = call.argument("adapterSet");
        // TODO better to pass them to the ctor
        client.connectionDetails.setServerAddress(serverAddress);
        client.connectionDetails.setAdapterSet(adapterSet);
        String id = call.argument("id");
        client.addListener(new MyClientListener(id, this));
        result.success(null);
    }

    void connect(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        Map<String, Object> details = call.argument("connectionDetails");
        client.connectionDetails.setAdapterSet((String) details.get("adapterSet"));
        client.connectionDetails.setServerAddress((String) details.get("serverAddress"));
        client.connectionDetails.setUser((String) details.get("user"));
        client.connectionDetails.setPassword((String) details.get("password"));
        Map<String, Object> options = call.argument("connectionOptions");
        client.connectionOptions.setContentLength((int) options.get("contentLength"));
        client.connectionOptions.setFirstRetryMaxDelay((int) options.get("firstRetryMaxDelay"));
        client.connectionOptions.setForcedTransport((String) options.get("forcedTransport"));
        client.connectionOptions.setHttpExtraHeaders((Map<String, String>) options.get("httpExtraHeaders"));
        client.connectionOptions.setIdleTimeout((int) options.get("idleTimeout"));
        client.connectionOptions.setKeepaliveInterval((int) options.get("keepaliveInterval"));
        client.connectionOptions.setPollingInterval((int) options.get("pollingInterval"));
        client.connectionOptions.setReconnectTimeout((int) options.get("reconnectTimeout"));
        client.connectionOptions.setRequestedMaxBandwidth((String) options.get("requestedMaxBandwidth"));
        client.connectionOptions.setRetryDelay((int) options.get("retryDelay"));
        client.connectionOptions.setReverseHeartbeatInterval((int) options.get("reverseHeartbeatInterval"));
        client.connectionOptions.setSessionRecoveryTimeout((int) options.get("sessionRecoveryTimeout"));
        client.connectionOptions.setStalledTimeout((int) options.get("stalledTimeout"));
        client.connectionOptions.setHttpExtraHeadersOnSessionCreationOnly((boolean) options.get("httpExtraHeadersOnSessionCreationOnly"));
        client.connectionOptions.setServerInstanceAddressIgnored((boolean) options.get("serverInstanceAddressIgnored"));
        client.connectionOptions.setSlowingEnabled((boolean) options.get("slowingEnabled"));
        client.connect();
        result.success(null);
    }

    void disconnect(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        client.disconnect();
        result.success(null);
    }

    void getStatus(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.getStatus();
        result.success(res);
    }

    void subscribe(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        Map<String, Object> options = call.argument("subscription");
        String subId = (String) options.get("id");
        List<String> items = (List<String>) options.get("items");
        List<String> fields = (List<String>) options.get("fields");
        String group = (String) options.get("group");
        String schema = (String) options.get("schema");
        String dataAdapter = (String) options.get("dataAdapter");
        String bufferSize = (String) options.get("bufferSize");
        String snapshot = (String) options.get("snapshot");
        String requestedMaxFrequency = (String) options.get("requestedMaxFrequency");
        String selector = (String) options.get("selector");
        String dataAdapter2 = (String) options.get("dataAdapter2");
        List<String> fields2 = (List<String>) options.get("fields2");
        String schema2 = (String) options.get("schema2");
        Subscription sub = new Subscription((String) options.get("mode"));
        // TODO what if already in _subMap?
        _subMap.put(subId, sub);
        if (items != null) {
            sub.setItems(items.toArray(new String[0]));
        }
        if (fields != null) {
            sub.setFields(fields.toArray(new String[0]));
        }
        if (group != null) {
            sub.setItemGroup(group);
        }
        if (schema != null) {
            sub.setFieldSchema(schema);
        }
        if (dataAdapter != null) {
            sub.setDataAdapter(dataAdapter);
        }
        if (bufferSize != null) {
            sub.setRequestedBufferSize(bufferSize);
        }
        if (snapshot != null) {
            sub.setRequestedSnapshot(snapshot);
        }
        if (requestedMaxFrequency != null) {
            sub.setRequestedMaxFrequency(requestedMaxFrequency);
        }
        if (selector != null) {
            sub.setSelector(selector);
        }
        if (dataAdapter2 != null) {
            sub.setCommandSecondLevelDataAdapter(dataAdapter2);
        }
        if (fields2 != null) {
            sub.setCommandSecondLevelFields(fields2.toArray(new String[0]));
        }
        if (schema2 != null) {
            sub.setCommandSecondLevelFieldSchema(schema2);
        }
        sub.addListener(new MySubscriptionListener(subId, sub, this));
        client.subscribe(sub);
        result.success(null);
    }

    void unsubscribe(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String subId = call.argument("subId");
        Subscription sub = _subMap.get(subId);
        _subMap.remove(subId);
        // TODO what if null?
        client.unsubscribe(sub);
        result.success(null);
    }

    void getSubscriptions(MethodCall call, MethodChannel.Result result) {
        // TODO improve performance
        LightstreamerClient client = getClient(call);
        List<Subscription> subs = client.getSubscriptions();
        List<String> res = new ArrayList<>();
        for (Map.Entry<String, Subscription> e : _subMap.entrySet()) {
            if (subs.contains(e.getValue())) {
                res.add(e.getKey());
            }
        }
        result.success(res);
    }

    void Details_getServerInstanceAddress(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.connectionDetails.getServerInstanceAddress();
        result.success(res);
    }

    void Details_getServerSocketName(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.connectionDetails.getServerSocketName();
        result.success(res);
    }

    void Details_getClientIp(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.connectionDetails.getClientIp();
        result.success(res);
    }

    void Details_getSessionId(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.connectionDetails.getSessionId();
        result.success(res);
    }

    void ConnectionOptions_getRealMaxBandwidth(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.connectionOptions.getRealMaxBandwidth();
        result.success(res);
    }

    LightstreamerClient getClient(MethodCall call) {
        String id = call.argument("id");
        LightstreamerClient ls = _clientMap.get(id);
        // TODO what if null and called by a method other than create?
        if (ls == null) {
            ls = new LightstreamerClient(null, null);
            _clientMap.put(id, ls);
        }
        return ls;
    }

    void logMethod(MethodCall call) {
        Log.i(TAG, "event on channel com.lightstreamer.flutter/methods: " + call.method + " " + call.arguments().toString());
    }
}

class MyClientListener implements ClientListener {
    final String clientId;
    final LightstreamerFlutterPlugin plugin;
    final Handler loop = new Handler(Looper.getMainLooper());

    MyClientListener(String clientId, LightstreamerFlutterPlugin plugin) {
        this.clientId = clientId;
        this.plugin = plugin;
    }

    @Override
    public void onListenEnd() {}

    @Override
    public void onListenStart() {}

    @Override
    public void onServerError(int errorCode, @NonNull String errorMessage) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("errorCode", errorCode);
        arguments.put("errorMessage", errorMessage);
        invoke("onServerError", arguments);
    }

    @Override
    public void onStatusChange(@NonNull String status) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("status", status);
        invoke("onStatusChange", arguments);
    }

    @Override
    public void onPropertyChange(@NonNull String property) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("property", property);
        invoke("onPropertyChange", arguments);
    }

    void invoke(String method, Map<String, Object> arguments) {
        arguments.put("id", clientId);
        loop.post(() ->
            plugin._listenerChannel.invokeMethod("ClientListener." + method, arguments));
    }
}

class MySubscriptionListener implements SubscriptionListener {
    final String _subId;
    final Subscription _sub;
    final LightstreamerFlutterPlugin _plugin;
    final Handler _loop = new Handler(Looper.getMainLooper());

    MySubscriptionListener(String subId, Subscription sub, LightstreamerFlutterPlugin plugin) {
        this._subId = subId;
        this._sub = sub;
        this._plugin = plugin;
    }

    @Override
    public void onListenEnd() {}

    @Override
    public void onListenStart() {}

    @Override
    public void onClearSnapshot(@Nullable String itemName, int itemPos) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("itemName", itemName);
        arguments.put("itemPos", itemPos);
        invoke("onClearSnapshot", arguments);
    }

    @Override
    public void onCommandSecondLevelItemLostUpdates(int lostUpdates, @NonNull String key) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("lostUpdates", lostUpdates);
        arguments.put("key", key);
        invoke("onCommandSecondLevelItemLostUpdates", arguments);
    }

    @Override
    public void onCommandSecondLevelSubscriptionError(int code, @Nullable String message, String key) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("code", code);
        arguments.put("message", message);
        arguments.put("key", key);
        invoke("onCommandSecondLevelSubscriptionError", arguments);
    }

    @Override
    public void onEndOfSnapshot(@Nullable String itemName, int itemPos) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("itemName", itemName);
        arguments.put("itemPos", itemPos);
        invoke("onEndOfSnapshot", arguments);
    }

    @Override
    public void onItemLostUpdates(@Nullable String itemName, int itemPos, int lostUpdates) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("itemName", itemName);
        arguments.put("itemPos", itemPos);
        arguments.put("lostUpdates", lostUpdates);
        invoke("onItemLostUpdates", arguments);
    }

    @Override
    public void onItemUpdate(@NonNull ItemUpdate update) {
        // TODO improve performance
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("itemName", update.getItemName());
        arguments.put("itemPos", update.getItemPos());
        arguments.put("isSnapshot", update.isSnapshot());
        if (_sub.getFields() != null || _sub.getCommandSecondLevelFields() != null) {
            try {
                Map<String, String> changedFields = update.getChangedFields();
                Map<String, String> fields = update.getFields();
                Map<String, String> jsonFields = new HashMap<>();
                for (String fld : fields.keySet()) {
                    String json = update.getValueAsJSONPatchIfAvailable(fld);
                    if (json != null) {
                        jsonFields.put(fld, json);
                    }
                }
                arguments.put("changedFields", changedFields);
                arguments.put("fields", fields);
                arguments.put("jsonFields", jsonFields);
            } catch (Exception e) {
                // if the subscription doesn't have field names, the methods getChangedFields and
                // getFields may throw exceptions
            }
        }
        Map<Integer, String> changedFieldsByPosition = update.getChangedFieldsByPosition();
        Map<Integer, String> fieldsByPosition = update.getFieldsByPosition();
        Map<Integer, String> jsonFieldsByPosition = new HashMap<>();
        for (Integer pos : fieldsByPosition.keySet()) {
            String json = update.getValueAsJSONPatchIfAvailable(pos);
            if (json != null) {
                jsonFieldsByPosition.put(pos, json);
            }
        }
        arguments.put("changedFieldsByPosition", changedFieldsByPosition);
        arguments.put("fieldsByPosition", fieldsByPosition);
        arguments.put("jsonFieldsByPosition", jsonFieldsByPosition);
        invoke("onItemUpdate", arguments);
    }

    @Override
    public void onSubscription() {
        invoke("onSubscription", new HashMap<>());
    }

    @Override
    public void onSubscriptionError(int code, @Nullable String message) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("errorCode", code);
        arguments.put("errorMessage", message);
        invoke("onSubscriptionError", arguments);
    }

    @Override
    public void onUnsubscription() {
        invoke("onUnsubscription", new HashMap<>());
    }

    @Override
    public void onRealMaxFrequency(@Nullable String frequency) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("frequency", frequency);
        invoke("onRealMaxFrequency", arguments);
    }

    void invoke(String method, Map<String, Object> arguments) {
        arguments.put("subId", _subId);
        _loop.post(() ->
                _plugin._listenerChannel.invokeMethod("SubscriptionListener." + method, arguments));
    }
}
