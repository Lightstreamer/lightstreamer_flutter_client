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

          result.error("1", "No server address was configured", null);

          return ;
        }
        if ( call.hasArgument("adapterSet") ) {
          System.out.println("adapterSet: " + call.<String>argument("adapterSet"));

          ls.connectionDetails.setAdapterSet(call.<String>argument("adapterSet"));
        } else {
          System.out.println("No adapterSet passed. ");

          result.error("2", "No adapter set id was configured", null);

          return ;
        }

        if (!ls.getListeners().isEmpty()) {
          ls.removeListener(ls.getListeners().get(0));
        }

        if (call.hasArgument("user"))
          ls.connectionDetails.setUser(call.<String>argument("user"));

        if (call.hasArgument("password"))
          ls.connectionDetails.setPassword(call.<String>argument("password"));

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

        result.error("3", "No message", null);

        return ;
      }
    } else if (call.method.equals("sendMessageExt")) {
      if ( call.hasArgument("message") ) {
        int timeout = 4000;
        String seq = "DEFAULT_SEQ1";
        boolean enq = false;

        System.out.println("message: " + call.<String>argument("message"));

        if ( call.hasArgument("sequence") ) {
          System.out.println("message: " + call.<String>argument("sequence"));

          seq = call.<String>argument("sequence");
        }
        if ( call.hasArgument("delayTimeout") ) {
          System.out.println("message: " + call.<Integer>argument("delayTimeout"));

          timeout = call.<Integer>argument("delayTimeout").intValue();
        }
        if ( call.hasArgument("enqueueWhileDisconnected") ) {
          System.out.println("message: " + call.<Boolean>argument("enqueueWhileDisconnected"));

          if ( call.<Boolean>argument("enqueueWhileDisconnected").booleanValue()) {
            enq = true;
          }
        }

        if (ls.getStatus().startsWith("CONNECTED:")) {
          ls.sendMessage(call.<String>argument("message"), seq, timeout, new MyClientMessageLisener(messagestatus_channel), enq);
        }
      } else {
        System.out.println("No message passed. ");

        result.error("3", "No message", null);

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
            result.error("000", "No Fields List specified", null);
          }
        } else {
          result.error("000", "No Items List specified", null);
        }
      } else {
        result.error("000", "No subscription mode specified", null);
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

        result.error("000", "No Items List specified", null);
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
            result.error("000", "No Fields List specified", null);
          }
        } else {
          result.error("000", "No Items List specified", null);
        }
      } else {
        result.error("000", "No subscription mode specified", null);
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

        result.error("000", "No Items List specified", null);
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
