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
// ignore_for_file: unnecessary_new, prefer_interpolation_to_compose_strings

import 'dart:io' show Platform, Cookie;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
import './utils.dart';

void main() {
  final host = Platform.isAndroid ? "http://10.0.2.2:8080" : "http://127.0.0.1:8080";
  late LightstreamerClient client;
  late BaseClientListener listener;
  late BaseSubscriptionListener subListener;
  late BaseMessageListener msgListener;
  LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

  test('channel errors', () async {
    try {
      client = LightstreamerClient('', '');
      await client.connect();
      fail('Expected PlatformException');
    } on PlatformException catch(e) {
      assertEqual('Lightstreamer Internal Error', e.code);
      assertEqual('address is malformed', e.message);
    }

    try {
      client = LightstreamerClient(host, 'TEST');
      client.connectionOptions.setContentLength(-1);
      await client.connect();
      fail('Expected PlatformException');
    } on PlatformException catch(e) {
      assertEqual('Lightstreamer Internal Error', e.code);
      assertEqual('value must be greater than zero', e.message);
    }
  }, skip: Platform.isIOS || Platform.isMacOS ? "When a precondition fails, Swift Client SDK throws an unrecoverable exception" : false);

  test('Subscription errors', () async {
    client = LightstreamerClient(host, "TEST");
    var sub = new Subscription("MERGE", ["count"], ["count"]);
    client.subscribe(sub);
    try {
      await client.subscribe(sub);
      fail('Expected PlatformException');
    } on PlatformException catch(e) {
      assertEqual('Lightstreamer Internal Error', e.code);
      assertEqual('Cannot subscribe to an active Subscription', e.message);
    }
    
    await client.unsubscribe(sub);
    sub.setRequestedMaxFrequency('2');
    await client.subscribe(sub);
  });

  ["WS-STREAMING", "HTTP-STREAMING", "HTTP-POLLING", "WS-POLLING"].forEach((transport) { 
    group(transport, () {

      setUp(() async {
        client = LightstreamerClient(host, "TEST");
        listener = new BaseClientListener();
        subListener = new BaseSubscriptionListener();
        msgListener = new BaseMessageListener();
        client.addListener(listener);

        client.connectionOptions.setForcedTransport(transport);
        if (transport.endsWith("POLLING")) {
          client.connectionOptions.setIdleTimeout(0);
          client.connectionOptions.setPollingInterval(100);
        }
      });

      tearDown(() {
        client.disconnect();
      });

      test('listeners', () async {
        var exps = new Expectations();
        var ls = client.getListeners();
        assertEqual(1, ls.length);
        assertEqual(true, listener == ls[0]);

        var cl2 = BaseClientListener();
        cl2.fListenStart = () => exps.signal('ClientListener.onListenStart');
        cl2.fListenEnd = () => exps.signal('ClientListener.onListenEnd');
        client.addListener(cl2);
        await exps.value('ClientListener.onListenStart');
        client.removeListener(cl2);
        await exps.value('ClientListener.onListenEnd');

        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.addListener(subListener);
        var subls = sub.getListeners();
        assertEqual(1, subls.length);
        assertEqual(true, subListener == subls[0]);

        var sl2 = BaseSubscriptionListener();
        sl2.fListenStart = () => exps.signal('SubscriptionListener.onListenStart');
        sl2.fListenEnd = () => exps.signal('SubscriptionListener.onListenEnd');
        sub.addListener(sl2);
        await exps.value('SubscriptionListener.onListenStart');
        sub.removeListener(sl2);
        await exps.value('SubscriptionListener.onListenEnd');
      });

      test('connect', () async {
        var exps = new Expectations();
        var expected = "CONNECTED:" + transport;
        listener.fStatusChange = (status) {
          if (status == expected) {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();
        assertEqual(expected, await client.getStatus());
      });

      test('online server', () async {
        var exps = new Expectations();
        client.connectionDetails.setServerAddress("https://push.lightstreamer.com");
        client.connectionDetails.setAdapterSet("DEMO");
        listener = new BaseClientListener();
        client.addListener(listener);

        var expected = "CONNECTED:" + transport;
        listener.fStatusChange = (status) {
          if (status == expected) {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();
        assertEqual(expected, await client.getStatus());
      });

      test('error', () async {
        var exps = new Expectations();
        client = LightstreamerClient(host, "XXX");
        listener = new BaseClientListener();
        client.addListener(listener);
        listener.fServerError = (code, msg) {
          exps.signal('$code $msg');
        };
        client.connect();
        await exps.value("2 Requested Adapter Set not available");
      });

      test('disconnect', () async {
        var exps = new Expectations();
        listener.fStatusChange = (status) {
          if (status == "CONNECTED:" + transport) {
            client.disconnect();
          } else if (status == "DISCONNECTED") {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();
        assertEqual("DISCONNECTED", await client.getStatus());
      });

      test('subscribe', () async {
        var exps = new Expectations();
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        var subs = await client.getSubscriptions();
        assertEqual(1, subs.length);
        assertEqual(true, sub == subs[0]);
        client.connect();
        await exps.value();
        assertEqual(true, sub.isSubscribed());
      });

      test('subscription error', () async {
        var exps = new Expectations();
        var sub = new Subscription("RAW", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fSubscriptionError = (code, msg) {
          exps.signal('$code $msg');
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("24 Invalid mode for these items");
      });

      test('subscribe command', () async {
        var exps = new Expectations();
        var sub = new Subscription(
            "COMMAND", ["mult_table"], ["key", "value1", "value2", "command"]);
        sub.setDataAdapter("MULT_TABLE");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        client.connect();
        await exps.value();
        assertEqual(true, sub.isSubscribed());
        assertEqual(1, sub.getKeyPosition());
        assertEqual(4, sub.getCommandPosition());
        // check that `getCommandValue` doesn't throw exceptions
        await sub.getCommandValue('mult_table', 'row', 'value1');
        await sub.getCommandValue('mult_table', 'row', '2');
        await sub.getCommandValue('1', 'row', 'value1');
        await sub.getCommandValue('1', 'row', '2');
      });

      test('subscribe command 2 levels', () async {
        var exps = new Expectations();
        var sub = new Subscription("COMMAND",
            ["two_level_command_count" + transport], ["key", "command"]);
        sub.setDataAdapter("TWO_LEVEL_COMMAND");
        sub.setCommandSecondLevelDataAdapter("COUNT");
        sub.setCommandSecondLevelFields(["count"]);
        sub.addListener(subListener);
        var regex = new RegExp('\\d+');
        subListener.fItemUpdate = (update) {
          var val = update.getValue("count") ?? "";
          var key = update.getValue("key") ?? "";
          var cmd = update.getValue("command") ?? "";
          if (regex.hasMatch(val) && key == "count" && cmd == "UPDATE") {
            exps.signal();
          }
        };
        client.subscribe(sub);
        var subs = await client.getSubscriptions();
        assertEqual(1, subs.length);
        assertEqual(true, sub == subs[0]);
        client.connect();
        await exps.value();
        assertEqual(true, sub.isSubscribed());
        assertEqual(1, sub.getKeyPosition());
        assertEqual(2, sub.getCommandPosition());
      });

      test('unsubscribe', () async {
        var exps = new Expectations();
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          client.unsubscribe(sub);
        };
        subListener.fUnsubscription = () {
          exps.signal('onUnsubscription');
        };
        client.subscribe(sub);
        client.connect();
        await exps.value('onUnsubscription');
        assertEqual(false, sub.isSubscribed());
        assertEqual(false, sub.isActive());
      });

      test('subscribe non-ascii', () async {
        var exps = new Expectations();
        var sub = new Subscription(
            "MERGE", ["strange:àìùòlè"], ["value🌐-", "value&+=\r\n%"]);
        sub.setDataAdapter("STRANGE_NAMES");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        client.connect();
        await exps.value();
      });

      String? normalizeFloat(String? d) {
        // numeric strings coming from different platforms have different formatting.
        // for example, iOS usually appends a trailing '.0' to decimal number, while Android doesn't
        return d == null ? null : d.contains(".") ? d : '$d.0';
      }

      test('bandwidth', () async {
        var exps = new Expectations();
        listener.fPropertyChange = (prop) async {
          switch (prop) {
            case "realMaxBandwidth":
              exps.signal("realMaxBandwidth=${normalizeFloat(client.connectionOptions.getRealMaxBandwidth())}");
          }
        };
        assertEqual("unlimited", client.connectionOptions.getRequestedMaxBandwidth());
        client.connect();
        await exps.value("realMaxBandwidth=40.0"); // after the connection, the server sends the default bandwidth
        // request a bandwidth equal to 20.1: the request is accepted
        client.connectionOptions.setRequestedMaxBandwidth("20.1");
        await exps.value("realMaxBandwidth=20.1");
        // request a bandwidth equal to 70.1: the meta-data adapter cuts it to 40 (which is the configured limit)
        client.connectionOptions.setRequestedMaxBandwidth("70.1");
        await exps.value("realMaxBandwidth=40.0");
        // request an unlimited bandwidth: the meta-data adapter cuts it to 40 (which is the configured limit)
        client.connectionOptions.setRequestedMaxBandwidth("unlimited");
        // NB the listener isn't notified again because the value isn't changed
        // await exps.value("realMaxBandwidth=40");
      });

      test('forced transport', () async {
        var exps = new Expectations();
        listener.fStatusChange = (status) => exps.signal(status);
        client.connect();
        await exps.until('CONNECTED:$transport');
        var newTransport = transport == 'WS-STREAMING' ? 'HTTP-STREAMING' : 'WS-STREAMING';
        client.connectionOptions.setForcedTransport(newTransport);
        await exps.until('CONNECTED:$newTransport');
      });

      test('heartbeat', () async {var exps = new Expectations();
        listener.fPropertyChange = (prop) async {
          switch (prop) {
            case "reverseHeartbeatInterval":
              exps.signal("reverseHeartbeatInterval=${client.connectionOptions.getReverseHeartbeatInterval()}");
          }
        };
        client.connect();
        client.connectionOptions.setReverseHeartbeatInterval(123);
        await exps.until("reverseHeartbeatInterval=123");
        client.connectionOptions.setReverseHeartbeatInterval(456);
        await exps.until("reverseHeartbeatInterval=456");
      });

      test('setServerAddress', () async {
        var exps = new Expectations();
        client.connectionOptions.setRetryDelay(100);
        client.connectionDetails.setServerAddress("http://10.255.255.1:8080"); // non-routable IP address 
        listener.fStatusChange = (status) => exps.signal(status);
        client.connect();
        await exps.until('DISCONNECTED:WILL-RETRY');
        client.connectionDetails.setServerAddress(host);
        await exps.until('CONNECTED:$transport');
      });

      test('clear snapshot', () async {
        var exps = new Expectations();
        var sub = new Subscription("DISTINCT", ["clear_snapshot"], ["dummy"]);
        sub.setDataAdapter("CLEAR_SNAPSHOT");
        sub.addListener(subListener);
        subListener.fClearSnapshot = (name, pos) {
          exps.signal('$name $pos');
        };
        client.subscribe(sub);
        client.connect();
        await exps.value('clear_snapshot 1');
      });

      test('roundtrip', () async {
        var exps = new Expectations();
        assertEqual("TEST", client.connectionDetails.getAdapterSet());
        assertEqual(host, client.connectionDetails.getServerAddress());
        assertEqual(50000000, client.connectionOptions.getContentLength());
        assertEqual(4000, client.connectionOptions.getRetryDelay());
        assertEqual(
            15000, client.connectionOptions.getSessionRecoveryTimeout());
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        assertEqual("COUNT", sub.getDataAdapter());
        assertEqual("MERGE", sub.getMode());
        sub.addListener(subListener);
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fItemUpdate = (_) => exps.signal("onItemUpdate");
        subListener.fUnsubscription = () => exps.signal("onUnsubscription");
        subListener.fRealMaxFrequency =
            (freq) => exps.signal('onRealMaxFrequency $freq');
        if (transport == "WS-STREAMING") {
          listener.fPropertyChange = (prop) async {
            switch (prop) {
              case "clientIp":
                exps.signal(
                    "clientIp=${client.connectionDetails.getClientIp()}");
              case "serverSocketName":
                exps.signal(
                    "serverSocketName=${client.connectionDetails.getServerSocketName()}");
              case "sessionId":
                exps.signal("sessionId " +
                    ((client.connectionDetails.getSessionId()) == null
                        ? "is null"
                        : "is not null"));
              case "keepaliveInterval":
                exps.signal("keepaliveInterval=${client.connectionOptions.getKeepaliveInterval()}");
              case "realMaxBandwidth":
                exps.signal(
                    "realMaxBandwidth=${normalizeFloat(client.connectionOptions.getRealMaxBandwidth())}");
            }
          };
        }
        client.connect();
        if (transport == "WS-STREAMING") {
          // when the native client connects, it sets all the properties in connectionOptions and connectionDetails, 
          // including keepaliveInterval, to the values passed by the Dart front-end
          await exps.value("sessionId is not null");
          await exps.value("keepaliveInterval=5000");
          await exps.value("serverSocketName=Lightstreamer HTTP Server");
          await exps.value("clientIp=127.0.0.1");
          await exps.value("realMaxBandwidth=40.0");
        }
        client.subscribe(sub);
        await exps.value("onSubscription");
        await exps.value("onRealMaxFrequency unlimited");
        await exps.value("onItemUpdate");
        assertNotNull(await sub.getValue('count', 'count'));
        assertNotNull(await sub.getValue('count', '1'));
        assertNotNull(await sub.getValue('1', 'count'));
        assertNotNull(await sub.getValue('1', '1'));
        client.unsubscribe(sub);
        await exps.value("onUnsubscription");
      });

      test('message', () async {
        var exps = new Expectations();
        client.connect();
        client.sendMessage("test message ()", null, 0, null, true);
        // no outcome expected
        client.sendMessage(
            "test message (sequence)", "test_seq", 0, null, true);
        // no outcome expected
        msgListener = new BaseMessageListener();
        msgListener.fProcessed = (msg, _) => exps.signal("onProcessed " + msg);
        client.sendMessage(
            "test message (listener)", null, -1, msgListener, true);
        await exps.value("onProcessed test message (listener)");
        msgListener = new BaseMessageListener();
        msgListener.fProcessed = (msg, _) => exps.signal("onProcessed " + msg);
        client.sendMessage("test message (sequence+listener)", "test_seq", -1,
            msgListener, true);
        await exps.value("onProcessed test message (sequence+listener)");
      });

      test('message with return value', () async {
        var exps = new Expectations();
        client.connect();
        msgListener = new BaseMessageListener();
        msgListener.fProcessed =
            (msg, resp) => exps.signal('onProcessed `$msg` `$resp`');
        client.sendMessage(
            "give me a result", "test_seq", -1, msgListener, true);
        await exps.value("onProcessed `give me a result` `result:ok`");
      });

      test('message with special chars', () async {
        var exps = new Expectations();
        msgListener.fProcessed = (msg, _) {
          exps.signal(msg);
        };
        client.connect();
        client.sendMessage("hello +&=%\r\n", null, -1, msgListener, false);
        await exps.value("hello +&=%\r\n");
      });

      test('unordered messages', () async {
        var exps = new Expectations();
        msgListener.fProcessed = (msg, _) {
          exps.signal(msg);
        };
        client.connect();
        client.sendMessage(
            "test message", "UNORDERED_MESSAGES", -1, msgListener, false);
        await exps.value("test message");
      });

      test('message error', () async {var exps = new Expectations();
        msgListener.fDeny = (msg, code, error) {
          exps.signal('$msg $code $error');
        };
        client.connect();
        client.sendMessage(
            "throw me an error", "test_seq", -1, msgListener, false);
        await exps.value("throw me an error -123 test error");
      });

      test('long message', () async {
        var exps = new Expectations();
        var msg =
            "{\"n\":\"MESSAGE_SEND\",\"c\":{\"u\":\"GEiIxthxD-1gf5Tk5O1NTw\",\"s\":\"S29120e92e162c244T2004863\",\"p\":\"localhost:3000/html/widget-responsive.html\",\"t\":\"2017-08-08T10:20:05.665Z\"},\"d\":\"{\\\"p\\\":\\\"🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐\\\"}\"}";
        msgListener.fProcessed = (_, __) => exps.signal();
        client.connect();
        client.sendMessage(msg, "test_seq", -1, msgListener, false);
        await exps.value();
      });

      test('end of snapshot', () async {
        var exps = new Expectations();
        var sub = new Subscription("DISTINCT", ["end_of_snapshot"], ["value"]);
        sub.setRequestedSnapshot("yes");
        sub.setDataAdapter("END_OF_SNAPSHOT");
        subListener.fEndOfSnapshot = (name, pos) {
          exps.signal('$name $pos');
        };
        sub.addListener(subListener);
        client.subscribe(sub);
        client.connect();
        await exps.value("end_of_snapshot 1");
      });

      /**
       * Subscribes to an item and verifies the overflow event is notified to the client.
       * <br>To ease the overflow event, the test
       * <ul>
       * <li>limits the event buffer size (see max_buffer_size in Test_integration/conf/test_conf.xml)</li>
       * <li>limits the bandwidth (see {@link ConnectionOptions#setRequestedMaxBandwidth(String)})</li>
       * <li>requests "unfiltered" messages (see {@link Subscription#setRequestedMaxFrequency(String)}).</li>
       * </ul>
       */
      test('overflow', () async {
        var exps = new Expectations();
        var sub = new Subscription("MERGE", ["overflow"], ["value"]);
        sub.setRequestedSnapshot("yes");
        sub.setDataAdapter("OVERFLOW");
        sub.setRequestedMaxFrequency("unfiltered");
        subListener.fItemLostUpdates = (name, pos, lost) {
          exps.signal('$name $pos');
          client.unsubscribe(sub);
        };
        subListener.fUnsubscription = () {
          exps.signal("onUnsubscription");
        };
        sub.addListener(subListener);
        client.subscribe(sub);
        // NB the bandwidth must not be too low otherwise the server can't write the response
        client.connectionOptions.setRequestedMaxBandwidth("10");
        client.connect();
        await exps.value("overflow 1");
        await exps.value("onUnsubscription");
      });

      test('frequency', () async {
        var exps = new Expectations();
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fRealMaxFrequency = (freq) {
          exps.signal(freq!);
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("unlimited");
      });

      test('change frequency', () async {
        var exps = new Expectations();
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fRealMaxFrequency = (freq) {
          exps.signal("frequency=" + freq!);
        };
        sub.setRequestedMaxFrequency("unlimited");
        client.subscribe(sub);
        client.connect();
        await exps.value("frequency=unlimited");
        sub.setRequestedMaxFrequency("2.5");
        await exps.value("frequency=2.5");
        sub.setRequestedMaxFrequency("unlimited");
        await exps.value("frequency=unlimited");
      });

      test('headers', () async {
        var exps = new Expectations();
        client.connectionOptions.setHttpExtraHeaders({"hello": "header"});
        var hs = client.connectionOptions.getHttpExtraHeaders()!;
        assertEqual("header", hs["hello"]);

        var expected = "CONNECTED:" + transport;
        listener.fStatusChange = (status) {
          if (status == expected) exps.signal();
        };
        client.connect();
        await exps.value();
      });

      test('json patch', () async {
        var exps = new Expectations();
        var updates = <ItemUpdate>[];
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setRequestedSnapshot("no");
        sub.setDataAdapter("JSON_COUNT");
        sub.addListener(subListener);
        subListener.fItemUpdate = (update) {
          updates.add(update);
          exps.signal("onItemUpdate");
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("onItemUpdate");
        await exps.value("onItemUpdate");
        var u = updates[1];
        var patch = u.getValueAsJSONPatchIfAvailableByPosition(1)!;
        expect(patch, contains('"op":"replace"'));
        if (Platform.isIOS || Platform.isMacOS) {
          // by default iOS/macOS JSON serialization escapes forward slashes
          expect(patch, contains('"path":"\\/value"'));
        } else {
          expect(patch, contains('"path":"/value"'));
        }
        expect(patch, matches(RegExp('"value":\\d+')));
        expect(u.getValueByPosition(1), isNotNull);
      }, skip: Platform.isWindows);

      test('diff patch', () async {
        var exps = new Expectations();
        var updates = <ItemUpdate>[];
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setRequestedSnapshot("no");
        sub.setDataAdapter("DIFF_COUNT");
        sub.addListener(subListener);
        subListener.fItemUpdate = (update) {
          updates.add(update);
          exps.signal("onItemUpdate");
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("onItemUpdate");
        await exps.value("onItemUpdate");
        var u = updates[1];
        expect(u.getValueByPosition(1), matches('value=\\d+'));
      }, skip: Platform.isWindows);

      test('cookies', () async {
        // clear cookies
        var cookies0_ = await LightstreamerClient.getCookies(host);
        cookies0_.forEach((c) => c.maxAge = 0);
        await LightstreamerClient.addCookies(host, cookies0_);
        
        var cookies0 = await LightstreamerClient.getCookies(host);
        assertEqual(0, cookies0.length);

        var cookie = Cookie.fromSetCookieValue("X-Client=client");
        await LightstreamerClient.addCookies(host, [cookie]);

        var exps = new Expectations();
        listener.fStatusChange = (status) {
          if (status.startsWith("CONNECTED")) {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();

        var cookies = await LightstreamerClient.getCookies(host);
        assertEqual(2, cookies.length);
        var cookies_ = cookies.map((c) => c.toString()).join(" ");
        expect(cookies_, contains("X-Client=client"));
        expect(cookies_, contains("X-Server=server"));
      });

      test('null field', () async {
        var exps = new Expectations();
        var updates = <ItemUpdate>[];
        var sub = Subscription("MERGE", ["null_item"], ["null_field"]);
        sub.setRequestedSnapshot("no");
        sub.setDataAdapter("NULL_ITEM");
        sub.addListener(subListener);
        subListener.fItemUpdate = (update) {
          updates.add(update);
          exps.signal("onItemUpdate");
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("onItemUpdate");
        var u = updates[0];
        expect(u.getValueByPosition(1), isNull);
        expect(u.getValue("null_field"), isNull);
        expect(u.getFields(), {"null_field": null});
        expect(u.getFieldsByPosition(), {1: null});
      });

    }); // group
  }); // for each group
} // main
