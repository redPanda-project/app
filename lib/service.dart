import 'dart:io';
import 'dart:typed_data';

import 'package:base58check/base58.dart';
import 'package:base58check/base58check.dart';
import 'package:buffer/buffer.dart';
import 'dart:convert';

import 'package:hex/hex.dart';


const String _bitcoinAlphabet =
    "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

class Service {
  Socket socket;

  final magic = Utf8Codec().encode("k3gV");

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

    Socket.connect("redpanda.im", 59558).then((socket) {
      print('Connected to: '
          '${socket.remoteAddress.address}:${socket.remotePort}');
      socket.write("qwert");
      socket.listen(ondata);
//      socket.destroy();
    });
  }

  void ondata(Uint8List data) {
    print(data.toString());

    ByteDataReader byteDataReader = new ByteDataReader();
    byteDataReader.add(data);

//    print(Utf8Codec().decode(data.sublist(0, 4)));
//    print(magic);
//    print(data.sublist(0, 4));

//    print(Utf8Codec().decode(data.sublist(0, 4)) == "k3gV");

    Uint8List readMagic = byteDataReader.read(4);
    print(readMagic);

    int version = byteDataReader.readUint8();
    print("version $version");

    if (!_listsAreEqual(magic, readMagic)) {
      print("wrong magic, disconnect!");
    }

    Uint8List nonce = byteDataReader.read(20);
    print("server identity: " + HEX.encode(nonce).toUpperCase());
    print(Base58Codec(_bitcoinAlphabet).encode(nonce));
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
