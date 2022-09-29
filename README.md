# Lightstreamer Flutter Plugin

A [Flutter](https://flutter.dev/) plugin for [Lightstreamer](https://lightstreamer.com/), built on top of [Android Client SDK](https://github.com/Lightstreamer/Lightstreamer-lib-client-java)
and of [Swift Client SDK](https://github.com/Lightstreamer/Lightstreamer-lib-client-swift).

## Target Android and iOS Platform

The Plugin is basically a bridge linking Dart code and native code for Android and iOS platforms.
Messages are passed between the Dart application (UI) and host (platform) using platform channels; in particular one MethodChannel and three BasicMessageChannel. The MethodChannel is used to request actions prompted by the UI iteration such as opening and closing the connection with the Lightstreamer server and subscribing and unsubscribing particular Items.

 - The `com.lightstreamer.lightstreamer_flutter_client.status` BasicMessageChannel is used to send real-time updates to the application about the status of the connection with the Lightstreamer server.
 - The `com.lightstreamer.lightstreamer_flutter_client.realtime` BasicMessageChannel is used to send real-time updates about the Items the application is subscribed to.
 - The `com.lightstreamer.lightstreamer_flutter_client.messages` BasicMessageChannel is used to send feedback on the status of send message operation requested by the application.

## Getting Started

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
          "item2,item7,item8".split(","),
          "last_price,time,stock_name".split(","),
          params);

      static_sub_id = subId as String;

      LightstreamerFlutterClient.setSubscriptionListener(subId, _values);
    } on PlatformException catch (e) {
      // ...
    }
```

The below code shows an example of implementation of the callback to listen for any real-time updates from your subcriptions:

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

## External Documentations

 - Package home: [pub.dev/packages/lightstreamer_flutter_client](https://pub.dev/packages/lightstreamer_flutter_client)
 - To add a package plugin to your Flutter project see: [Adding a package dependency to an app](https://flutter.dev/docs/development/packages-and-plugins/using-packages#adding-a-package-dependency-to-an-app)
 - Check out [this demo](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-flutter) showing the integration between Lightstreamer and Flutter App Development Toolkit. In particular the demo shows how to use the lightstreamer_flutter_client plugin package.
 - For help getting started with Flutter, view
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
 - For help getting started with Lightstreamer, view
[online documentation](https://lightstreamer.com/doc)
 - In particular refer to the [Android API Client Reference](https://www.lightstreamer.com/api/ls-android-client/latest/) or to the [Swift API Client Reference](https://www.lightstreamer.com/api/ls-swift-client/latest/).

