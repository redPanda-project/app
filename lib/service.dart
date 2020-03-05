import 'dart:async';
import 'dart:core';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data' hide ByteBuffer;
import 'dart:typed_data';
import 'dart:typed_data' as prefix0;

import 'package:base58check/base58.dart';
import 'package:base58check/base58check.dart';
import 'package:buffer/buffer.dart';
import 'package:byte_array/byte_array.dart';
import 'dart:convert';

import 'package:hex/hex.dart';
import 'package:redpanda/redPanda/ByteBuffer.dart';
import 'package:redpanda/redPanda/KademliaId.dart';
import 'package:redpanda/redPanda/Peer.dart';
import 'package:redpanda/redPanda/Settings.dart';
import 'package:redpanda/redPanda/Utils.dart';

const String _bitcoinAlphabet =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

class Service {
  Socket socket;

  KademliaId nodeId;
  List<Peer> peerlist;

  Service(this.nodeId) {
    peerlist = new List();
  }

  void loop() {
    if (peerlist.length < 3) {
      reseed();
    }

    for (Peer peer in peerlist) {
      if (peer.connecting || peer.connected) {
        if (new DateTime.now().millisecondsSinceEpoch -
                peer.lastActionOnConnection >
            1000 * 5) {
          if (peer.socket != null) {
            peer.socket.destroy();
          }

          for (Function setState in Utils.states) {
            setState(() {
              // This call to setState tells the Flutter framework that something has
              // changed in this State, which causes it to rerun the build method below
              // so that the display can reflect the updated values. If we changed
              // _counter without calling setState(), then the build method would not be
              // called again, and so nothing would appear to happen.
              peer.connecting = false;
              peer.connected = false;
            });
          }
        }

        continue;
      }

      connectTo(peer);
    }
  }

  void start() {
    loop();
    const oneSec = const Duration(seconds: 2);
    new Timer.periodic(oneSec, (Timer t) => {loop()});

//    var utf8codec = new Utf8Codec();
//    var encode = utf8codec.encode("test string");
//
//    var byteDataWriter = new ByteDataWriter();
//
//    byteDataWriter.writeInt32(19);
//    byteDataWriter.write(encode);
//
//    var byteDataReader = ByteDataReader();
//
//    byteDataReader.add(byteDataWriter.toBytes());
//
//    print("test " + byteDataReader.readInt32().toString());
//    print("test " + utf8codec.decode(byteDataReader.read(11)));
//    print('' + "");

//    Socket.connect("redpanda.im", 59558).then((socket) {

//    List<String> split = Settings.seedNodeList[0].split(":");
//    String ip = split[0];
//    int port = int.tryParse(split[1]);
//    if (port == null) {
//      return;
//    }
//    Peer peer = new Peer(ip, port);
  }

  void connectTo(Peer peer) {
    for (Function setState in Utils.states) {
      setState(() {
        // This call to setState tells the Flutter framework that something has
        // changed in this State, which causes it to rerun the build method below
        // so that the display can reflect the updated values. If we changed
        // _counter without calling setState(), then the build method would not be
        // called again, and so nothing would appear to happen.
        peer.connecting = true;
      });
    }

    peer.lastActionOnConnection = new DateTime.now().millisecondsSinceEpoch;

    Socket.connect(peer.ip, peer.port).catchError(peer.onError).then((socket) {
      if (socket == null) {
        peer.connecting = false;
//        print('error connecting...');
        return;
      }

      peer.socket = socket;

      print('Connected to: '
          '${socket.remoteAddress.address}:${socket.remotePort}');
      socket.handleError(peer.onError);

      socket.done.then((value) => {peer.onError(value)});

      //      socket.add(utf8.encode("3kgV"));
      //      socket.write(utf8.encode("3kgV"));

      ByteBuffer byteBuffer =
          new ByteBuffer(4 + 1 + KademliaId.ID_LENGTH_BYTES + 4);
      byteBuffer.writeList('3kgV'.codeUnits);
      byteBuffer.writeByte(8);
      byteBuffer.writeList(nodeId.bytes);
      print(byteBuffer.buffer.asUint8List());
      byteBuffer.writeInt(59558);
      print(byteBuffer.buffer.asUint8List());

      socket.add(byteBuffer.buffer.asInt8List());

      //      socket.writeCharCode(8);
      socket.add(nodeId.bytes);
      //      socket.add(59558);
      //      socket.flush();
      socket.listen(peer.ondata);
      //      socket.destroy();
    });
  }

  void dataHandler(data) {
    print(new String.fromCharCodes(data).trim());
  }

  void errorHandler(error, StackTrace trace) {
    print(error);
  }

  void doneHandler() {
    socket.destroy();
  }

  bool _listsAreEqual(list1, list2) {
    if (list1.length != list2.length) {
      return false;
    }
    var i = -1;
    return list1.every((val) {
      i++;
      if (val is List && list2[i] is List)
        return _listsAreEqual(val, list2[i]);
      else
        return list2[i] == val;
    });
  }

  void reseed() {
//    print('reseed...');
    for (String str in Settings.seedNodeList) {
      List<String> split = str.split(":");
      String ip = split[0];
      int port = int.tryParse(split[1]);
      if (port == null) {
        return;
      }
      Peer peer = new Peer(ip, port);

      if (!peerlist.contains(peer)) {
//        print('peer not in list add');
        peerlist.add(peer);
      } else {
//        print('peer in list do not add');
      }
    }
  }
}
