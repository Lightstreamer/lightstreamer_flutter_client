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
import com.lightstreamer.client.Subscription;
import com.lightstreamer.client.mpn.MpnSubscription;

import java.util.ArrayList;
import java.util.HashMap;
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
            System.out.println(" HTTP Extra Headers: " + s);
            Map<String, String> myMap = new HashMap<String, String>();
            String[] pairs = s.split(",");
            for (int i=0;i<pairs.length;i++) {
              String pair = pairs[i];
              String[] keyValue = pair.split(":");
              myMap.put(keyValue[0], keyValue[1]);
            }

            ls.connectionOptions.setHttpExtraHeaders(myMap);
          }
        } catch (Exception e) {
          System.out.println("HTTP Extra Headers error: " + e.getMessage());
        }

        ls.addListener(new MyClientListener(clientstatus_channel));
        ls.connect();
        System.out.println("Try connect ... ");

        result.success(ls.getStatus());
      } else {
        System.out.println(" ... " + ls.getStatus());

        result.success(ls.getStatus());
      }
    } else if (call.method.equals("disconnect")) {
      if (ls.getStatus().startsWith("CONNECTED:")) {
        ls.disconnect();

        result.success(ls.getStatus());
      } else {
        System.out.println(" ... " + ls.getStatus());

        result.success(ls.getStatus());
      }
    } else if (call.method.equals("sendMessage")) {
      if ( call.hasArgument("message") ) {
        System.out.println("message: " + call.<String>argument("message"));

        if (ls.getStatus().startsWith("CONNECTED:")) {
          ls.sendMessage(call.<String>argument("message"));
        }
      } else {
        System.out.println("No message passed. ");

        result.error("10", "No message", null);

        return ;
      }
    } else if (call.method.equals("sendMessageExt")) {
      if ( call.hasArgument("message") ) {
        int timeout = -1;
        String seq = "DEFAULT_FLUTTERPLUGIN_SEQUENCE";
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

        if (ls.getStatus().startsWith("CONNECTED:")) {
          if (addListnr) {
            ls.sendMessage(call.<String>argument("message"), seq, timeout, new MyClientMessageLisener(messagestatus_channel), enq);
          } else {
            ls.sendMessage(call.<String>argument("message"), seq, timeout, null, enq);
          }
        }
      } else {
        System.out.println("No message passed. ");

        result.error("9", "No message", null);

        return ;
      }
    } else if (call.method.equals("subscribe")) {
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

            Subscription sub = new Subscription(mode, itemArr, fieldArr);

            if (call.hasArgument("dataAdapter"))
              sub.setDataAdapter(call.<String>argument("dataAdapter"));

            if (call.hasArgument("requestedSnapshot"))
              sub.setRequestedSnapshot(call.<String>argument("requestedSnapshot"));

            if (call.hasArgument("requestedBufferSize"))
              sub.setRequestedBufferSize(call.<String>argument("requestedBufferSize"));

            if (call.hasArgument("requestedMaxFrequency"))
              sub.setRequestedMaxFrequency(call.<String>argument("requestedMaxFrequency"));

            sub.addListener(new MySubListener(subscribedata_channel,sub_id));

            ls.subscribe(sub);

            activeSubs.put(sub_id, sub);

            result.success(sub_id);
          } else {
            result.error("6", "No Fields List specified", null);
          }
        } else {
          result.error("7", "No Items List specified", null);
        }
      } else {
        result.error("8", "No subscription mode specified", null);
      }
    } else if (call.method.equals("unsubscribe")) {
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
    } else if (call.method.equals("mpnSubscribe")) {
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
    } else if (call.method.equals("mpnUnsubscribe")) {
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
    } else if (call.method.equals("getStatus")) {
      System.out.println("Get Status:" + ls.getStatus());

      result.success(ls.getStatus());
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
