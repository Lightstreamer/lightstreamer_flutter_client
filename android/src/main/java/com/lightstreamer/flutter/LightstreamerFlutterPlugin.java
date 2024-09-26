package com.lightstreamer.flutter;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

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
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * A plugin manages the communication between the Flutter component (the Flutter app targeting Android using the Lightstreamer Flutter Client SDK)
 * and this Android component (the environment running the Lightstreamer Android Client SDK
 * that performs the operations requested by the Flutter component).
 * See also: https://docs.flutter.dev/platform-integration/platform-channels
 */
public class LightstreamerFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    static final com.lightstreamer.log.Logger channelLogger = com.lightstreamer.log.LogManager.getLogger("lightstreamer.flutter");
    static final AtomicInteger _mpnSubIdGenerator = new AtomicInteger();

    // TODO potential memory leak: objects are added to the maps but never removed

    /**
     * Maps a clientId (i.e. the `id` field of a MethodCall object) to a LightstreamerClient.
     * The mapping is created when any LightstreamerClient method is called by the Flutter component.
     */
    final Map<String, LightstreamerClient> _clientMap = new HashMap<>();
    /**
     * Maps a subId (i.e. the `subId` field of a MethodCall object) to a Subscription.
     * The mapping is created when `LightstreamerClient.subscribe` is called.
     */
    final Map<String, Subscription> _subMap = new HashMap<>();
    /**
     * Maps an mpnSubId (i.e. the `mpnSubId` field of a MethodCall object) to an MpnSubscription.
     * The mapping is created either when
     * 1. `LightstreamerClient.subscribeMpn` is called, or
     * 2. a Server MpnSubscription (i.e. an MpnSubscription not created in response to a `LightstreamerClient.subscribeMpn` call)
     *    is returned by `LightstreamerClient.getMpnSubscriptions` or `LightstreamerClient.findMpnSubscription`.
     */
    final Map<String, MyMpnSubscription> _mpnSubMap = new HashMap<>();
    /**
     * Maps an mpnDevId (i.e. the `mpnDevId` field of a MethodCall object) to an MpnDevice.
     * The mapping is created when `LightstreamerClient.registerForMpn` is called.
     */
    final Map<String, MpnDevice> _mpnDeviceMap = new HashMap<>();
    /**
     * The channel through which the procedure calls requested by the Flutter component are received.
     */
    MethodChannel _methodChannel;
    /**
     * The channel through which the events fired by the listeners are communicated to the Flutter component.
     */
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
        try {
            String[] parts = call.method.split("\\.");
            String className = parts[0];
            String methodName = parts[1];
            switch (className) {
                case "LightstreamerClient":
                    Client_handle(methodName, call, result);
                    break;
                case "ConnectionDetails":
                    ConnectionDetails_handle(methodName, call, result);
                    break;
                case "ConnectionOptions":
                    ConnectionOptions_handle(methodName, call, result);
                    break;
                case "Subscription":
                    Subscription_handle(methodName, call, result);
                    break;
                case "MpnDevice":
                    MpnDevice_handle(methodName, call, result);
                    break;
                case "MpnSubscription":
                    MpnSubscription_handle(methodName, call, result);
                    break;
                case "AndroidMpnBuilder":
                    AndroidMpnBuilder_handle(methodName, call, result);
                    break;
                default:
                    if (channelLogger.isErrorEnabled()) {
                        channelLogger.error("Unknown method " + call.method, null);
                    }
                    result.notImplemented();
            }
        } catch (Exception e) {
            if (channelLogger.isErrorEnabled()) {
                channelLogger.error(e.getMessage(), e);
            }
            result.error("Lightstreamer Internal Error", e.getMessage(), e);
        }
    }

    void Client_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            case "create":
                Client_create(call, result);
                break;
            case "connect":
                Client_connect(call, result);
                break;
            case "disconnect":
                Client_disconnect(call, result);
                break;
            case "getStatus":
                Client_getStatus(call, result);
                break;
            case "subscribe":
                Client_subscribe(call, result);
                break;
            case "unsubscribe":
                Client_unsubscribe(call, result);
                break;
            case "getSubscriptions":
                Client_getSubscriptions(call, result);
                break;
            case "sendMessage":
                Client_sendMessage(call, result);
                break;
            case "registerForMpn":
                Client_registerForMpn(call, result);
                break;
            case "subscribeMpn":
                Client_subscribeMpn(call, result);
                break;
            case "unsubscribeMpn":
                Client_unsubscribeMpn(call, result);
                break;
            case "unsubscribeMpnSubscriptions":
                Client_unsubscribeMpnSubscriptions(call, result);
                break;
            case "getMpnSubscriptions":
                Client_getMpnSubscriptions(call, result);
                break;
            case "findMpnSubscription":
                Client_findMpnSubscription(call, result);
                break;
            case "setLoggerProvider":
                Client_setLoggerProvider(call, result);
                break;
            case "addCookies":
                Client_addCookies(call, result);
                break;
            case "getCookies":
                Client_getCookies(call, result);
                break;
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void ConnectionDetails_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            case "setServerAddress":
                Details_setServerAddress(call, result);
                break;
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void ConnectionOptions_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            case "setForcedTransport":
                ConnectionOptions_setForcedTransport(call, result);
                break;
            case "setRequestedMaxBandwidth":
                ConnectionOptions_setRequestedMaxBandwidth(call, result);
                break;
            case "setReverseHeartbeatInterval":
                ConnectionOptions_setReverseHeartbeatInterval(call, result);
                break;
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void Subscription_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            case "getCommandPosition":
                Subscription_getCommandPosition(call, result);
                break;
            case "getKeyPosition":
                Subscription_getKeyPosition(call, result);
                break;
            case "setRequestedMaxFrequency":
                Subscription_setRequestedMaxFrequency(call, result);
                break;
            case "isActive":
                Subscription_isActive(call, result);
                break;
            case "isSubscribed":
                Subscription_isSubscribed(call, result);
                break;
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void MpnDevice_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void MpnSubscription_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            case "setTriggerExpression":
                MpnSubscription_setTriggerExpression(call, result);
                break;
            case "setNotificationFormat":
                MpnSubscription_setNotificationFormat(call, result);
                break;
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void AndroidMpnBuilder_handle(String method, MethodCall call, MethodChannel.Result result) {
        switch (method) {
            case "build":
                AndroidMpnBuilder_build(call, result);
                break;
            default:
                if (channelLogger.isErrorEnabled()) {
                    channelLogger.error("Unknown method " + call.method, null);
                }
                result.notImplemented();
        }
    }

    void Client_create(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = createClient(call);
        String id = call.argument("id");
        client.addListener(new MyClientListener(id, client, this));
        result.success(null);
    }

    void Client_setLoggerProvider(MethodCall call, MethodChannel.Result result) {
        int level = call.argument("level");
        LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(level));
        result.success(null);
    }

    void Client_addCookies(MethodCall call, MethodChannel.Result result) {
        String uri = call.argument("uri");
        List<String> cookies = call.argument("cookies");
        URI uri_ = URI.create(uri);
        List<HttpCookie> cookies_ = cookies.stream().flatMap(c -> HttpCookie.parse(c).stream()).collect(Collectors.toList());
        LightstreamerClient.addCookies(uri_, cookies_);
        result.success(null);
    }

    void Client_getCookies(MethodCall call, MethodChannel.Result result) {
        String uri = call.argument("uri");
        URI uri_ = URI.create(uri);
        List<String> res = LightstreamerClient.getCookies(uri_).stream().map(LightstreamerFlutterPlugin::cookieToString).collect(Collectors.toList());
        result.success(res);
    }

    void Client_connect(MethodCall call, MethodChannel.Result result) {
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

    void Client_disconnect(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        client.disconnect();
        result.success(null);
    }

    void Client_getStatus(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String res = client.getStatus();
        result.success(res);
    }

    void Client_subscribe(MethodCall call, MethodChannel.Result result) {
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
        Subscription sub = _subMap.get(subId);
        if (sub == null) {
            sub = new Subscription((String) options.get("mode"));
            sub.addListener(new MySubscriptionListener(subId, sub, this));
            _subMap.put(subId, sub);
        }
        if (sub.isActive()) {
            throw new IllegalStateException("Cannot subscribe to an active Subscription");
        }
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
        client.subscribe(sub);
        result.success(null);
    }

    void Client_unsubscribe(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String subId = call.argument("subId");
        Subscription sub = getSubscription(subId);
        client.unsubscribe(sub);
        result.success(null);
    }

    void Client_getSubscriptions(MethodCall call, MethodChannel.Result result) {
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

    void Client_sendMessage(MethodCall call, MethodChannel.Result result) {
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

    void Client_registerForMpn(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String mpnDevId = call.argument("mpnDevId");
        MpnDevice device = _mpnDeviceMap.get(mpnDevId);
        if (device != null) {
            client.registerForMpn(device);
            result.success(null);
            return;
        }
        // mpnDevId is unknown: get a device token and create a new device
        FirebaseMessaging.getInstance().getToken().addOnCompleteListener(new OnCompleteListener<String>() {
            @Override
            public void onComplete(@NonNull Task<String> task) {
                if (!task.isSuccessful()) {
                    String errMsg = "MPN Device Token is unavailable";
                    if (channelLogger.isErrorEnabled()) {
                        channelLogger.error(errMsg, null);
                    }
                    result.error("Lightstreamer Internal Error", errMsg, task.getException());
                    return;
                }
                // TODO synchronize access to `_mpnDeviceMap`?
                if (_mpnDeviceMap.containsKey(mpnDevId)) {
                    String errMsg = "MpnDevice " + mpnDevId + " already exists";
                    if (channelLogger.isErrorEnabled()) {
                        channelLogger.error(errMsg, null);
                    }
                    result.error("Lightstreamer Internal Error", errMsg, null);
                    return;
                }
                String token = task.getResult();
                MpnDevice device = new MpnDevice(_appContext, token);
                device.addListener(new MyMpnDeviceListener(mpnDevId, device, LightstreamerFlutterPlugin.this));
                _mpnDeviceMap.put(mpnDevId, device);
                client.registerForMpn(device);

                result.success(null);
            }
        });
    }

    void Client_subscribeMpn(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        Map<String, Object> options = call.argument("subscription");
        String mpnSubId = (String) options.get("id");
        String mode = (String) options.get("mode");
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
        MyMpnSubscription mySub = _mpnSubMap.get(mpnSubId);
        if (mySub == null) {
            MpnSubscription sub = new MpnSubscription(mode);
            sub.addListener(new MyMpnSubscriptionListener(mpnSubId, sub, this));
            mySub = new MyMpnSubscription(client, mpnSubId, sub);
            _mpnSubMap.put(mpnSubId, mySub);
        }
        MpnSubscription sub = mySub._sub;
        if (sub.isActive()) {
            throw new IllegalStateException("Cannot subscribe to an active MpnSubscription");
        }
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
        client.subscribe(sub, coalescing);
        result.success(null);
    }

    void Client_unsubscribeMpn(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String mpnSubId = call.argument("mpnSubId");
        MpnSubscription sub = getMpnSubscription(mpnSubId);
        client.unsubscribe(sub);
        result.success(null);
    }

    void Client_unsubscribeMpnSubscriptions(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String filter = (String) call.argument("filter");
        client.unsubscribeMpnSubscriptions(filter);
        result.success(null);
    }

    String nextServerMpnSubId() {
        // IMPLEMENTATION NOTE
        // since mpnSubIds for user subscriptions are generated by the Flutter component
        // while mpnSubIds for server subscriptions are generated by this Android component,
        // a simple way to ensure that server and user mpnSubIds are unique is to use different prefixes,
        // i.e. "mpnsub" for user subscriptions and "mpnsub-server" for server subscriptions
        return "mpnsub-server" + _mpnSubIdGenerator.getAndIncrement();
    }

    void Client_getMpnSubscriptions(MethodCall call, MethodChannel.Result result) {
        // TODO improve performance
        LightstreamerClient client = getClient(call);
        String filter = (String) call.argument("filter");
        List<MpnSubscription> subs = client.getMpnSubscriptions(filter);
        //
        List<String> knownSubs = new ArrayList<>();
        List<Map<String, Object>> unknownSubs = new ArrayList<>();
        for (MpnSubscription sub : subs) {
            String subscriptionId = sub.getSubscriptionId(); // can be null
            // 1. search a subscription known to the Flutter component (i.e. in `_mpnSubMap`) and owned by `client` having the same subscriptionId
            if (subscriptionId != null) { // defensive check, even if `subscriptionId` should not be null
                String mpnSubId = null;
                for (Map.Entry<String, MyMpnSubscription> e : _mpnSubMap.entrySet()) {
                    MyMpnSubscription mySub = e.getValue();
                    if (mySub._client == client && subscriptionId.equals(mySub._sub.getSubscriptionId())) {
                        mpnSubId = e.getKey();
                        break;
                    }
                }
                if (mpnSubId != null) {
                    // 2.A. there is such a subscription: it means that `sub` is known to the Flutter component
                    knownSubs.add(mpnSubId);
                } else {
                    // 2.B. there isn't such a subscription: it means that `sub` is unknown to the Flutter component
                    // (i.e. it is a new server subscription)
                    // add it to `_mpnSubMap` and add a listener so the Flutter component can receive subscription events
                    mpnSubId = nextServerMpnSubId();
                    sub.addListener(new MyMpnSubscriptionListener(mpnSubId, sub, this));
                    MyMpnSubscription mySub = new MyMpnSubscription(client, mpnSubId, sub);
                    _mpnSubMap.put(mpnSubId, mySub);
                    // serialize `sub` in order to send it to the Flutter component
                    Map<String, Object> dto = mySub.toMap();
                    unknownSubs.add(dto);
                }
            } else {
                if (channelLogger.isWarnEnabled()) {
                    channelLogger.warn("MpnSubscription.subscriptionId should not be null, but it is", null);
                }
            }
        }
        Map<String, Object> res = new HashMap<>();
        res.put("result", knownSubs);
        res.put("extra", unknownSubs);
        result.success(res);
    }

    void Client_findMpnSubscription(MethodCall call, MethodChannel.Result result) {
        // TODO improve performance
        LightstreamerClient client = getClient(call);
        String subscriptionId = (String) call.argument("subscriptionId");
        MpnSubscription sub = client.findMpnSubscription(subscriptionId);
        //
        Map<String, Object> res = new HashMap<>();
        if (sub != null) {
            // 1. search a subscription known to the Flutter component (i.e. in `_mpnSubMap`) and owned by `client` having the same subscriptionId
            String mpnSubId = null;
            for (Map.Entry<String, MyMpnSubscription> e : _mpnSubMap.entrySet()) {
                MyMpnSubscription mySub = e.getValue();
                if (mySub._client == client && subscriptionId.equals(mySub._sub.getSubscriptionId())) {
                    mpnSubId = e.getKey();
                    break;
                }
            }
            if (mpnSubId != null) {
                // 2.A. there is such a subscription: it means that `sub` is known to the Flutter component
                res.put("result", mpnSubId);
            } else {
                // 2.B. there isn't such a subscription: it means that `sub` is unknown to the Flutter component
                // (i.e. it is a new server subscription)
                // add it to `_mpnSubMap` and add a listener so the Flutter component can receive subscription events
                mpnSubId = nextServerMpnSubId();
                sub.addListener(new MyMpnSubscriptionListener(mpnSubId, sub, this));
                MyMpnSubscription mySub = new MyMpnSubscription(client, mpnSubId, sub);
                _mpnSubMap.put(mpnSubId, mySub);
                // serialize `sub` in order to send it to the Flutter component
                Map<String, Object> dto = mySub.toMap();
                res.put("extra", dto);
            }
        } // else if sub == null, return an empty map
        result.success(res);
    }

    void Details_setServerAddress(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String newVal = call.argument("newVal");
        client.connectionDetails.setServerAddress(newVal);
        result.success(null);
    }

    void ConnectionOptions_setForcedTransport(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String newVal = call.argument("newVal");
        client.connectionOptions.setForcedTransport(newVal);
        result.success(null);
    }

    void ConnectionOptions_setRequestedMaxBandwidth(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        String newVal = call.argument("newVal");
        client.connectionOptions.setRequestedMaxBandwidth(newVal);
        result.success(null);
    }

    void ConnectionOptions_setReverseHeartbeatInterval(MethodCall call, MethodChannel.Result result) {
        LightstreamerClient client = getClient(call);
        int newVal = call.argument("newVal");
        client.connectionOptions.setReverseHeartbeatInterval(newVal);
        result.success(null);
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

    Subscription getSubscription(String subId) {
        Subscription sub = _subMap.get(subId);
        if (sub == null) {
            String errMsg = "Subscription " + subId + " doesn't exist";
            if (channelLogger.isErrorEnabled()) {
                channelLogger.error(errMsg, null);
            }
            throw new IllegalStateException(errMsg);
        }
        return sub;
    }

    void Subscription_getCommandPosition(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = getSubscription(subId);
        Object res = sub.getCommandPosition();
        result.success(res);
    }

    void Subscription_getKeyPosition(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = getSubscription(subId);
        Object res = sub.getKeyPosition();
        result.success(res);
    }

    void Subscription_setRequestedMaxFrequency(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        String newVal = call.argument("newVal");
        Subscription sub = getSubscription(subId);
        sub.setRequestedMaxFrequency(newVal);
        result.success(null);
    }

    void Subscription_isActive(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = getSubscription(subId);
        Object res = sub.isActive();
        result.success(res);
    }

    void Subscription_isSubscribed(MethodCall call, MethodChannel.Result result) {
        String subId = call.argument("subId");
        Subscription sub = getSubscription(subId);
        Object res = sub.isSubscribed();
        result.success(res);
    }

    MpnSubscription getMpnSubscription(String mpnSubId) {
        MyMpnSubscription mySub = _mpnSubMap.get(mpnSubId);
        if (mySub == null) {
            String errMsg = "MpnSubscription " + mpnSubId + " doesn't exist";
            if (channelLogger.isErrorEnabled()) {
                channelLogger.error(errMsg, null);
            }
            throw new IllegalStateException(errMsg);
        }
        return mySub._sub;
    }

    void MpnSubscription_setTriggerExpression(MethodCall call, MethodChannel.Result result) {
        String mpnSubId = call.argument("mpnSubId");
        MpnSubscription sub = getMpnSubscription(mpnSubId);
        sub.setTriggerExpression(call.argument("trigger"));
        result.success(null);
    }

    void MpnSubscription_setNotificationFormat(MethodCall call, MethodChannel.Result result) {
        String mpnSubId = call.argument("mpnSubId");
        MpnSubscription sub = getMpnSubscription(mpnSubId);
        sub.setNotificationFormat(call.argument("notificationFormat"));
        result.success(null);
    }

    LightstreamerClient createClient(MethodCall call) {
        String id = call.argument("id");
        LightstreamerClient ls = _clientMap.get(id);
        if (ls != null) {
            String errMsg = "LightstreamerClient " + id + " already exists";
            if (channelLogger.isErrorEnabled()) {
                channelLogger.error(errMsg, null);
            }
            throw new IllegalStateException(errMsg);
        }
        String serverAddress = call.argument("serverAddress");
        String adapterSet = call.argument("adapterSet");
        ls = new LightstreamerClient(serverAddress, adapterSet);
        _clientMap.put(id, ls);
        return ls;
    }

    LightstreamerClient getClient(MethodCall call) {
        String id = call.argument("id");
        LightstreamerClient ls = _clientMap.get(id);
        if (ls == null) {
            String errMsg = "A LightstreamerClient wit id " + id + " doesn't exist";
            if (channelLogger.isErrorEnabled()) {
                channelLogger.error(errMsg, null);
            }
            throw new IllegalStateException(errMsg);
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
    final LightstreamerClient client;
    final LightstreamerFlutterPlugin plugin;

    MyClientListener(String clientId, LightstreamerClient client, LightstreamerFlutterPlugin plugin) {
        this.clientId = clientId;
        this.client = client;
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
        switch (property) {
            case "serverInstanceAddress":
                arguments.put("value", client.connectionDetails.getServerInstanceAddress());
                break;
            case "serverSocketName":
                arguments.put("value", client.connectionDetails.getServerSocketName());
                break;
            case "clientIp":
                arguments.put("value", client.connectionDetails.getClientIp());
                break;
            case "sessionId":
                arguments.put("value", client.connectionDetails.getSessionId());
                break;
            case "realMaxBandwidth":
                arguments.put("value", client.connectionOptions.getRealMaxBandwidth());
                break;
            case "idleTimeout":
                arguments.put("value", client.connectionOptions.getIdleTimeout());
                break;
            case "keepaliveInterval":
                arguments.put("value", client.connectionOptions.getKeepaliveInterval());
                break;
            case "pollingInterval":
                arguments.put("value", client.connectionOptions.getPollingInterval());
                break;
        }
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
        Map<String, Object> arguments = new HashMap<>();
        if ("COMMAND".equals(_sub.getMode())) {
            arguments.put("commandPosition", _sub.getCommandPosition());
            arguments.put("keyPosition", _sub.getKeyPosition());
        }
        invoke("onSubscription", arguments);
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

class MyMpnSubscription {
    // TODO what if another client subscribes to this MpnSubscription?
    final LightstreamerClient _client;
    final String _mpnSubId;
    final MpnSubscription _sub;

    MyMpnSubscription(LightstreamerClient client, String mpnSubId, MpnSubscription sub) {
        _client = client;
        _mpnSubId = mpnSubId;
        _sub = sub;
    }

    Map<String, Object> toMap() {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", _mpnSubId);
        dto.put("mode", _sub.getMode());
        dto.put("items", _sub.getItems());
        dto.put("fields", _sub.getFields());
        dto.put("group", _sub.getItemGroup());
        dto.put("schema", _sub.getFieldSchema());
        dto.put("dataAdapter", _sub.getDataAdapter());
        dto.put("bufferSize", _sub.getRequestedBufferSize());
        dto.put("requestedMaxFrequency", _sub.getRequestedMaxFrequency());
        dto.put("notificationFormat", _sub.getNotificationFormat());
        dto.put("trigger", _sub.getTriggerExpression());
        dto.put("actualNotificationFormat", _sub.getActualNotificationFormat());
        dto.put("actualTrigger", _sub.getActualTriggerExpression());
        dto.put("statusTs", _sub.getStatusTimestamp());
        dto.put("status", _sub.getStatus());
        dto.put("subscriptionId", _sub.getSubscriptionId());
        return dto;
    }
}

class MyMpnDeviceListener implements MpnDeviceListener {
    final String _mpnDevId;
    final MpnDevice _device;
    final LightstreamerFlutterPlugin _plugin;

    MyMpnDeviceListener(String mpnDevId, MpnDevice device, LightstreamerFlutterPlugin plugin) {
        this._mpnDevId = mpnDevId;
        this._device = device;
        this._plugin = plugin;
    }

    @Override
    public void onListenStart() {}

    @Override
    public void onListenEnd() {}

    @Override
    public void onRegistered() {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("applicationId", _device.getApplicationId());
        arguments.put("deviceId", _device.getDeviceId());
        arguments.put("deviceToken", _device.getDeviceToken());
        arguments.put("platform", _device.getPlatform());
        arguments.put("previousDeviceToken", _device.getPreviousDeviceToken());
        invoke("onRegistered", arguments);
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
        arguments.put("mpnDevId", _mpnDevId);
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