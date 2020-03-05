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

const String _bitcoinAlphabet =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

class Service {
  Socket socket;

  KademliaId nodeId = new KademliaId();

  start() {
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

    List<String> split = Settings.seedNodeList[0].split(":");
    String ip = split[0];
    int port = int.tryParse(split[1]);
    if (port == null) {
      return;
    }
    Peer peer = new Peer(ip, port);

    Socket.connect(peer.ip, peer.port).then((socket) {
      print('Connected to: '
          '${socket.remoteAddress.address}:${socket.remotePort}');

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
      socket.add(
          "asdafwadwdadst4bt2tz3b4r2tz3b42xdtz3r4fbxd2tz3b4fd2tz3bd4f2tz3d4f2tz34bdf2tz4f2z4fd"
              .codeUnits);
      socket.add(
          "asdafwadwdadst4bt2tz3b4r2tz3b42xdtz3r4fbxd2tz3b4fd2tz3bd4f2tz3d4f2tz34bdf2tz4f2z4fd"
              .codeUnits);
      socket.add(
          "asdafwadwdadst4bt2tz3b4r2tz3b42xdtz3r4fbxd2tz3b4fd2tz3bd4f2tz3d4f2tz34bdf2tz4f2z4fd"
              .codeUnits);
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
}
