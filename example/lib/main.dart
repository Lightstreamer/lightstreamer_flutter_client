import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_flutter_client.dart';

// ignore: non_constant_identifier_names
String static_sub_id = "";

String _last7 = " ---- ";

Color highlightcolor7 = Colors.blueGrey;

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

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String status;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      Map<String, String> params = {"user": "prova1", "password": "qwerty!"};

      status = await LightstreamerFlutterClient.connect(
              "https://push.lightstreamer.com/", "", params) ??
          'Unknown client session status';
    } on PlatformException {
      status = 'Failed to start Lighstreamer connection.';
    }

    LightstreamerFlutterClient.setClientListener(_clientStatus);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _status = status;
    });
  }

  Future<void> _startRealTime() async {
    String currentStatus;

    try {
      Map<String, String> params = {"user": "prova1", "password": "qwerty!"};

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
  }

  Future<void> _stopRealTime() async {
    String currentStatus;

    try {
      currentStatus = await LightstreamerFlutterClient.disconnect() ??
          'Unknown client session status';
    } on PlatformException catch (e) {
      currentStatus =
          "Problems in starting a session with Lightstreamer: '${e.message}' .";
    }

    setState(() {
      _status = currentStatus;
    });
  }

  Future<void> _getStatus() async {
    String result;

    try {
      result = await LightstreamerFlutterClient.getStatus() ?? ' -- ';
    } on PlatformException catch (e) {
      result = "Unknown";
    }

    setState(() {
      _status = result;
    });
  }

  Future<void> _sendMessage() async {
    try {
      // await LightstreamerFlutterClient.sendMessage(myController.text);

      await LightstreamerFlutterClient.sendMessageExt(
          myController.text, "Sequence1", 5000, _clientmessages, true);
    } on PlatformException catch (e) {
      // ...
    }
  }

  Future<void> _subscribe() async {
    String? subId = "";
    try {
      Map<String, String> params = {
        "dataAdapter": "STOCKS",
        "requestedMaxFrequency": "0.3"
      };
      subId = await LightstreamerFlutterClient.subscribe(
          "MERGE",
          mySubController.text.split(","),
          "last_price,time,stock_name".split(","),
          params);

      static_sub_id = subId as String;

      LightstreamerFlutterClient.setSubscriptionListener(subId, _values);
    } on PlatformException catch (e) {
      // ...
    }
  }

  void _values(String item, String fieldName, String fieldValue) {
    setState(() {
      _last7 = item + "," + fieldName + "," + fieldValue;
      highlightcolor7 = Colors.yellow;
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
    try {
      await LightstreamerFlutterClient.unsubscribe(static_sub_id);
    } on PlatformException catch (e) {
      // ...
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Connect'),
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
              Text(
                _last7,
                style: TextStyle(backgroundColor: highlightcolor7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
