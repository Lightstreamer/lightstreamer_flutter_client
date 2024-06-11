package com.lightstreamer.lightstreamer_flutter_client;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StringCodec;

import com.lightstreamer.client.LightstreamerClient;
import com.lightstreamer.client.Proxy;
import com.lightstreamer.client.Subscription;
import com.lightstreamer.client.SubscriptionListener;
import com.lightstreamer.client.mpn.MpnSubscription;
import com.lightstreamer.log.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;


/** LightstreamerFlutterClientPlugin */
public class LightstreamerFlutterClientPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private BasicMessageChannel<String> clientstatus_channel;

  private BasicMessageChannel<String> messagestatus_channel;

  private BasicMessageChannel<String> subscribedata_channel;

  private ConcurrentHashMap<String, Subscription> activeSubs = new ConcurrentHashMap<String, Subscription>();

  private ConcurrentHashMap<String, MpnSubscription> activeMpnSubs = new ConcurrentHashMap<String, MpnSubscription>();

  private int prgs_sub = 0;

  private LightstreamerClient ls = new LightstreamerClient("https://push.lightstreamer.com/", "WELCOME");

  final LightstreamerBridge lsBridge = new LightstreamerBridge();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.lightstreamer.lightstreamer_flutter_client.method");
    channel.setMethodCallHandler(this);

    clientstatus_channel = new BasicMessageChannel<String>(
            flutterPluginBinding.getBinaryMessenger(), "com.lightstreamer.lightstreamer_flutter_client.status", StringCodec.INSTANCE);

    messagestatus_channel = new BasicMessageChannel<String>(
            flutterPluginBinding.getBinaryMessenger(), "com.lightstreamer.lightstreamer_flutter_client.messages", StringCodec.INSTANCE);

    subscribedata_channel = new BasicMessageChannel<String>(
            flutterPluginBinding.getBinaryMessenger(), "com.lightstreamer.lightstreamer_flutter_client.realtime", StringCodec.INSTANCE);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    System.out.println("Method called: " + call.method);

    if (call.method.equals("connect")) {
      if (lsBridge.hasId(call)) {
        lsBridge.connect(call, result, clientstatus_channel);
      } else {
        connect(call, result);
      }
    } else if (call.method.equals("disconnect")) {
      if (lsBridge.hasId(call)) {
        lsBridge.disconnect(call, result);
      } else {
        disconnect(result);
      }
    } else if (call.method.equals("sendMessage")) {
      sendMessage(call, result);
    } else if (call.method.equals("sendMessageExt")) {
      if (lsBridge.hasId(call)) {
        lsBridge.sendMessageExt(call, result, messagestatus_channel);
      } else {
        sendMessageExt(call, result);
      }
    } else if (call.method.equals("subscribe")) {
      if (lsBridge.hasId(call)) {
        lsBridge.subscribe(call, result, subscribedata_channel);
      } else {
        subscribe(call, result);
      }
    } else if (call.method.equals("unsubscribe")) {
      if (lsBridge.hasId(call)) {
        lsBridge.unsubscribe(call, result);
      } else {
        unsubscribe(call, result);
      }
    } else if (call.method.equals("mpnSubscribe")) {
      if (lsBridge.hasId(call)) {
        lsBridge.mpnSubscribe(call, result, subscribedata_channel);
      } else {
        mpnSubscribe(call, result);
      }
    } else if (call.method.equals("mpnUnsubscribe")) {
      if (lsBridge.hasId(call)) {
        lsBridge.mpnUnsubscribe(call, result);
      } else {
        mpnUnsubscribe(call, result);
      }
    } else if (call.method.equals("getStatus")) {
      if (lsBridge.hasId(call)) {
        result.success(lsBridge.getStatus(call));
      } else {
        result.success(ls.getStatus());
      }
    } else if (call.method.equals("enableLog")) {
        enableLog();
    } else {
      result.notImplemented();
    }
  }

  private void enableLog() {
    LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.DEBUG));
  }

  private void mpnUnsubscribe(MethodCall call, Result result) {
    System.out.println("MPN Unsubscribe");
    if ( call.hasArgument("sub_id") ) {
      String sub_id = call.<String>argument("sub_id");
      System.out.println("Sub Id: " + sub_id);

      MpnSubscription sub = activeMpnSubs.remove(sub_id);
      if ( sub != null ) {
        ls.unsubscribe(sub);
      }

      result.success("Ok");
    } else {
      System.out.println("No Sub Id specified");

      result.error("4", "No Items List specified", null);
    }
  }

  private void mpnSubscribe(MethodCall call, Result result) {
    if ( call.hasArgument("mode") ) {
      String mode = call.<String>argument("mode");
      System.out.println("mode: " + mode);
      if ( call.hasArgument("itemList") ) {
        ArrayList<String> itemList = call.<ArrayList<String>>argument("itemList");
        System.out.println("itemList: " + itemList);
        String[] itemArr = new String[itemList.size()];
        itemArr = itemList.toArray(itemArr);

        if ( call.hasArgument("fieldList") ) {
          String sub_id = "Ok" + prgs_sub++;

          ArrayList<String> fieldList = call.<ArrayList<String>>argument("fieldList");
          System.out.println("fieldList: " + fieldList);
          String[] fieldArr = new String[fieldList.size()];
          fieldArr = fieldList.toArray(fieldArr);

          MpnSubscription sub = new MpnSubscription(mode, itemArr, fieldArr);

          if (call.hasArgument("dataAdapter"))
            sub.setDataAdapter(call.<String>argument("dataAdapter"));

          if (call.hasArgument("requestedBufferSize"))
            sub.setRequestedBufferSize(call.<String>argument("requestedBufferSize"));

          if (call.hasArgument("requestedMaxFrequency"))
            sub.setRequestedMaxFrequency(call.<String>argument("requestedMaxFrequency"));

          if (call.hasArgument("notificationFormat"))
            sub.setNotificationFormat(call.<String>argument("notificationFormat"));

          if (call.hasArgument("triggerExpression"))
            sub.setTriggerExpression(call.<String>argument("triggerExpression"));

          sub.addListener(new MyMpnSubListener(subscribedata_channel, sub_id));

          ls.subscribe(sub,true);

          activeMpnSubs.put(sub_id, sub);

          result.success(sub_id);
        } else {
          result.error("1", "No Fields List specified", null);
        }
      } else {
        result.error("2", "No Items List specified", null);
      }
    } else {
      result.error("3", "No subscription mode specified", null);
    }
  }

  private void unsubscribe(MethodCall call, Result result) {
    System.out.println("Unsubscribe");
    if ( call.hasArgument("sub_id") ) {
      String sub_id = call.<String>argument("sub_id");
      System.out.println("Sub Id: " + sub_id);

      Subscription sub = activeSubs.remove(sub_id);
      if ( sub != null ) {
        ls.unsubscribe(sub);
      }

      result.success("Ok");
    } else {
      System.out.println("No Sub Id specified");

      result.error("5", "No Items List specified", null);
    }
  }

  private void subscribe(MethodCall call, Result result) {
    try {
      String mode = call.argument("mode");
      Subscription sub = new Subscription(mode);

      List<String> itemList = call.argument("itemList");
      if (itemList != null) {
        sub.setItems(itemList.toArray(new String[0]));
      }
      String itemGroup = call.argument("itemGroup");
      if (itemGroup != null) {
        sub.setItemGroup(itemGroup);
      }
      List<String> fieldList = call.argument("fieldList");
      if (fieldList != null) {
        sub.setFields(fieldList.toArray(new String[0]));
      }
      String fieldSchema = call.argument("fieldSchema");
      if (fieldSchema != null) {
        sub.setFieldSchema(fieldSchema);
      }

      String sub_id = "Ok" + prgs_sub++;

      if (call.hasArgument("dataAdapter"))
        sub.setDataAdapter(call.<String>argument("dataAdapter"));

      if (call.hasArgument("requestedSnapshot"))
        sub.setRequestedSnapshot(call.<String>argument("requestedSnapshot"));

      if (call.hasArgument("requestedBufferSize"))
        sub.setRequestedBufferSize(call.<String>argument("requestedBufferSize"));

      if (call.hasArgument("requestedMaxFrequency"))
        sub.setRequestedMaxFrequency(call.<String>argument("requestedMaxFrequency"));

      if (call.hasArgument("commandSecondLevelDataAdapter"))
        sub.setCommandSecondLevelDataAdapter(call.<String>argument("commandSecondLevelDataAdapter"));

      if ( call.hasArgument("commandSecondLevelFields") ) {
        String sfieldList = call.<String>argument("commandSecondLevelFields");
        sub.setCommandSecondLevelFields(sfieldList.split(","));
      }

      SubscriptionListener subListener = new MySubListener(subscribedata_channel,sub_id,sub);
      sub.addListener(subListener);

      ls.subscribe(sub);

      activeSubs.put(sub_id, sub);

      result.success(sub_id);

    } catch (Exception ex) {
      result.error("61", ex.getMessage(), ex);
    }
  }

  private void sendMessageExt(MethodCall call, Result result) {
    if ( call.hasArgument("message") ) {
      int timeout = -1;
      String seq = null;
      boolean enq = false;
      boolean addListnr = false;

      System.out.println("message: " + call.<String>argument("message"));

      if ( call.hasArgument("sequence") ) {
        System.out.println("sequence: " + call.<String>argument("sequence"));

        seq = call.<String>argument("sequence");
        if (seq == null) {
          System.out.println("sequence forced to \"UNORDERED_MESSAGES\" ");
        }
      }
      if ( call.hasArgument("delayTimeout") ) {
        System.out.println("delayTimeout: " + call.<Integer>argument("delayTimeout"));

        if (call.<Integer>argument("delayTimeout") == null) {
          System.out.println("delayTimeout forced to negative");
        } else {
          timeout = call.<Integer>argument("delayTimeout").intValue();
        }

      }
      if ( call.hasArgument("enqueueWhileDisconnected") ) {
        System.out.println("enqueueWhileDisconnected: " + call.<Boolean>argument("enqueueWhileDisconnected"));

        if (call.<Integer>argument("enqueueWhileDisconnected") == null) {
          System.out.println("enqueueWhileDisconnected forced to false");
        } else {
          if (call.<Boolean>argument("enqueueWhileDisconnected").booleanValue()) {
            enq = true;
          }
        }
      }
      if ( call.hasArgument("listener") ) {
        System.out.println("listener: " + call.<Boolean>argument("listener"));

        if (call.<Integer>argument("listener") == null) {
          System.out.println("No listener");
        } else {
          if (call.<Boolean>argument("listener").booleanValue()) {
            addListnr = true;
          }
        }
      }

      if (addListnr) {
        ls.sendMessage(call.<String>argument("message"), seq, timeout, new MyClientMessageLisener(messagestatus_channel, "-1"), enq);
      } else {
        ls.sendMessage(call.<String>argument("message"), seq, timeout, null, enq);
      }

      result.success("OK");
    } else {
      System.out.println("No message passed. ");

      result.error("9", "No message", null);
    }
  }

  private void sendMessage(MethodCall call, Result result) {
    if ( call.hasArgument("message") ) {
      System.out.println("message: " + call.<String>argument("message"));

      ls.sendMessage(call.<String>argument("message"));

      result.success("Ok");
    } else {
      System.out.println("No message passed. ");

      result.error("10", "No message", null);
    }
  }

  private void disconnect(Result result) {
    if (ls.getStatus().startsWith("CONNECTED:")) {
      ls.disconnect();

      result.success(ls.getStatus());
    } else {
      System.out.println(" ... " + ls.getStatus());

      result.success(ls.getStatus());
    }
  }

  private void connect(MethodCall call, Result  result) {
    if (!ls.getStatus().startsWith("CONNECTED:")) {
      if ( call.hasArgument("serverAddress") ) {
        System.out.println("serverAddress: " + call.<String>argument("serverAddress"));

        ls.connectionDetails.setServerAddress(call.<String>argument("serverAddress"));
      } else {
        System.out.println("No serverAddress passed. ");

        result.error("11", "No server address was configured", null);

        return ;
      }
      if ( call.hasArgument("adapterSet") ) {
        System.out.println("adapterSet: " + call.<String>argument("adapterSet"));

        ls.connectionDetails.setAdapterSet(call.<String>argument("adapterSet"));
      } else {
        System.out.println("No adapterSet passed. ");

        result.error("12", "No adapter set id was configured", null);

        return ;
      }

      if (!ls.getListeners().isEmpty()) {
        ls.removeListener(ls.getListeners().get(0));
      }

      if (call.hasArgument("user"))
        ls.connectionDetails.setUser(call.<String>argument("user"));

      if (call.hasArgument("password"))
        ls.connectionDetails.setPassword(call.<String>argument("password"));

      try {
        if (call.hasArgument("forcedTransport")) {
          ls.connectionOptions.setForcedTransport(call.<String>argument("forcedTransport"));
          System.out.println("Forced Transport: " + call.<String>argument("forcedTransport"));
        }
      } catch (Exception e) {
        System.out.println("Forced Transport error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("firstRetryMaxDelay"))
          ls.connectionOptions.setFirstRetryMaxDelay(Long.parseLong(call.<String>argument("firstRetryMaxDelay")));
      } catch (Exception e) {
        System.out.println("First Retry Max Delay error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("retryDelay"))
          ls.connectionOptions.setRetryDelay(Long.parseLong(call.<String>argument("retryDelay")));
      } catch (Exception e) {
        System.out.println("Retry Delay error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("idleTimeout"))
          ls.connectionOptions.setIdleTimeout(Long.parseLong(call.<String>argument("idleTimeout")));
      } catch (Exception e) {
        System.out.println("Idle Timeout error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("reconnectTimeout"))
          ls.connectionOptions.setReconnectTimeout(Long.parseLong(call.<String>argument("reconnectTimeout")));
      } catch (Exception e) {
        System.out.println("Reconnect Timeout error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("stalledTimeout"))
          ls.connectionOptions.setStalledTimeout(Long.parseLong(call.<String>argument("stalledTimeout")));
      } catch (Exception e) {
        System.out.println("Stalled Timeout error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("sessionRecoveryTimeout"))
          ls.connectionOptions.setSessionRecoveryTimeout(Long.parseLong(call.<String>argument("sessionRecoveryTimeout")));
      } catch (Exception e) {
        System.out.println("Session Recovery Timeout error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("keepaliveInterval"))
          ls.connectionOptions.setKeepaliveInterval(Long.parseLong(call.<String>argument("keepaliveInterval")));
      } catch (Exception e) {
        System.out.println("Keepalive Interval error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("pollingInterval"))
          ls.connectionOptions.setPollingInterval(Long.parseLong(call.<String>argument("pollingInterval")));
      } catch (Exception e) {
        System.out.println("Polling Interval error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("reverseHeartbeatInterval"))
          ls.connectionOptions.setReverseHeartbeatInterval(Long.parseLong(call.<String>argument("reverseHeartbeatInterval")));
      } catch (Exception e) {
        System.out.println("Reverse Heartbeat Interval error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("maxBandwidth"))
          ls.connectionOptions.setRequestedMaxBandwidth(call.<String>argument("maxBandwidth"));
      } catch (Exception e) {
        System.out.println("Max Bandwidth error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("httpExtraHeaders")) {
          String s = call.<String>argument("httpExtraHeaders");
          s = s.substring( 1, s.length() - 1 );
          System.out.println("HTTP Extra Headers: " + s);
          Map<String, String> myMap = new HashMap<String, String>();
          String[] pairs = s.split(",");
          for (int i=0;i<pairs.length;i++) {
            String pair = pairs[i];
            String[] keyValue = pair.split(":");

            System.out.println("HTTP Extra Headers (" + i + "): " + keyValue[0] + " - " + keyValue[1]);

            myMap.put(keyValue[0].trim(), keyValue[1].trim());
          }

          ls.connectionOptions.setHttpExtraHeaders(myMap);
        }
      } catch (Exception e) {
        System.out.println("HTTP Extra Headers error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("httpExtraHeadersOnSessionCreationOnly"))
          ls.connectionOptions.setHttpExtraHeadersOnSessionCreationOnly(Boolean.parseBoolean(call.<String>argument("httpExtraHeadersOnSessionCreationOnly")));
      } catch (Exception e) {
        System.out.println("HTTP Extra Headers On Session Create Only error: " + e.getMessage());
      }

      try {
        if (call.hasArgument("proxy")) {
          String p = call.<String>argument("proxy");
          p = p.substring( 1, p.length() - 1 );
          System.out.println("Proxy: " + p);
          Map<String, String> myMap = new HashMap<String, String>();
          String[] ps = p.split(",");
          if (ps.length > 2) {
            Proxy proxy;

            if (ps.length > 4)
              proxy = new Proxy(ps[0].trim(), ps[1].trim(), Integer.parseInt(ps[2].trim()), ps[3].trim(), ps[4].trim());
            else if (ps.length > 3)
              proxy = new Proxy(ps[0].trim(), ps[1].trim(), Integer.parseInt(ps[2].trim()), ps[3].trim());
            else
              proxy = new Proxy(ps[0].trim(), ps[1].trim(), Integer.parseInt(ps[2].trim()));

            ls.connectionOptions.setProxy(proxy);
          } else {
            System.out.println("Proxy misconfigured.");
          }
        }
      } catch (Exception e) {
        System.out.println("Proxy error: " + e.getMessage());
      }

      ls.addListener(new MyClientListener(clientstatus_channel, "-1"));
      ls.connect();
      System.out.println("Try connect ... ");

      result.success(ls.getStatus());
    } else {
      System.out.println(" ... " + ls.getStatus());

      result.success(ls.getStatus());
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}

class LightstreamerBridge {
  final Map<String, LightstreamerClient> _clientMap = new HashMap<>();
  final Map<String, MyClientListener> _listenerMap = new HashMap<>();

  int _subIdGenerator = 0;
  final Map<String, Subscription> _subMap = new HashMap<>();
  final Map<String, MySubListener> _subListenerMap = new HashMap<>();

  int _mpnSubIdGenerator = 0;
  final Map<String, MpnSubscription> _mpnSubMap = new HashMap<>();
  final Map<String, MyMpnSubListener> _mpnSubListenerMap = new HashMap<>();

  final Map<String, MyClientMessageLisener> _msgListenerMap = new HashMap<>();

  boolean hasId(MethodCall call) {
    return call.hasArgument("id");
  }

  void connect(MethodCall call, Result  result, BasicMessageChannel<String> clientstatus_channel) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    if ( call.hasArgument("serverAddress") ) {
      System.out.println("serverAddress: " + call.<String>argument("serverAddress"));

      ls.connectionDetails.setServerAddress(call.<String>argument("serverAddress"));
    } else {
      System.out.println("No serverAddress passed. ");

      result.error("11", "No server address was configured", null);

      return ;
    }
    if ( call.hasArgument("adapterSet") ) {
      System.out.println("adapterSet: " + call.<String>argument("adapterSet"));

      ls.connectionDetails.setAdapterSet(call.<String>argument("adapterSet"));
    } else {
      System.out.println("No adapterSet passed. ");

      result.error("12", "No adapter set id was configured", null);

      return ;
    }

    if (!ls.getListeners().isEmpty()) {
      ls.removeListener(ls.getListeners().get(0));
    }

    if (call.hasArgument("user"))
      ls.connectionDetails.setUser(call.<String>argument("user"));

    if (call.hasArgument("password"))
      ls.connectionDetails.setPassword(call.<String>argument("password"));

    try {
      if (call.hasArgument("forcedTransport")) {
        ls.connectionOptions.setForcedTransport(call.<String>argument("forcedTransport"));
        System.out.println("Forced Transport: " + call.<String>argument("forcedTransport"));
      }
    } catch (Exception e) {
      System.out.println("Forced Transport error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("firstRetryMaxDelay"))
        ls.connectionOptions.setFirstRetryMaxDelay(Long.parseLong(call.<String>argument("firstRetryMaxDelay")));
    } catch (Exception e) {
      System.out.println("First Retry Max Delay error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("retryDelay"))
        ls.connectionOptions.setRetryDelay(Long.parseLong(call.<String>argument("retryDelay")));
    } catch (Exception e) {
      System.out.println("Retry Delay error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("idleTimeout"))
        ls.connectionOptions.setIdleTimeout(Long.parseLong(call.<String>argument("idleTimeout")));
    } catch (Exception e) {
      System.out.println("Idle Timeout error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("reconnectTimeout"))
        ls.connectionOptions.setReconnectTimeout(Long.parseLong(call.<String>argument("reconnectTimeout")));
    } catch (Exception e) {
      System.out.println("Reconnect Timeout error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("stalledTimeout"))
        ls.connectionOptions.setStalledTimeout(Long.parseLong(call.<String>argument("stalledTimeout")));
    } catch (Exception e) {
      System.out.println("Stalled Timeout error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("sessionRecoveryTimeout"))
        ls.connectionOptions.setSessionRecoveryTimeout(Long.parseLong(call.<String>argument("sessionRecoveryTimeout")));
    } catch (Exception e) {
      System.out.println("Session Recovery Timeout error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("keepaliveInterval"))
        ls.connectionOptions.setKeepaliveInterval(Long.parseLong(call.<String>argument("keepaliveInterval")));
    } catch (Exception e) {
      System.out.println("Keepalive Interval error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("pollingInterval"))
        ls.connectionOptions.setPollingInterval(Long.parseLong(call.<String>argument("pollingInterval")));
    } catch (Exception e) {
      System.out.println("Polling Interval error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("reverseHeartbeatInterval"))
        ls.connectionOptions.setReverseHeartbeatInterval(Long.parseLong(call.<String>argument("reverseHeartbeatInterval")));
    } catch (Exception e) {
      System.out.println("Reverse Heartbeat Interval error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("maxBandwidth"))
        ls.connectionOptions.setRequestedMaxBandwidth(call.<String>argument("maxBandwidth"));
    } catch (Exception e) {
      System.out.println("Max Bandwidth error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("httpExtraHeaders")) {
        String s = call.<String>argument("httpExtraHeaders");
        s = s.substring( 1, s.length() - 1 );
        System.out.println("HTTP Extra Headers: " + s);
        Map<String, String> myMap = new HashMap<String, String>();
        String[] pairs = s.split(",");
        for (int i=0;i<pairs.length;i++) {
          String pair = pairs[i];
          String[] keyValue = pair.split(":");

          System.out.println("HTTP Extra Headers (" + i + "): " + keyValue[0] + " - " + keyValue[1]);

          myMap.put(keyValue[0].trim(), keyValue[1].trim());
        }

        ls.connectionOptions.setHttpExtraHeaders(myMap);
      }
    } catch (Exception e) {
      System.out.println("HTTP Extra Headers error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("httpExtraHeadersOnSessionCreationOnly"))
        ls.connectionOptions.setHttpExtraHeadersOnSessionCreationOnly(Boolean.parseBoolean(call.<String>argument("httpExtraHeadersOnSessionCreationOnly")));
    } catch (Exception e) {
      System.out.println("HTTP Extra Headers On Session Create Only error: " + e.getMessage());
    }

    try {
      if (call.hasArgument("proxy")) {
        String p = call.<String>argument("proxy");
        p = p.substring( 1, p.length() - 1 );
        System.out.println("Proxy: " + p);
        Map<String, String> myMap = new HashMap<String, String>();
        String[] ps = p.split(",");
        if (ps.length > 2) {
          Proxy proxy;

          if (ps.length > 4)
            proxy = new Proxy(ps[0].trim(), ps[1].trim(), Integer.parseInt(ps[2].trim()), ps[3].trim(), ps[4].trim());
          else if (ps.length > 3)
            proxy = new Proxy(ps[0].trim(), ps[1].trim(), Integer.parseInt(ps[2].trim()), ps[3].trim());
          else
            proxy = new Proxy(ps[0].trim(), ps[1].trim(), Integer.parseInt(ps[2].trim()));

          ls.connectionOptions.setProxy(proxy);
        } else {
          System.out.println("Proxy misconfigured.");
        }
      }
    } catch (Exception e) {
      System.out.println("Proxy error: " + e.getMessage());
    }

    MyClientListener clientListener = _listenerMap.get(id);
    if (clientListener == null) {
      clientListener = new MyClientListener(clientstatus_channel, id);
      _listenerMap.put(id, clientListener);
      ls.addListener(clientListener);
    }
    ls.connect();

    result.success(ls.getStatus());
  }

  void disconnect(MethodCall call, Result result) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    ls.disconnect();
    _listenerMap.remove(id);

    result.success(ls.getStatus());
  }

  String getStatus(MethodCall call) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    return ls.getStatus();
  }

  LightstreamerClient getClient(String id) {
    LightstreamerClient ls = _clientMap.get(id);
    if (ls == null) {
      ls = new LightstreamerClient(null, null);
      _clientMap.put(id, ls);
    }
    return ls;
  }

  void subscribe(MethodCall call, Result result, BasicMessageChannel<String> subscribedata_channel) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    try {
      String mode = call.argument("mode");
      Subscription sub = new Subscription(mode);

      List<String> itemList = call.argument("itemList");
      if (itemList != null) {
        sub.setItems(itemList.toArray(new String[0]));
      }
      String itemGroup = call.argument("itemGroup");
      if (itemGroup != null) {
        sub.setItemGroup(itemGroup);
      }
      List<String> fieldList = call.argument("fieldList");
      if (fieldList != null) {
        sub.setFields(fieldList.toArray(new String[0]));
      }
      String fieldSchema = call.argument("fieldSchema");
      if (fieldSchema != null) {
        sub.setFieldSchema(fieldSchema);
      }

      if (call.hasArgument("dataAdapter"))
        sub.setDataAdapter(call.<String>argument("dataAdapter"));

      if (call.hasArgument("requestedSnapshot"))
        sub.setRequestedSnapshot(call.<String>argument("requestedSnapshot"));

      if (call.hasArgument("requestedBufferSize"))
        sub.setRequestedBufferSize(call.<String>argument("requestedBufferSize"));

      if (call.hasArgument("requestedMaxFrequency"))
        sub.setRequestedMaxFrequency(call.<String>argument("requestedMaxFrequency"));

      if (call.hasArgument("commandSecondLevelDataAdapter"))
        sub.setCommandSecondLevelDataAdapter(call.<String>argument("commandSecondLevelDataAdapter"));

      if ( call.hasArgument("commandSecondLevelFields") ) {
        String sfieldList = call.<String>argument("commandSecondLevelFields");
        sub.setCommandSecondLevelFields(sfieldList.split(","));
      }

      String subId = "subid_" + _subIdGenerator++;

      MySubListener subListener = new MySubListener(subscribedata_channel, subId, sub);
      _subMap.put(subId, sub);
      _subListenerMap.put(subId, subListener);

      sub.addListener(subListener);
      ls.subscribe(sub);

      result.success(subId);

    } catch (Exception ex) {
      result.error("61", ex.getMessage(), ex);
    }
  }

  void unsubscribe(MethodCall call, Result result) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    if ( call.hasArgument("sub_id") ) {
      String sub_id = call.<String>argument("sub_id");

      Subscription sub = _subMap.remove(sub_id);
      if (sub != null) {
        ls.unsubscribe(sub);
        _subListenerMap.remove(sub_id);
      }

      result.success("Ok");
    } else {

      result.error("5", "No Sub Id specified", null);
    }
  }

  void sendMessageExt(MethodCall call, Result result, BasicMessageChannel<String> messagestatus_channel) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    String msgId = call.argument("msg_id");

    if ( call.hasArgument("message") ) {
      int timeout = -1;
      String seq = null;
      boolean enq = false;
      boolean addListnr = false;

      if ( call.hasArgument("sequence") ) {
        seq = call.<String>argument("sequence");
      }
      if ( call.hasArgument("delayTimeout") ) {
        if (call.<Integer>argument("delayTimeout") != null) {
          timeout = call.<Integer>argument("delayTimeout").intValue();
        }

      }
      if ( call.hasArgument("enqueueWhileDisconnected") ) {
        if (call.<Integer>argument("enqueueWhileDisconnected") != null) {
          if (call.<Boolean>argument("enqueueWhileDisconnected").booleanValue()) {
            enq = true;
          }
        }
      }
      if ( call.hasArgument("listener") ) {
        if (call.<Integer>argument("listener") != null) {
          if (call.<Boolean>argument("listener").booleanValue()) {
            addListnr = true;
          }
        }
      }

      if (addListnr) {
        ls.sendMessage(call.<String>argument("message"), seq, timeout, new MyClientMessageLisener(messagestatus_channel, msgId), enq);
      } else {
        ls.sendMessage(call.<String>argument("message"), seq, timeout, null, enq);
      }

      result.success("OK");
    } else {

      result.error("9", "No message", null);
    }
  }

  void mpnSubscribe(MethodCall call, Result result, BasicMessageChannel<String> subscribedata_channel) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    if ( call.hasArgument("mode") ) {
      String mode = call.<String>argument("mode");
      System.out.println("mode: " + mode);
      if ( call.hasArgument("itemList") ) {
        ArrayList<String> itemList = call.<ArrayList<String>>argument("itemList");
        System.out.println("itemList: " + itemList);
        String[] itemArr = new String[itemList.size()];
        itemArr = itemList.toArray(itemArr);

        if ( call.hasArgument("fieldList") ) {
          String sub_id = "mpnsubid_" + _mpnSubIdGenerator++;

          ArrayList<String> fieldList = call.<ArrayList<String>>argument("fieldList");
          System.out.println("fieldList: " + fieldList);
          String[] fieldArr = new String[fieldList.size()];
          fieldArr = fieldList.toArray(fieldArr);

          MpnSubscription sub = new MpnSubscription(mode, itemArr, fieldArr);

          if (call.hasArgument("dataAdapter"))
            sub.setDataAdapter(call.<String>argument("dataAdapter"));

          if (call.hasArgument("requestedBufferSize"))
            sub.setRequestedBufferSize(call.<String>argument("requestedBufferSize"));

          if (call.hasArgument("requestedMaxFrequency"))
            sub.setRequestedMaxFrequency(call.<String>argument("requestedMaxFrequency"));

          if (call.hasArgument("notificationFormat"))
            sub.setNotificationFormat(call.<String>argument("notificationFormat"));

          if (call.hasArgument("triggerExpression"))
            sub.setTriggerExpression(call.<String>argument("triggerExpression"));

          MyMpnSubListener mpnListener = new MyMpnSubListener(subscribedata_channel, sub_id);
          _mpnSubMap.put(sub_id, sub);
          _mpnSubListenerMap.put(sub_id, mpnListener);

          sub.addListener(mpnListener);
          ls.subscribe(sub, true);

          result.success(sub_id);
        } else {
          result.error("1", "No Fields List specified", null);
        }
      } else {
        result.error("2", "No Items List specified", null);
      }
    } else {
      result.error("3", "No subscription mode specified", null);
    }
  }

  void mpnUnsubscribe(MethodCall call, Result result) {
    String id = call.argument("id");
    LightstreamerClient ls = getClient(id);

    if ( call.hasArgument("sub_id") ) {
      String sub_id = call.<String>argument("sub_id");

      MpnSubscription sub = _mpnSubMap.remove(sub_id);
      if (sub != null) {
        ls.unsubscribe(sub);
        _mpnSubListenerMap.remove(sub_id);
      }

      result.success("Ok");
    } else {
      result.error("4", "No Sub Id specified", null);
    }
  }
}