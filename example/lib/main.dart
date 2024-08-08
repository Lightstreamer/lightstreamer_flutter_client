import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

String _lastUpdate = " ---- ";

Color highlightcolorLast = Colors.blueGrey;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Unknown';
  final myController = TextEditingController();
  final mySubController = TextEditingController();
  late LightstreamerClient _client;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // LightstreamerClient.enableLog();

    _client = await LightstreamerClient.create("https://push.lightstreamer.com/", "DEMO");
    _client.addListener(_MyClientListener(this));
  }

  Future<void> _startRealTime() async {
    _client.connectionOptions.setKeepaliveInterval(10000);
    _client.connect();
  }

  Future<void> _stopRealTime() async {
    _client.disconnect();
  }

  Future<void> _getStatus() async {
    String result = await _client.getStatus();
    setState(() {
      _status = result;
    });
  }

  Future<void> _sendMessage() async {
    await _client.sendMessage(myController.text, null, null, _MyClientMessageListener(this), true);
  }

  Future<void> _subscribe() async {
    var items = mySubController.text.split(",");
    var fields = [ "last_price", "time", "stock_name" ];
    var sub = Subscription("MERGE", items, fields);
    sub.setDataAdapter("QUOTE_ADAPTER");
    sub.setRequestedMaxFrequency("1");
    sub.setRequestedSnapshot("yes");
    sub.addListener(_MySubscriptionListener(this));
    await _client.subscribe(sub);
  }

  void _values(String item, String fieldName, String fieldValue) {
    setState(() {
      _lastUpdate =
          item + "," + fieldName + "," + fieldValue + "\n" + _lastUpdate;
      highlightcolorLast = Colors.yellow;
    });
  }

  void _clientStatus(String msg) {
    setState(() {
      _status = msg;
    });
  }

  void _clientmessages(String msg) {
    setState(() {
      _status = msg;
    });
  }

  Future<void> _unsubscribe() async {
    for (var sub in await _client.getSubscriptions()) {
      await _client.unsubscribe(sub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lightstreamer Flutter Plugin Example'),
        ),
        body: Center(
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: const Text('Start Realtime from Lightstreamer'),
                onPressed: _startRealTime,
              ),
              ElevatedButton(
                child: const Text('Stop Realtime from Lightstreamer'),
                onPressed: _stopRealTime,
              ),
              ElevatedButton(
                child: const Text('Get Status'),
                onPressed: _getStatus,
              ),
              Text('Status of the connection: $_status\n'),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a message to send',
                ),
                controller: myController,
              ),
              ElevatedButton(
                child: const Text('Send Message'),
                onPressed: _sendMessage,
              ),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter the list of items to subscribe',
                ),
                controller: mySubController,
              ),
              ElevatedButton(
                child: const Text('Subscribe'),
                onPressed: _subscribe,
              ),
              ElevatedButton(
                child: const Text('Unsubscribe'),
                onPressed: _unsubscribe,
              ),
              Text(_lastUpdate,
                  maxLines: 20,
                  style: TextStyle(backgroundColor: highlightcolorLast),
                  overflow: TextOverflow.fade,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.justify),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyClientListener extends ClientListener {
  final _MyAppState _state;

  _MyClientListener(_MyAppState state) : _state = state;

  @override
  void onServerError(int errorCode, String errorMessage) {
    _state._clientStatus('ERROR $errorCode: $errorMessage');
  }

  @override
  void onStatusChange(String status) {
    _state._clientStatus(status);
  }
}

class _MySubscriptionListener extends SubscriptionListener {
  final _MyAppState _state;

  _MySubscriptionListener(_MyAppState state) : _state = state;

  @override
  void onItemUpdate(ItemUpdate update) {
    var itemName = update.getItemName()!;
    for (var field in update.getFields().entries) {
      _state._values(itemName, field.key, field.value);
    }
  }

  @override
  void onSubscriptionError(int errorCode, String errorMessage) {
    _state._clientStatus('ERROR $errorCode: $errorMessage');
  }
}

class _MyClientMessageListener extends ClientMessageListener {
  final _MyAppState _state;

  _MyClientMessageListener(_MyAppState state) : _state = state;

  void onAbort(String originalMessage, bool sentOnNetwork) {
    _state._clientmessages('ERROR: Message aborted: $originalMessage');
  }

  void onDeny(String originalMessage, int errorCode, String errorMessage) {
    _state._clientmessages('ERROR: Message denied: $errorCode - $errorMessage');
  }

  void onDiscarded(String originalMessage) {
    _state._clientmessages('ERROR: Message discarded: $originalMessage');
  }

  void onError(String originalMessage) {
    _state._clientmessages('ERROR: Message error: $originalMessage');
  }

  void onProcessed(String originalMessage, String response) {
    _state._clientmessages('SUCCESS: Message processed: $originalMessage $response');
  }
}