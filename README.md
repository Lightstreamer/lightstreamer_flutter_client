# Lightstreamer Flutter Plugin

A [Flutter](https://flutter.dev/) plugin for [Lightstreamer](https://lightstreamer.com/) addressing Android, iOS and Web platforms.

## Android and iOS platforms

The mobile plugin is basically a bridge linking Dart code and the Lightstreamer [Android](https://github.com/Lightstreamer/Lightstreamer-lib-client-haxe) and [Swift](https://github.com/Lightstreamer/Lightstreamer-lib-client-swift) Client SDKs.
Messages are passed between the Dart application (UI) and host (platform) using platform channels; in particular one MethodChannel and three BasicMessageChannel. The MethodChannel is used to request actions prompted by the UI iteration such as opening and closing the connection with the Lightstreamer server and subscribing and unsubscribing particular Items.

 - The `com.lightstreamer.lightstreamer_flutter_client.status` BasicMessageChannel is used to send real-time updates to the application about the status of the connection with the Lightstreamer server.
 - The `com.lightstreamer.lightstreamer_flutter_client.realtime` BasicMessageChannel is used to send real-time updates about the Items the application is subscribed to.
 - The `com.lightstreamer.lightstreamer_flutter_client.messages` BasicMessageChannel is used to send feedback on the status of send message operation requested by the application.

 ## Web platform

 The web plugin is a wrapper that forwards its calls to the [Lightstreamer Web Client SDK](https://github.com/Lightstreamer/Lightstreamer-lib-client-haxe).

## Getting Started (mobile platforms)

#### Import the package

```dart
import 'package:lightstreamer_flutter_client/lightstreamer_flutter_client.dart';
```

#### Configure and Start a Lightstreamer Client Session

To connect to a Lightstreamer Server a LightstreamerClient object has to be created, configured, and instructed to connect to a specified endpoint. The platform-specific implementation will take care of this when it receives a 'connect' command on the specific MethodChannel. A minimal version of the code which through the 'connect' command connect to the public Lightstreamer Demo Server (on https://push.lightstreamer.com) will look like this:

```dart
    String currentStatus;

    try {
      Map<String, String> params = {"user": "prova1", 
             "password": "qwerty!"};

      currentStatus = await LightstreamerFlutterClient.connect(
              "https://push.lightstreamer.com/", "WELCOME", params) ??
          'Unknown client session status';
    } on PlatformException catch (e) {
      currentStatus =
          "Problems in starting a session with Lightstreamer: '${e.message}' .";
    }

    setState(() {
      _status = currentStatus;
    });
```
The below code allow the application to listen for any real-time connection state change events:

```dart
    LightstreamerFlutterClient.setClientListener(_clientStatus);

    void _clientStatus(String msg) {
    setState(() {
      _status = msg;
    });
  }
```

#### Receive Real-Time Updates

In order to receive real-time updates from the Lightstreamer server the client needs to subscribe to specific Items handled by a Data Adapter deployed at the server-side. This can be accomplished by instantiating an object of type Subscription. For more details about Subscription in Lightstreamer see the section 3.2 of the [Lightstreamer General Concepts](https://lightstreamer.com/docs/ls-server/latest/General%20Concepts.pdf) documentation. A sample of code that subscribes three Items of the classic Stock-List example is:

```dart
    String static_sub_id = "";

    String? subId = "";
    try {
      Map<String, String> params = {
        "dataAdapter": "STOCKS",
        "requestedMaxFrequency": "7",
        "requestedSnapshot": "yes"
      };
      subId = await LightstreamerFlutterClient.subscribe(
          "MERGE",
          itemList: "item2,item7,item8".split(","),
          fieldList: "last_price,time,stock_name".split(","),
          parameters: params);

      static_sub_id = subId as String;

      LightstreamerFlutterClient.setSubscriptionListener(subId, _values);
    } on PlatformException catch (e) {
      // ...
    }
```

The below code shows an example of implementation of the callback to listen for any real-time updates from your subscriptions:

```dart
  void _values(String item, String fieldName, String fieldValue) {
    setState(() {
      _lastUpdate = item + "," + fieldName + "," + fieldValue;
      highlightcolorLast = Colors.yellow;
    });
  }
```

This code allow to unsubscribing from receiving messages for the previous subscription:

```dart
    try {
      await LightstreamerFlutterClient.unsubscribe(static_sub_id);
    } on PlatformException catch (e) {
      // ...
    }
```

#### Send Client Messages to the Server

The client can also send messages to the server:

```dart
    try {
      await LightstreamerFlutterClient.sendMessageExt(
           "Hello World", "Sequence1", 5000, _clientmessages, true);
    } on PlatformException catch (e) {
      // ...
    }
```

The below code shows an example of implementation of the callback to listen for send message feedback:

```dart
    void _clientmessages(String msg) {
        setState(() {
            _status = msg;
        });
    }
```
A full running example app is included in the project under `example` folder.

## Getting Started (Web platform)

### Import the package

- Get the [Lightstreamer Client Web SDK](https://www.npmjs.com/package/lightstreamer-client-web)

- Copy the file `lightstreamer-core.min.js` (or the file `lightstreamer-mpn.min.js` if you need the Web Push Notifications, see below) in the `web` folder of your Flutter app, 

- Put the following line in the `<head>` section of the file `index.html` just before every other `<script>` element:

```html
<script src="lightstreamer-core.min.js" data-lightstreamer-ns="lightstreamer"></script>
```

or the following line if you need the Web Push Notifications

```html
<script src="lightstreamer-mpn.min.js" data-lightstreamer-ns="lightstreamer"></script>
```

- Add the following import to your app:

```dart
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';
```

### Configure and Start a Lightstreamer Client Session

To connect to a Lightstreamer Server, a `LightstreamerClient` object has to be created, configured, and instructed to connect to the Lightstreamer Server. 
A minimal version of the code that creates a LightstreamerClient and connects to the Lightstreamer Server on *https://push.lightstreamer.com* will look like this:

```dart
var client = new LightstreamerClient("https://push.lightstreamer.com/","DEMO");
client.connect();
```

For each subscription to be subscribed to a Lightstreamer Server a `Subscription` instance is needed.
A simple Subscription containing three items and two fields to be subscribed in *MERGE* mode is easily created:

```dart
var sub = new Subscription("MERGE",["item1","item2","item3"],["stock_name","last_price"]);
sub.setDataAdapter("QUOTE_ADAPTER");
sub.setRequestedSnapshot("yes");
client.subscribe(sub);
```

Before sending the subscription to the server, usually at least one `SubscriptionListener` is attached to the Subscription instance in order to consume the real-time updates. The following code shows the values of the fields *stock_name* and *last_price* each time a new update is received for the subscription:

```dart
class MySubscriptionListener extends SubscriptionListener {
  void onItemUpdate(ItemUpdate obj) {
    print('${obj.getValue("stock_name")}: ${obj.getValue("last_price")}');
  }
}
sub.addListener(new MySubscriptionListener());
```

### Logging

To enable the internal client logger, create a `LoggerProvider` and set it as the default provider of `LightstreamerClient`.

```dart
var loggerProvider = new ConsoleLoggerProvider(ConsoleLogLevel.DEBUG);
LightstreamerClient.setLoggerProvider(loggerProvider);
```

### Web Push Notifications

The library offers support for Web Push Notifications on Apple platforms via **Apple Push Notification Service (APNs)** and Google platforms  via  **Firebase Cloud Messaging (FCM)**. With Web Push, subscriptions deliver their updates via push notifications even when the application is offline.

To receive notifications, you need to subscribe to a `MpnSubscription`: it contains subscription details and the listener needed to monitor its status. Real-time data is routed via native push notifications.

```dart
var items = [ "item1","item2","item3" ];
var fields = [ "stock_name","last_price","time" ];
var sub = new MpnSubscription("MERGE",items,fields);
var data = {
  "stock_name": "\${stock_name}",
  "last_price": "\${last_price}",
  "time": "\${time}",
  "item": "item1" };
String format = new MpnBuilder().data(data).build();
sub.setNotificationFormat(format);
sub.setTriggerExpression("Double.parseDouble(\$[2])>45.0");
client.subscribe(sub, true);
```

The notification format lets you specify how to format the notification message. It can contain a special syntax that lets you compose the message with the content of the subscription updates (see §5.4.1 of the [General Concepts guide](https://lightstreamer.com/docs/ls-server/7.1.1/General%20Concepts.pdf)).

The optional  trigger expression  lets you specify  when to send  the notification message: it is a boolean expression, in Java language, that when evaluates to true triggers the sending of the notification (see §5.4.2 of the [General Concepts guide](https://lightstreamer.com/docs/ls-server/7.1.1/General%20Concepts.pdf)). If not specified, a notification is sent each time the Data Adapter produces an update.

For more information see the [Firebase Cloud Messaging docs](https://firebase.google.com/docs/cloud-messaging/flutter/client).

## External Documentations

 - Package home: [pub.dev/packages/lightstreamer_flutter_client](https://pub.dev/packages/lightstreamer_flutter_client)
 - Check out [this demo](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-flutter) showing the integration between Lightstreamer and Flutter App Development Toolkit. In particular the demo shows how to use the lightstreamer_flutter_client plugin package.
 - For help getting started with Lightstreamer, view the [online documentation](https://lightstreamer.com/doc).
 - In particular refer to the [Android API Client Reference](https://www.lightstreamer.com/api/ls-android-client/latest/), the [Swift API Client Reference](https://www.lightstreamer.com/api/ls-swift-client/latest/) or the [Web API Client Reference](https://www.lightstreamer.com/api/ls-web-client/latest/).

## Compatibility

The Plugin requires Lightstreamer Server 7.4.0 or later
