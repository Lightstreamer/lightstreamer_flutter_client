# Lightstreamer Flutter Plugin

The Lightstreamer Flutter Plugin enables any mobile (Android or iOS) or Web application to communicate bidirectionally with the Lightstreamer Server. The fully asynchronous API allows to subscribe to real-time data delivered directly by the server or routed via mobile push notifications, and to send any message to the server.

The library offers automatic recovery from connection failures, automatic selection of the best available transport, and full decoupling of subscription and connection operations.

The library also offers support for mobile push notifications (MPN). While real-time subscriptions deliver their updates via the client connection, MPN subscriptions deliver their updates via push notifications, even when the application is offline. They are handled by a special module of the Server, the MPN Module, that keeps them active at all times and continues pushing with no need for a client connection. However, push notifications are not real-time, they may be delayed by the service provider (Google Firebase or Apple APNs) and their delivery is not guaranteed.

## Installation

In the `dependencies:` section of your `pubspec.yaml`, add the following line:

```yaml
dependencies:
  lightstreamer_flutter_client: 2.0.0
```

## ⚠ Differences Between Mobile and Web Libraries ⚠

The `lightstreamer_flutter_client` package comprises two libraries: `lightstreamer_client.dart` for Android and iOS targets and `lightstreamer_client_web.dart` for Web target.

These libraries are very similar, as they expose the same classes and methods. This means an application using the mobile library is almost source-code compatible with the same application using the web library. However, there are a few differences to keep in mind when writing apps that should work both on mobile and web devices.

1. **Object lifespan** When using the mobile library, references to the `LightstreamerClient`, `Subscription`, `MpnDevice` and `MpnSubscription` instances _**must be maintained by the Flutter app for as long as these objects are in use**_. Failing to do so may result in the loss of events directed to these objects (e.g. listener notifications).

    ```dart
    // DO
    class MyClient {
      final client = LightstreamerClient("host", "adapter");
      void connect() async {
        client.addListener(MyClientListener());
        await client.connect();
      }
    }

    // DO NOT
    class MyClient {
      void connect() async {
        var client = LightstreamerClient("host", "adapter");
        client.addListener(MyClientListener());
        await client.connect();
      }
    }
    ```

    The web library does not require such precautions.

2. **Async Methods** In the mobile library, most methods of the `LightstreamerClient` class (e.g. `connect`, `subscribe`, etc.) return a `Future`, whereas the corresponding methods of the web library return `void` or simple values.

    For example, in the web library, a client establishes a session as follows:

    ```dart
    var client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
    client.connect();
    ```

    The equivalent code for the mobile library is:

    ```dart
    var client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
    await client.connect();
    ```

    While the `await` command before the connection is optional in this case, it is recommended to include it to catch exceptions.

3. **Exception Types** The web library throws exceptions such as `IllegalArgumentException` or `IllegalStateException`, while the mobile library only throws `PlatformException`.

4. **Exception Timing** The web library methods throw exceptions as soon as they detect an invalid condition, whereas the mobile library checks these conditions only during a few fundamental methods such as `connect`, `subscribe`, etc.
However, both libraries document the thrown exceptions when discussing the methods to which the exceptions logically belong.

5. **Precondition Failures on iOS** Since the mobile library leverages the [Lightstreamer iOS Client SDK](https://github.com/Lightstreamer/Lightstreamer-lib-client-swift) to support the iOS target, and the iOS Client SDK uses Swift [preconditions](https://developer.apple.com/documentation/swift/precondition(_:_:file:line:)) to validate method arguments, a failed precondition will abruptly stop the program execution when a Flutter app runs on an iOS device. However, in the same circumstances, both the web library and the Android library will throw an `IllegalArgumentException`.

## Getting Started (Android/iOS)

### Import the package

```dart
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
```

### Configure and start a session

To connect to a Lightstreamer Server, a `LightstreamerClient` object has to be created, configured, and instructed to connect to a specified endpoint. 

A minimal version of the code that creates a LightstreamerClient and connects to the Lightstreamer Server at `https://push.lightstreamer.com` will look like this:

```dart
var client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
await client.connect();
```

For each subscription to be subscribed to a Lightstreamer Server a `Subscription` instance is needed.

A simple Subscription containing three items and two fields to be subscribed in *MERGE* mode is easily created (see [Lightstreamer General Concepts](https://www.lightstreamer.com/docs/ls-server/latest/General%20Concepts.pdf)):
```dart
var items  = [ "item1","item2","item3" ];
var fields = [ "stock_name","last_price" ];
var sub = Subscription("MERGE", items, fields);
sub.setDataAdapter("QUOTE_ADAPTER");
sub.setRequestedSnapshot("yes");
await client.subscribe(sub);
```

Before sending the subscription to the server, usually at least one `SubscriptionListener` is attached to the Subscription instance in order to consume the real-time updates. 

The following code shows the values of the fields *stock_name* and *last_price* each time a new update is received for the subscription:

```dart
sub.addListener(MySubscriptionListener());

class MySubscriptionListener extends SubscriptionListener {
  void onItemUpdate(ItemUpdate update) {
    print("UPDATE " + update.getValue("stock_name") + " " + update.getValue("last_price"));
  }
}
```

Below is the complete Dart code:

```dart
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

void main() async {
  var client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
  await client.connect();

  var items  = [ "item1","item2","item3" ];
  var fields = [ "stock_name","last_price" ];
  var sub = Subscription("MERGE", items, fields);
  sub.setDataAdapter("QUOTE_ADAPTER");
  sub.setRequestedSnapshot("yes");
  sub.addListener(MySubscriptionListener());
  await client.subscribe(sub);

  await Future.delayed(const Duration(seconds: 5));
}

class MySubscriptionListener extends SubscriptionListener {
  void onItemUpdate(ItemUpdate update) {
    print("UPDATE ${update.getValue("stock_name")} ${update.getValue("last_price")}");
  }
}
```

### Sending messages

The client can also send messages to the Server:

```dart
await client.sendMessage("Hello world");
```

The code below shows an implementation for a message listener:

```dart
await client.sendMessage("Hello world again", "sequence1", 5000, MyMessageListener(), true);

class MyMessageListener extends ClientMessageListener {
  void onProcessed(String originalMessage, String response) {
    print("PROCESSED $originalMessage");
  }
}
```

A full running example app is included in the project under the `example` folder.

### Logging

To enable the internal client logger, create a `LoggerProvider` and set it as the default provider of `LightstreamerClient`.

```dart
var provider = ConsoleLoggerProvider(ConsoleLogLevel.DEBUG);
await LightstreamerClient.setLoggerProvider(provider);
```

### Mobile Push Notifications

The library offers support for Push Notifications on Apple platforms through **Apple Push Notification Service (APNs)** and Google platforms through **Firebase Cloud Messaging (FCM)**. With Push Notifications, subscriptions deliver their updates through push notifications even when the application is offline.

#### Firebase configuration

1. Before you can add Firebase to your Android app, you need to create a [Firebase project](https://firebase.google.com/docs/projects/learn-more) to connect to your Android app.

2. From the [Firebase console](https://console.firebase.google.com/), download the `google-services.json` configuration file and move it into the **module (app-level)** root directory of your app.

3. In your **root-level (project-level)** Gradle file (`<project>/build.gradle`), add the Google services plugin as a dependency:

    ```gradle
    plugins {
      id 'com.android.application' version '7.3.0' apply false
      // ...

      // Add the dependency for the Google services Gradle plugin
      id 'com.google.gms.google-services' version '4.4.2' apply false
    }
    ```

4. In your **module (app-level)** Gradle file (`<project>/<app-module>/build.gradle`), add the Google services plugin:

    ```gradle
    plugins {
      id 'com.android.application'

      // Add the Google services Gradle plugin
      id 'com.google.gms.google-services'
      // ...
    }
    ```

5. In your **module (app-level)** Gradle file (`<project>/<app-module>/build.gradle`), add the dependencies for the Firebase messaging.

    ```gradle
    dependencies {
      // ...

      // Import the Firebase BoM
      implementation(platform("com.google.firebase:firebase-bom:33.5.0"))

      // When using the BoM, you don't specify versions in Firebase library dependencies

      implementation 'com.google.firebase:firebase-messaging'
    }
    ```

6. Make sure that the `applicationId` field in the **module (app-level)** Gradle file (`<project>/<app-module>/build.gradle`) has the same value as the `package_name` field in the `google-services.json` file.

For further information, see the [Firebase documentation](https://firebase.google.com/docs/android/setup).

#### APNs configuration

1. In your [Developer Account](https://developer.apple.com/account/), enable the push notification service for the App ID assigned to your project.

2. In xcode, open the `xcworkspace` file from your Flutter project.

3. In the Project navigator, click the `Runner` project and then select the `Runner` target.

4. Click *Signing & Capabilities* and add the *Push Notification* and *Background Modes > Remote Notifications* capabilities. 

For further information, see the [APNs documentation](https://developer.apple.com/documentation/usernotifications).

#### Subscribe to Push Notifications

Before you can use MPN services, you need to configure the Lightstreamer MPN module (read carefully the section  `Mobile and Web Push Notifications` in the [General Concepts guide](https://lightstreamer.com/distros/ls-server/7.4.5/docs/General%20Concepts.pdf)).

Then you can create a `MpnDevice`, which represents a specific app running on a specific mobile device.

```dart
var device = MpnDevice();
await client.registerForMpn(device);
```

To receive notifications, you need to subscribe to a `MpnSubscription`: it contains subscription details and the listener needed to monitor its status.

```dart
var items = [ "item1","item2","item3" ];
var fields = [ "stock_name","last_price","time" ];
var sub = MpnSubscription("MERGE", items, fields);
var data = {
  "stock_name": "\${stock_name}",
  "last_price": "\${last_price}",
  "time": "\${time}",
  "item": "item1" };
var format = FirebaseMpnBuilder().setData(data).build();
sub.setNotificationFormat(format);
sub.setTriggerExpression("Double.parseDouble(\$[2])>45.0");
await client.subscribe(sub, true);
```

The notification format lets you specify how to format the notification message. It can contain a special syntax that lets you compose the message with the content of the subscription updates 
(see the `FirebaseMpnBuilder` and `ApnsMpnBuilder` classes).

The optional  trigger expression  lets you specify  when to send  the notification message: it is a boolean expression, in Java language, that when evaluates to true triggers the sending of the notification. If not specified, a notification is sent each time the Data Adapter produces an update.

For more information, see the `Mobile and Web Push Notifications` chapter in the [General Concepts Guide](https://lightstreamer.com/distros/ls-server/7.4.5/docs/General%20Concepts.pdf).

## Getting Started (Web)

### Import the package

- Get the [Lightstreamer Client Web SDK](https://www.npmjs.com/package/lightstreamer-client-web)

- Copy the file `lightstreamer-core.min.js` (or the file `lightstreamer-mpn.min.js` if you need the Web Push Notifications, see below) in the `web` folder of your Flutter app

- Put the following line in the `<head>` section of the file `index.html` just before every other `<script>` element:

    ```html
    <script src="lightstreamer-core.min.js" data-lightstreamer-ns="lightstreamer"></script>
    ```

    (or the following line if you need the Web Push Notifications)

    ```html
    <script src="lightstreamer-mpn.min.js" data-lightstreamer-ns="lightstreamer"></script>
    ```

- Add the following import to your app:

    ```dart
    import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';
    ```

### Configure and start a session

To connect to a Lightstreamer Server, a `LightstreamerClient` object has to be created, configured, and instructed to connect to a specified endpoint. 

A minimal version of the code that creates a LightstreamerClient and connects to the Lightstreamer Server at `https://push.lightstreamer.com` will look like this:

```dart
var client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
client.connect();
```

For each subscription to be subscribed to a Lightstreamer Server a `Subscription` instance is needed.

A simple Subscription containing three items and two fields to be subscribed in *MERGE* mode is easily created (see [Lightstreamer General Concepts](https://www.lightstreamer.com/docs/ls-server/latest/General%20Concepts.pdf)):
```dart
var items  = [ "item1","item2","item3" ];
var fields = [ "stock_name","last_price" ];
var sub = Subscription("MERGE", items, fields);
sub.setDataAdapter("QUOTE_ADAPTER");
sub.setRequestedSnapshot("yes");
client.subscribe(sub);
```

Before sending the subscription to the server, usually at least one `SubscriptionListener` is attached to the Subscription instance in order to consume the real-time updates. 

The following code shows the values of the fields *stock_name* and *last_price* each time a new update is received for the subscription:

```dart
sub.addListener(MySubscriptionListener());

class MySubscriptionListener extends SubscriptionListener {
  void onItemUpdate(ItemUpdate update) {
    print("UPDATE " + update.getValue("stock_name") + " " + update.getValue("last_price"));
  }
}
```

Below is the complete Dart code:

```dart
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

void main() async {
  var client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
  client.connect();

  var items  = [ "item1","item2","item3" ];
  var fields = [ "stock_name","last_price" ];
  var sub = Subscription("MERGE", items, fields);
  sub.setDataAdapter("QUOTE_ADAPTER");
  sub.setRequestedSnapshot("yes");
  sub.addListener(MySubscriptionListener());
  client.subscribe(sub);

  await Future.delayed(const Duration(seconds: 5));
}

class MySubscriptionListener extends SubscriptionListener {
  void onItemUpdate(ItemUpdate update) {
    print("UPDATE ${update.getValue("stock_name")} ${update.getValue("last_price")}");
  }
}
```

### Sending messages

The client can also send messages to the Server:

```dart
client.sendMessage("Hello world");
```

The code below shows an implementation for a message listener:

```dart
client.sendMessage("Hello world again", "sequence1", 5000, MyMessageListener(), true);

class MyMessageListener extends ClientMessageListener {
  void onProcessed(String originalMessage, String response) {
    print("PROCESSED $originalMessage");
  }
}
```

A full running example app is included in the project under the `example` folder.

### Logging

To enable the internal client logger, create a `LoggerProvider` and set it as the default provider of `LightstreamerClient`.

```dart
var provider = ConsoleLoggerProvider(ConsoleLogLevel.DEBUG);
LightstreamerClient.setLoggerProvider(provider);
```

### Web Push Notifications

The library offers support for Web Push Notifications on Apple platforms through **Apple Push Notification Service (APNs)** and Google platforms through **Firebase Cloud Messaging (FCM)**. With Web Push, subscriptions deliver their updates through push notifications even when the application is offline.

Before you can use MPN services, you need to configure the Lightstreamer MPN module (read carefully the section  `Mobile and Web Push Notifications` in the [General Concepts guide](https://lightstreamer.com/distros/ls-server/7.4.5/docs/General%20Concepts.pdf)).

To receive notifications, you need to subscribe to a `MpnSubscription`: it contains subscription details and the listener needed to monitor its status.

```dart
var items = [ "item1","item2","item3" ];
var fields = [ "stock_name","last_price","time" ];
var sub = MpnSubscription("MERGE", items, fields);
var data = {
  "stock_name": "\${stock_name}",
  "last_price": "\${last_price}",
  "time": "\${time}",
  "item": "item1" };
var format = FirebaseMpnBuilder().setData(data).build();
sub.setNotificationFormat(format);
sub.setTriggerExpression("Double.parseDouble(\$[2])>45.0");
client.subscribe(sub, true);
```

The notification format lets you specify how to format the notification message. It can contain a special syntax that lets you compose the message with the content of the subscription updates 
(see the `FirebaseMpnBuilder` and `SafariMpnBuilder` classes).

The optional  trigger expression  lets you specify  when to send  the notification message: it is a boolean expression, in Java language, that when evaluates to true triggers the sending of the notification. If not specified, a notification is sent each time the Data Adapter produces an update.

For more information, see the `Mobile and Web Push Notifications` chapter in the [General Concepts Guide](https://lightstreamer.com/distros/ls-server/7.4.5/docs/General%20Concepts.pdf) and the
the [Firebase Cloud Messaging docs](https://firebase.google.com/docs/cloud-messaging/flutter/client).

## See Also

 - [Lightstreamer Flutter Plugin](https://pub.dev/packages/lightstreamer_flutter_client)
 - [Lightstreamer Flutter Stock-List Demo](https://github.com/Lightstreamer/Lightstreamer-example-StockList-client-flutter)
 - [Lightstreamer Flutter Project](https://github.com/Lightstreamer/lightstreamer_flutter_client/tree/2.0.0)
 - [Flutter Mobile API Client Reference](https://lightstreamer.com/sdks/ls-flutter-client/2.0.0/api/lightstreamer_client/lightstreamer_client-library.html)
 - [Flutter Web API Client Reference](https://lightstreamer.com/sdks/ls-flutter-client/2.0.0/api/lightstreamer_client_web/lightstreamer_client_web-library.html)
 - [Lightstreamer Documentation](https://lightstreamer.com/docs)

## Compatibility

* The Plugin requires Lightstreamer Server 7.4.0 or later
* On Android devices, Android 8 (API 26) or later is required.
* On iOS devices, iOS 12.0 or later is required.
