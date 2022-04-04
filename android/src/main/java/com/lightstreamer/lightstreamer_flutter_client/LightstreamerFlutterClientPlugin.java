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

  private BasicMessageChannel<String> subscribedata_channel;

  private ConcurrentHashMap<String, Subscription> activeSubs = new ConcurrentHashMap<String, Subscription>();

  private static final LightstreamerClient ls = new LightstreamerClient("https://push.lightstreamer.com/", "WELCOME");

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "lightstreamer_flutter_client");
    channel.setMethodCallHandler(this);


    clientstatus_channel = new BasicMessageChannel<String>(
            flutterPluginBinding.getBinaryMessenger(), "com.lightstreamer.flutter.clientStatus_channel", StringCodec.INSTANCE);

    subscribedata_channel = new BasicMessageChannel<String>(
            flutterPluginBinding.getBinaryMessenger(), "com.lightstreamer.flutter.subscribedata_channel", StringCodec.INSTANCE);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    System.out.println("Method called: " + call.method);

    if (call.method.equals("connect")) {
      if (!ls.getStatus().startsWith("CONNECTED:")) {
        if ( call.hasArgument("serverAddress") ) {
          System.out.println("serverAddress: " + call.<String>argument("serverAddress"));

          ls.connectionDetails.setServerAddress(call.<String>argument("serverAddress"));
        }
        if ( call.hasArgument("adapterSet") ) {
          System.out.println("adapterSet: " + call.<String>argument("adapterSet"));

          ls.connectionDetails.setAdapterSet(call.<String>argument("adapterSet"));
        }

        if (!ls.getListeners().isEmpty()) {
          ls.removeListener(ls.getListeners().get(0));
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
      }
    }  else if (call.method.equals("subscribe")) {
      if ( call.hasArgument("mode") ) {
        String mode = call.<String>argument("mode");
        System.out.println("mode: " + mode);
        if ( call.hasArgument("itemList") ) {
          ArrayList<String> itemList = call.<ArrayList<String>>argument("itemList");
          System.out.println("itemList: " + itemList);
          String[] itemArr = new String[itemList.size()];
          itemArr = itemList.toArray(itemArr);

          if ( call.hasArgument("fieldList") ) {
            ArrayList<String> fieldList = call.<ArrayList<String>>argument("fieldList");
            System.out.println("fieldList: " + fieldList);
            String[] fieldArr = new String[fieldList.size()];
            fieldArr = fieldList.toArray(fieldArr);

            Subscription sub = new Subscription(mode, itemArr, fieldArr);
            if (call.hasArgument("dataAdapter"))
              sub.setDataAdapter(call.<String>argument("dataAdapter"));

            sub.addListener(new MySubListener(subscribedata_channel));

            ls.subscribe(sub);
            activeSubs.put(itemList.get(0), sub);
          }
        }

        result.success("Ok");
      }
    } else if (call.method.equals("getStatus")) {
      System.out.println(" get status:" + ls.getStatus());

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
