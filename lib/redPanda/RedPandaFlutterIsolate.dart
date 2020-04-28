import 'dart:async';
import 'dart:isolate';

import 'dart:ui';

import 'package:redpanda/redPanda/RedPandaFlutter.dart';
import 'package:redpanda_light_client/export.dart';

isolateBootUpCallBackFunction(SendPort sendPort) {
  ReceivePort _port = new ReceivePort();

  print("isolate is starting, trying to register IsolateNameServer");
  var registerPortWithName = IsolateNameServer.registerPortWithName(_port.sendPort, RedPandaFlutterIsolate.LOOKUPNAME);
  if (!registerPortWithName) {
    print("registering failed, exit this isolate");
    //inform the waiting main thread
    sendPort.send(null);
    Isolate.current.kill();
    return;
  }

  print("Listening for register messages...");
  /**
   * Listen for register messages, data messages are parsed separately for each registered sendPort.
   */
  _port.listen((dynamic msg) {
    if (msg == "STOP") {
      print("stoping isolate...");
      //todo shutdown lib
      Isolate.current.kill();
      return;
    }

    print(msg.runtimeType.toString());

    if (msg is List<SendPort>) {
      var sendPort = msg[0];
      try {
        runZoned<Future<void>>(() async {
          sendPort.send(IsolateCommand.PING);
        }, onError: (error, stackTrace) {
          print("isolate is not running in the same process as the caller!");
          print(error);
        });
      } on Exception catch (e) {
        print("isolate is not running in the same process as the caller!");
        print(e);
      }
      return;
    }

    /**
     * We generate a new ReceivePort for every registration to this isolate and send the SendPort for this to the
     * registering isolate.
     */
    var receivePort = new ReceivePort();
    SendPort sendPortToRegister = msg as SendPort;
    sendPortToRegister.send(receivePort.sendPort);

    /**
     * We parse each data here on that new isolate with the RPC library.
     */
    receivePort.listen((dynamic message) {
      SendPort sendPort = message["sender"];
      String command = message["command"];
      dynamic data = message["data"];

      parseIsolateCommands(sendPort, command, data);
    });
  });

  //inform the waiting main thread
  sendPort.send(null);
}

class RedPandaFlutterIsolate {
  static final String LOOKUPNAME = "redpandaisolate";
  static ReceivePort _port;

  static Future<void> tryStart() async {
    SendPort lookupPortByName = IsolateNameServer.lookupPortByName(LOOKUPNAME);
//    print("lookupPortByName: $lookupPortByName");
    if (lookupPortByName == null) {
      print("spawning....");

      ReceivePort startCheckPort = await spawnIsolate();
      await startCheckPort.first;
    } else {
      print("isolate already running...");
      /**
       * lets send an object and check if the isolate is running in another process and we can not send objects to that
       * isolate.
       */
      try {
        var startCheckPort = new ReceivePort();
        print("send check");
        lookupPortByName.send([startCheckPort.sendPort]);
        print("send");

        final result = await Future.any([startCheckPort.first, Future.delayed(const Duration(milliseconds: 500))]);

        print("result: " + result.toString() + " " + result.runtimeType.toString());
        if (result == null) {
          print("no answer from isolate stoping...");
          RedPandaFlutter.stop();
          print("stoped isolate restarting...");
          ReceivePort startCheckPort = await spawnIsolate();
          await startCheckPort.first;
        }
      } on Exception catch (e) {
        print(e);
        print(e.runtimeType);
        RedPandaFlutter.stop();
        ReceivePort startCheckPort = await spawnIsolate();
        await startCheckPort.first;
      }
    }
  }

  static Future<ReceivePort> spawnIsolate() async {
    ReceivePort startCheckPort = new ReceivePort();
    Isolate newIsolate = await Isolate.spawn(isolateBootUpCallBackFunction, startCheckPort.sendPort);
    ReceivePort errorPort = ReceivePort();
    newIsolate.addErrorListener(errorPort.sendPort);
    errorPort.listen((listMessage) {
      String errorDescription = listMessage[0];
      String stackDescription = listMessage[1];
      ConnectionService.sentry.captureException(exception: errorDescription, stackTrace: stackDescription);
      print(errorDescription);
      print(stackDescription);
    });
    return startCheckPort;
  }
}
