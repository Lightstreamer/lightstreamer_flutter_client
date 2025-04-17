/*
 * Copyright (C) 2022 Lightstreamer Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import 'package:flutter/material.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

String _lastUpdate = " ---- ";

Color highlightColorLast = Colors.blueGrey;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String _status = 'Unknown';
  final myController = TextEditingController();
  final mySubController = TextEditingController();

  // WARNING keep strong references to LightstreamerClients, Subscriptions, MpnDevices and MpnSubscriptions 
  // to receive related events
  late LightstreamerClient _client;
  Subscription? _subscription;

  @override
  void initState() {
    super.initState();
    
    LightstreamerClient.setLoggerProvider(ConsoleLoggerProvider(ConsoleLogLevel.WARN));

    _client = LightstreamerClient("https://push.lightstreamer.com/", "DEMO");
    _client.addListener(_MyClientListener(this));
  }

  void _startRealTime() async {
    _client.connectionOptions.setKeepaliveInterval(10000);
    await _client.connect();
  }

  void _stopRealTime() async {
    await _client.disconnect();
  }

  void _getStatus() async {
    String result = await _client.getStatus();
    setState(() {
      _status = result;
    });
  }

  void _sendMessage() async {
    await _client.sendMessage(myController.text, null, null, _MyClientMessageListener(this), true);
  }

  void _subscribe() async {
    if (_subscription != null) {
      await _client.unsubscribe(_subscription!);
    }
    var items = mySubController.text.split(",");
    var fields = [ "last_price", "time", "stock_name" ];
    var sub = Subscription("MERGE", items, fields);
    sub.setDataAdapter("QUOTE_ADAPTER");
    sub.setRequestedMaxFrequency("1");
    sub.setRequestedSnapshot("yes");
    sub.addListener(_MySubscriptionListener(this));
    _subscription = sub;
    await _client.subscribe(sub);
  }

  void _unsubscribe() async {
    _subscription = null;
    for (var sub in await _client.getSubscriptions()) {
      await _client.unsubscribe(sub);
    }
  }

  void _values(String item, String fieldName, String fieldValue) {
    setState(() {
      _lastUpdate = "$item,$fieldName,$fieldValue\n$_lastUpdate";
      highlightColorLast = Colors.yellow;
    });
  }

  void _clientStatus(String msg) {
    setState(() {
      _status = msg;
    });
  }

  void _clientMessage(String msg) {
    setState(() {
      _status = msg;
    });
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _startRealTime,
                child: const Text('Start Realtime from Lightstreamer'),
              ),
              ElevatedButton(
                onPressed: _stopRealTime,
                child: const Text('Stop Realtime from Lightstreamer'),
              ),
              ElevatedButton(
                onPressed: _getStatus,
                child: const Text('Get Status'),
              ),
              Text('Status of the connection: $_status\n'),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a message to send',
                ),
                controller: myController,
              ),
              ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('Send Message'),
              ),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter the list of items to subscribe',
                ),
                controller: mySubController,
              ),
              ElevatedButton(
                onPressed: _subscribe,
                child: const Text('Subscribe'),
              ),
              ElevatedButton(
                onPressed: _unsubscribe,
                child: const Text('Unsubscribe'),
              ),
              Text(_lastUpdate,
                  maxLines: 20,
                  style: TextStyle(backgroundColor: highlightColorLast),
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
  final MyAppState _state;

  _MyClientListener(MyAppState state) : _state = state;

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
  final MyAppState _state;

  _MySubscriptionListener(MyAppState state) : _state = state;

  @override
  void onItemUpdate(ItemUpdate update) {
    var itemName = update.getItemName()!;
    for (var field in update.getFields().entries) {
      _state._values(itemName, field.key, field.value ?? '');
    }
  }

  @override
  void onSubscriptionError(int errorCode, String errorMessage) {
    _state._clientStatus('ERROR $errorCode: $errorMessage');
  }
}

class _MyClientMessageListener extends ClientMessageListener {
  final MyAppState _state;

  _MyClientMessageListener(MyAppState state) : _state = state;

  @override
  void onAbort(String originalMessage, bool sentOnNetwork) {
    _state._clientMessage('ERROR: Message aborted: $originalMessage');
  }

  @override
  void onDeny(String originalMessage, int errorCode, String errorMessage) {
    _state._clientMessage('ERROR: Message denied: $errorCode - $errorMessage');
  }

  @override
  void onDiscarded(String originalMessage) {
    _state._clientMessage('ERROR: Message discarded: $originalMessage');
  }

  @override
  void onError(String originalMessage) {
    _state._clientMessage('ERROR: Message error: $originalMessage');
  }

  @override
  void onProcessed(String originalMessage, String response) {
    _state._clientMessage('SUCCESS: Message processed: $originalMessage $response');
  }
}