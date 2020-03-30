import 'dart:isolate';
import 'dart:ui';

import 'package:redpanda/redPanda/RedPandaFlutterIsolate.dart';
import 'package:redpanda_light_client/export.dart';

class RedPandaFlutter {
  static SendPort sendPort;

  static stop() {
    var lookupPortByName = IsolateNameServer.lookupPortByName(RedPandaFlutterIsolate.LOOKUPNAME);
    if (lookupPortByName == null) {
      print("no isolate to stop");
      return;
    }
    lookupPortByName.send("STOP");
    IsolateNameServer.removePortNameMapping(RedPandaFlutterIsolate.LOOKUPNAME);
  }

  static start(String dataFolderPath, int myPort) async {
//    stop();
    /**
     * Lets try to start the Isolate which handles all redpanda functions.
     * This method will self check if the service is already running.
     */
    await RedPandaFlutterIsolate.tryStart();

    SendPort lookupPortByName = IsolateNameServer.lookupPortByName(RedPandaFlutterIsolate.LOOKUPNAME);

    var handshakePort = new ReceivePort();

    print("send registration to isolate");
    lookupPortByName.send(handshakePort.sendPort);

    sendPort = await handshakePort.first;
    print("sucessfully registered to isolate");

    RedPandaLightClient.initWithSendPort(dataFolderPath, myPort, sendPort);
  }

}
