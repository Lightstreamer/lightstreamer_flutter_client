import 'package:flutter/material.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

void main() {
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

  _MyHomePageState() : _client = new LightstreamerClient("https://push.lightstreamer.com", "DEMO") {
    LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

    var listener = new _MyClientListener();
    _client.addListener(listener);
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
          ],
        ),
      ),
    );
  }
}
