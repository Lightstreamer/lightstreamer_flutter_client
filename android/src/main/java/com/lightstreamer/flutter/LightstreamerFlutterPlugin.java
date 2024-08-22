package com.lightstreamer.flutter;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.messaging.FirebaseMessaging;
import com.lightstreamer.client.ClientListener;
import com.lightstreamer.client.ClientMessageListener;
import com.lightstreamer.client.ItemUpdate;
import com.lightstreamer.client.LightstreamerClient;
import com.lightstreamer.client.Subscription;
import com.lightstreamer.client.SubscriptionListener;
import com.lightstreamer.client.mpn.MpnBuilder;
import com.lightstreamer.client.mpn.MpnDevice;
import com.lightstreamer.client.mpn.MpnDeviceListener;
import com.lightstreamer.client.mpn.MpnSubscription;
import com.lightstreamer.client.mpn.MpnSubscriptionListener;
import com.lightstreamer.log.ConsoleLoggerProvider;

import java.net.HttpCookie;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class LightstreamerFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    static final String TAG = "LightstreamerClient";
    static final com.lightstreamer.log.Logger channelLogger = com.lightstreamer.log.LogManager.getLogger("lightstreamer.flutter");

    // WARNING: Potential memory leak. Clients are added to the map but not removed.
    final Map<String, LightstreamerClient> _clientMap = new HashMap<>();
    final Map<String, Subscription> _subMap = new HashMap<>();
    final Map<String, MpnSubscription> _mpnSubMap = new HashMap<>();
    // maps client id to MpnDevice
    final Map<String, MpnDevice> _mpnDeviceMap = new HashMap<>();
    MethodChannel _methodChannel;
    MethodChannel _listenerChannel;
    Context _appContext;
    final Handler _loop = new Handler(Looper.getMainLooper());

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        _appContext = binding.getApplicationContext();
        _methodChannel = new MethodChannel(binding.getBinaryMessenger(), "com.lightstreamer.flutter/methods");
        _methodChannel.setMethodCallHandler(this);
        _listenerChannel = new MethodChannel(binding.getBinaryMessenger(), "com.lightstreamer.flutter/listeners");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        _methodChannel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (channelLogger.isDebugEnabled()) {
            channelLogger.debug("Accepting " + call.method + " " + call.arguments(), null);
        }
        // TODO optimize switch
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
            case "LightstreamerClient.sendMessage":
                sendMessage(call, result);
                break;
            case "LightstreamerClient.registerForMpn":
                registerForMpn(call, result);
                break;
            case "LightstreamerClient.subscribeMpn":
                subscribeMpn(call, result);
                break;
            case "LightstreamerClient.unsubscribeMpn":
                unsubscribeMpn(call, result);
                break;
            case "LightstreamerClient.unsubscribeMpnSubscriptions":
                unsubscribeMpnSubscriptions(call, result);
                break;
            case "LightstreamerClient.getMpnSubscriptions":
                getMpnSubscriptions(call, result);
                break;
            case "LightstreamerClient.findMpnSubscription":
                findMpnSubscription(call, result);
                break;
            case "LightstreamerClient.setLoggerProvider":
                setLoggerProvider(call, result);
                break;
            case "LightstreamerClient.addCookies":
                addCookies(call, result);
                break;
            case "LightstreamerClient.getCookies":
                getCookies(call, result);
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
//            case "ConnectionOptions.getRequestedMaxBandwidth":
//                ConnectionOptions_getRequestedMaxBandwidth(call, result);
//                break;
//            case "ConnectionOptions.setRequestedMaxBandwidth":
//                ConnectionOptions_setRequestedMaxBandwidth(call, result);
//                break;
            case "MpnDevice.getApplicationId":
                MpnDevice_getApplicationId(call, result);
                break;
            case "MpnDevice.getDeviceId":
                MpnDevice_getDeviceId(call, result);
                break;
            case "MpnDevice.getDeviceToken":
                MpnDevice_getDeviceToken(call, result);
                break;
            case "MpnDevice.getPlatform":
                MpnDevice_getPlatform(call, result);
                break;
            case "MpnDevice.getPreviousDeviceToken":
                MpnDevice_getPreviousDeviceToken(call, result);
                break;
            case "MpnDevice.getStatus":
                MpnDevice_getStatus(call, result);
                break;
            case "MpnDevice.getStatusTimestamp":
                MpnDevice_getStatusTimestamp(call, result);
                break;
            case "MpnDevice.isRegistered":
                MpnDevice_isRegistered(call, result);
                break;
            case "MpnDevice.isSuspended":
                MpnDevice_isSuspended(call, result);
                break;
            case "Subscription.getCommandPosition":
                Subscription_getCommandPosition(call, result);
                break;
            case "Subscription.getKeyPosition":
                Subscription_getKeyPosition(call, result);
                break;
//            case "Subscription.getRequestedMaxFrequency":
//                Subscription_getRequestedMaxFrequency(call, result);
//                break;
//            case "Subscription.setRequestedMaxFrequency":
//                Subscription_setRequestedMaxFrequency(call, result);
//                break;
            case "Subscription.isActive":
                Subscription_isActive(call, result);
                break;
            case "Subscription.isSubscribed":
                Subscription_isSubscribed(call, result);
                break;
            case "AndroidMpnBuilder.build":
                AndroidMpnBuilder_build(call, result);
                break;
            case "MpnSubscription.setTriggerExpression":
                MpnSubscription_setTriggerExpression(call, result);
                break;
            case "MpnSubscription.setNotificationFormat":
                MpnSubscription_setNotificationFormat(call, result);
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

    void setLoggerProvider(MethodCall call, MethodChannel.Result result) {
        int level = call.argument("level");
        LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(level));
        result.success(null);
    }

    void addCookies(MethodCall call, MethodChannel.Result result) {
        String uri = call.argument("uri");
        List<String> cookies = call.argument("cookies");
        URI uri_ = URI.create(uri);
        List<HttpCookie> cookies_ = cookies.stream().flatMap(c -> HttpCookie.parse(c).stream()).collect(Collectors.toList());
        LightstreamerClient.addCookies(uri_, cookies_);
        result.success(null);
    }

    void getCookies(MethodCall call, MethodChannel.Result result) {
        String uri = call.argument("uri");
        URI uri_ = URI.create(uri);
        List<String> res = LightstreamerClient.getCookies(uri_).stream().map(LightstreamerFlutterPlugin::cookieToString).collect(Collectors.toList());
        result.success(res);
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

    void sendMessage(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String msgId = call.argument("msgId");
        String message = call.argument("message");
        String sequence = call.argument("sequence");
        Integer _delayTimeout = call.argument("delayTimeout");
        int delayTimeout = _delayTimeout == null ? -1 : _delayTimeout;
        Boolean _enqueueWhileDisconnected = call.argument("enqueueWhileDisconnected");
        boolean enqueueWhileDisconnected = _enqueueWhileDisconnected == null ? false : _enqueueWhileDisconnected;
        ClientMessageListener listener = null;
        if (msgId != null) {
            listener = new MyClientMessageListener(msgId, this);
        }
        client.sendMessage(message, sequence, delayTimeout, listener, enqueueWhileDisconnected);
        result.success(null);
    }

    void registerForMpn(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String id = call.argument("id");
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(new OnCompleteListener<String>() {
            @Override
            public void onComplete(@NonNull Task<String> task) {
                if (!task.isSuccessful()) {
                    // TODO manage error
                    return;
                }
                String token = task.getResult();
                MpnDevice device = new MpnDevice(_appContext, token);
                device.addListener(new MyMpnDeviceListener(id, LightstreamerFlutterPlugin.this));
                client.registerForMpn(device);
                _mpnDeviceMap.put(id, device); // TODO what if already assigned?

                result.success(null);
            }
        });
    }

    void subscribeMpn(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        Map<String, Object> options = call.argument("subscription");
        String mpnSubId = (String) options.get("id");
        List<String> items = (List<String>) options.get("items");
        List<String> fields = (List<String>) options.get("fields");
        String group = (String) options.get("group");
        String schema = (String) options.get("schema");
        String dataAdapter = (String) options.get("dataAdapter");
        String bufferSize = (String) options.get("bufferSize");
        String requestedMaxFrequency = (String) options.get("requestedMaxFrequency");
        String trigger = (String) options.get("trigger");
        String format = (String) options.get("notificationFormat");
        boolean coalescing = (boolean) call.argument("coalescing");
        MpnSubscription sub = new MpnSubscription((String) options.get("mode"));
        // TODO what if already in _subMap?
        _mpnSubMap.put(mpnSubId, sub);
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
        if (requestedMaxFrequency != null) {
            sub.setRequestedMaxFrequency(requestedMaxFrequency);
        }
        if (trigger != null) {
            sub.setTriggerExpression(trigger);
        }
        if (format != null) {
            sub.setNotificationFormat(format);
        }
        sub.addListener(new MyMpnSubscriptionListener(mpnSubId, sub, this));
        client.subscribe(sub, coalescing);
        result.success(null);
    }

    void unsubscribeMpn(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String mpnSubId = call.argument("mpnSubId");
        MpnSubscription sub = _mpnSubMap.get(mpnSubId);
        _mpnSubMap.remove(mpnSubId);
        // TODO what if null?
        client.unsubscribe(sub);
        result.success(null);
    }

    void unsubscribeMpnSubscriptions(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String filter = (String) call.argument("filter");
        // TODO how to avoid _mpnSubMap memory leak?
        client.unsubscribeMpnSubscriptions(filter);
        result.success(null);
    }

    void getMpnSubscriptions(MethodCall call, MethodChannel.Result result) {
        // TODO improve performance
        LightstreamerClient client = getClient(call);
        String filter = (String) call.argument("filter");
        List<MpnSubscription> subs = client.getMpnSubscriptions(filter);
        List<String> res = new ArrayList<>();
        for (Map.Entry<String, MpnSubscription> e : _mpnSubMap.entrySet()) {
            if (subs.contains(e.getValue())) {
                res.add(e.getKey());
            }
        }
        result.success(res);
    }

    void findMpnSubscription(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String subscriptionId = (String) call.argument("subscriptionId");
        MpnSubscription sub = client.findMpnSubscription(subscriptionId);
        String res = null;
        for (Map.Entry<String, MpnSubscription> e : _mpnSubMap.entrySet()) {
            // TODO what if more than one?
            if (sub == e.getValue()) {
                res = e.getKey();
                break;
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

//    void ConnectionOptions_getRequestedMaxBandwidth(MethodCall call, MethodChannel.Result result) {
//        LightstreamerClient client = getClient(call);
//        String res = client.connectionOptions.getRequestedMaxBandwidth();
//        result.success(res);
//    }
//
//    void ConnectionOptions_setRequestedMaxBandwidth(MethodCall call, MethodChannel.Result result) {
//        LightstreamerClient client = getClient(call);
//        String newVal = call.argument("newVal");
//        client.connectionOptions.setRequestedMaxBandwidth(newVal);
//        result.success(null);
//    }

    void MpnDevice_getApplicationId(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getApplicationId();
        result.success(res);
    }

    void MpnDevice_getDeviceId(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getDeviceId();
        result.success(res);
    }

    void MpnDevice_getDeviceToken(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getDeviceToken();
        result.success(res);
    }

    void MpnDevice_getPlatform(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getPlatform();
        result.success(res);
    }

    void MpnDevice_getPreviousDeviceToken(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getPreviousDeviceToken();
        result.success(res);
    }

    void MpnDevice_getStatus(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getStatus();
        result.success(res);
    }

    void MpnDevice_getStatusTimestamp(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.getStatusTimestamp();
        result.success(res);
    }

    void MpnDevice_isRegistered(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.isRegistered();
        result.success(res);
    }

    void MpnDevice_isSuspended(MethodCall call, MethodChannel.Result result) {
        String id = call.argument("id");
        // TODO null check
        MpnDevice device = _mpnDeviceMap.get(id);
        Object res = device.isSuspended();
        result.success(res);
    }

    void AndroidMpnBuilder_build(MethodCall call, MethodChannel.Result result) {
        String collapseKey = call.argument("collapseKey");
        String priority = call.argument("priority");
        String timeToLive = call.argument("timeToLive");
        String title = call.argument("title");
        String titleLocKey = call.argument("titleLocKey");
        List<String> titleLocArguments = call.argument("titleLocArguments");
        String body = call.argument("body");
        String bodyLocKey = call.argument("bodyLocKey");
        List<String> bodyLocArguments = call.argument("bodyLocArguments");
        String icon = call.argument("icon");
        String sound = call.argument("sound");
        String tag = call.argument("tag");
        String color = call.argument("color");
        String clickAction = call.argument("clickAction");
        Map<String, String> data = call.argument("data");
        String notificationFormat = call.argument("notificationFormat");
        MpnBuilder builder = notificationFormat == null ? new MpnBuilder() : new MpnBuilder(notificationFormat);
        builder.collapseKey(collapseKey);
        builder.priority(priority);
        builder.timeToLive(timeToLive);
        builder.title(title);
        builder.titleLocKey(titleLocKey);
        builder.titleLocArguments(titleLocArguments);
        builder.body(body);
        builder.bodyLocKey(bodyLocKey);
        builder.bodyLocArguments(bodyLocArguments);
        builder.icon(icon);
        builder.sound(sound);
        builder.tag(tag);
        builder.color(color);
        builder.clickAction(clickAction);
        builder.data(data);
        String res = builder.build();
        result.success(res);
    }

    void Subscription_getCommandPosition(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = _subMap.get(subId);
        // TODO null check
        Object res = sub.getCommandPosition();
        result.success(res);
    }

    void Subscription_getKeyPosition(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = _subMap.get(subId);
        // TODO null check
        Object res = sub.getKeyPosition();
        result.success(res);
    }

//    void Subscription_getRequestedMaxFrequency(MethodCall call, MethodChannel.Result result) {
//        String subId = call.argument("subId");
//        Subscription sub = _subMap.get(subId);
//        // TODO null check
//        Object res = sub.getRequestedMaxFrequency();
//        result.success(res);
//    }
//
//    void Subscription_setRequestedMaxFrequency(MethodCall call, MethodChannel.Result result) {
//        String subId = call.argument("subId");
//        String newVal = call.argument("newVal");
//        Subscription sub = _subMap.get(subId);
//        // TODO null check
//        sub.setRequestedMaxFrequency(newVal);
//        result.success(null);
//    }

    void Subscription_isActive(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = _subMap.get(subId);
        // TODO null check
        Object res = sub.isActive();
        result.success(res);
    }

    void Subscription_isSubscribed(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = _subMap.get(subId);
        // TODO null check
        Object res = sub.isSubscribed();
        result.success(res);
    }

    void MpnSubscription_setTriggerExpression(MethodCall call, MethodChannel.Result result) {
        String mpnSubId = call.argument("mpnSubId");
        MpnSubscription sub = _mpnSubMap.get(mpnSubId);
        if (sub == null) {
            Log.w(TAG, "MpnSubscription with id " + mpnSubId + " not found");
            result.success(null);
            return;
        }
        sub.setTriggerExpression(call.argument("trigger"));
        result.success(null);
    }

    void MpnSubscription_setNotificationFormat(MethodCall call, MethodChannel.Result result) {
        String mpnSubId = call.argument("mpnSubId");
        MpnSubscription sub = _mpnSubMap.get(mpnSubId);
        if (sub == null) {
            Log.w(TAG, "MpnSubscription with id " + mpnSubId + " not found");
            result.success(null);
            return;
        }
        sub.setNotificationFormat(call.argument("notificationFormat"));
        result.success(null);
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

    void invokeMethod(String method, Map<String, Object> arguments) {
        if (channelLogger.isDebugEnabled()) {
            channelLogger.debug("Invoking " + method + " " + arguments, null);
        }
        _loop.post(() -> _listenerChannel.invokeMethod(method, arguments));
    }

    static String cookieToString(HttpCookie c) {
        StringBuilder result = new StringBuilder();
        result.append(c.getName());
        result.append("=");
        result.append(c.getValue());
        if (c.getDomain() != null) {
            result.append("; domain=");
            result.append(c.getDomain());
        }
        if (c.getPath() != null) {
            result.append("; path=");
            result.append(c.getPath());
        }
        if (c.getMaxAge() > 0) {
            result.append("; Max-Age=").append(c.getMaxAge());
        }
        if (c.getSecure()) {
            result.append("; secure");
        }
        if (c.isHttpOnly()) {
            result.append("; HttpOnly");
        }
        return result.toString();
    }
}

class MyClientListener implements ClientListener {
    final String clientId;
    final LightstreamerFlutterPlugin plugin;

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
        plugin.invokeMethod("ClientListener." + method, arguments);
    }
}

class MySubscriptionListener implements SubscriptionListener {
    final String _subId;
    final Subscription _sub;
    final LightstreamerFlutterPlugin _plugin;

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
        _plugin.invokeMethod("SubscriptionListener." + method, arguments);
    }
}

class MyClientMessageListener implements ClientMessageListener {
    final String _msgId;
    final LightstreamerFlutterPlugin _plugin;

    MyClientMessageListener(String msgId, LightstreamerFlutterPlugin plugin) {
        this._msgId = msgId;
        this._plugin = plugin;
    }
    @Override
    public void onAbort(@NonNull String originalMessage, boolean sentOnNetwork) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("originalMessage", originalMessage);
        arguments.put("sentOnNetwork", sentOnNetwork);
        invoke("onAbort", arguments);
    }

    @Override
    public void onDeny(@NonNull String originalMessage, int errorCode, @NonNull String errorMessage) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("originalMessage", originalMessage);
        arguments.put("errorCode", errorCode);
        arguments.put("errorMessage", errorMessage);
        invoke("onDeny", arguments);
    }

    @Override
    public void onDiscarded(@NonNull String originalMessage) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("originalMessage", originalMessage);
        invoke("onDiscarded", arguments);
    }

    @Override
    public void onError(@NonNull String originalMessage) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("originalMessage", originalMessage);
        invoke("onError", arguments);
    }

    @Override
    public void onProcessed(@NonNull String originalMessage, @NonNull String response) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("originalMessage", originalMessage);
        arguments.put("response", response);
        invoke("onProcessed", arguments);
    }

    void invoke(String method, Map<String, Object> arguments) {
        arguments.put("msgId", _msgId);
        _plugin.invokeMethod("ClientMessageListener." + method, arguments);
    }
}

class MyMpnDeviceListener implements MpnDeviceListener {
    final String _clientId;
    final LightstreamerFlutterPlugin _plugin;

    MyMpnDeviceListener(String clientId, LightstreamerFlutterPlugin plugin) {
        this._clientId = clientId;
        this._plugin = plugin;
    }

    @Override
    public void onListenStart() {}

    @Override
    public void onListenEnd() {}

    @Override
    public void onRegistered() {
        invoke("onRegistered");
    }

    @Override
    public void onSuspended() {
        invoke("onSuspended");
    }

    @Override
    public void onResumed() {
        invoke("onResumed");
    }

    @Override
    public void onStatusChanged(@NonNull String status, long timestamp) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("status", status);
        arguments.put("timestamp", timestamp);
        invoke("onStatusChanged", arguments);
    }

    @Override
    public void onRegistrationFailed(int code, @NonNull String message) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("errorCode", code);
        arguments.put("errorMessage", message);
        invoke("onRegistrationFailed", arguments);
    }

    @Override
    public void onSubscriptionsUpdated() {
        invoke("onSubscriptionsUpdated");
    }

    void invoke(String method, Map<String, Object> arguments) {
        arguments.put("id", _clientId);
        _plugin.invokeMethod("MpnDeviceListener." + method, arguments);
    }

    void invoke(String method) {
       invoke(method, new HashMap<>());
    }
}

class MyMpnSubscriptionListener implements MpnSubscriptionListener {
    final String _mpnSubId;
    final MpnSubscription _sub;
    final LightstreamerFlutterPlugin _plugin;

    MyMpnSubscriptionListener(String mpnSubId, MpnSubscription sub, LightstreamerFlutterPlugin plugin) {
        this._mpnSubId = mpnSubId;
        this._sub = sub;
        this._plugin = plugin;
    }

    @Override
    public void onListenStart() {}

    @Override
    public void onListenEnd() {}

    @Override
    public void onSubscription() {
        Map<String, Object> arguments = new HashMap<>();
        invoke("onSubscription", arguments);
    }

    @Override
    public void onUnsubscription() {
        Map<String, Object> arguments = new HashMap<>();
        invoke("onUnsubscription", arguments);
    }

    @Override
    public void onSubscriptionError(int code, @Nullable String message) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("errorCode", code);
        arguments.put("errorMessage", message);
        invoke("onSubscriptionError", arguments);
    }

    @Override
    public void onUnsubscriptionError(int code, @Nullable String message) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("errorCode", code);
        arguments.put("errorMessage", message);
        invoke("onUnsubscriptionError", arguments);
    }

    @Override
    public void onTriggered() {
        Map<String, Object> arguments = new HashMap<>();
        invoke("onTriggered", arguments);
    }

    @Override
    public void onStatusChanged(@NonNull String status, long timestamp) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("status", status);
        arguments.put("timestamp", timestamp);
        arguments.put("subscriptionId", "UNKNOWN".equals(status) ? null : _sub.getSubscriptionId());
        invoke("onStatusChanged", arguments);
    }

    @Override
    public void onPropertyChanged(@NonNull String propertyName) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("property", propertyName);
        switch (propertyName) {
            case "status_timestamp":
                arguments.put("value", _sub.getStatusTimestamp());
                break;
            case "mode":
                arguments.put("value", _sub.getMode());
                break;
            case "adapter":
                arguments.put("value", _sub.getDataAdapter());
                break;
            case "group":
                arguments.put("value", _sub.getItemGroup());
                break;
            case "schema":
                arguments.put("value", _sub.getFieldSchema());
                break;
            case "notification_format":
                arguments.put("value", _sub.getActualNotificationFormat());
                break;
            case "trigger":
                arguments.put("value", _sub.getActualTriggerExpression());
                break;
            case "requested_buffer_size":
                arguments.put("value", _sub.getRequestedBufferSize());
                break;
            case "requested_max_frequency":
                arguments.put("value", _sub.getRequestedMaxFrequency());
                break;
        }
        invoke("onPropertyChanged", arguments);
    }

    @Override
    public void onModificationError(int code, String message, String propertyName) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("errorCode", code);
        arguments.put("errorMessage", message);
        arguments.put("propertyName", propertyName);
        invoke("onModificationError", arguments);
    }

    void invoke(String method, Map<String, Object> arguments) {
        arguments.put("mpnSubId", _mpnSubId);
        _plugin.invokeMethod("MpnSubscriptionListener." + method, arguments);
    }
}