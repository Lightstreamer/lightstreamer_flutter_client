import 'package:flutter/material.dart';
/*
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
*/
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

late final String fcmToken;

void main() async {
  // TODO complete firebase configuration
  /*
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  fcmToken = (await FirebaseMessaging.instance.getToken(vapidKey: "BGxHjswNaj-9T1cur3TJuyUCgL9yudMZDDcEV43zpSxnZDvS7KbqnwAGSRz9zWbqySTa0Oij-i29xxRWEF0WtA8"))!;

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  */

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyClientListener extends ClientListener {
  void onStatusChange(status) {
    print(status);
  }
}

class _MyMsgListener extends ClientMessageListener {
  void onProcessed(String originalMessage, String response) {
    print('onProcessed $originalMessage $response');
  }
}

class _MySubListener extends SubscriptionListener {
  void onItemUpdate(ItemUpdate u) {
    print('${u.getValue("last_price")}|${u.getValue("time")}|${u.getValue("stock_name")}');
  }
}

class _MyHomePageState extends State<MyHomePage> {
  LightstreamerClient _client;
  Subscription? _sub = null;
  MpnSubscription? _mpnSub = null;
  late final MpnDevice _device;

  _MyHomePageState() : _client = new LightstreamerClient("https://push.lightstreamer.com", "DEMO") {
    LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.INFO));

    var listener = new _MyClientListener();
    _client.addListener(listener);
    _device = new MpnDevice(fcmToken, "com.lightstreamer.push_demo.android.fcm", "Google");
  }

  void _start() {
    _client.connect();
  }

  void _stop() {
    _client.disconnect();
  }

  void _send() {
    _client.sendMessage('hello world', null, -1, new _MyMsgListener());
  }

  void _subscribe() {
    if (_sub == null) {
      _sub = new Subscription("MERGE", ["item2"], ["last_price", "time", "stock_name"]);
      var sub = _sub!;
      sub.setDataAdapter("QUOTE_ADAPTER");
      sub.addListener(new _MySubListener());
      _client.subscribe(sub);
    }
  }

  void _unsubscribe() {
    if (_sub != null) {
      var sub = _sub!;
      sub.removeListener(sub.getListeners()[0]);
      _client.unsubscribe(sub);
      _sub = null;
    }
  }

  void _register() {
    _client.registerForMpn(_device);
  }

  void _subscribeMpn() {
    if (_mpnSub == null) {
      var item = "item2";
      var builder = new FirebaseMpnBuilder();
      builder.setData({
        "item": item,
        "stockName": "\${stock_name}",
        "lastPrice": "\${last_price}"
      });
      var notificationFormat = builder.build();
      var sub = new MpnSubscription("MERGE", [item], ["stock_name", "last_price"]);
      sub.setNotificationFormat(notificationFormat);
      sub.setDataAdapter("QUOTE_ADAPTER");
      _client.subscribeMpn(sub, true);
      _mpnSub = sub;
    }
  }

  void _unsubscribeMpn() {
    if (_mpnSub != null) {
      var sub = _mpnSub!;
      _client.unsubscribeMpn(sub);
      _mpnSub = null;
    }
  }

  void _unsubscribeAllMpn() {
    _client.unsubscribeMpnSubscriptions("ALL");
    _mpnSub = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Web App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _start,
                  child: Text('Connect'),
                ),
                ElevatedButton(
                  onPressed: _stop,
                  child: Text('Disconnect'),
                ),
                ElevatedButton(
                  onPressed: _subscribe,
                  child: Text('Subscribe'),
                ),
                ElevatedButton(
                  onPressed: _unsubscribe,
                  child: Text('Unsubscribe'),
                ),
                ElevatedButton(
                  onPressed: _send,
                  child: Text('Send hello'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _register,
                  child: Text('Register MPN'),
                ),
                ElevatedButton(
                  onPressed: _subscribeMpn,
                  child: Text('Subscribe MPN'),
                ),
                ElevatedButton(
                  onPressed: _unsubscribeMpn,
                  child: Text('Unsubscribe MPN'),
                ),
                ElevatedButton(
                  onPressed: _unsubscribeAllMpn,
                  child: Text('UnsubscribeAll MPN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
