import 'dart:io';
import 'dart:typed_data' hide ByteBuffer;
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:redpanda/redPanda/ByteBuffer.dart';
import 'package:redpanda/redPanda/KademliaId.dart';
import 'package:redpanda/redPanda/Utils.dart';

class Peer {
  String _ip;
  int _port;

  bool handshakeParsed = false;
  bool connecting = false;
  bool connected = false;

  int lastActionOnConnection = 0;

  Socket socket;

  Peer(this._ip, this._port);

  String get ip => _ip;

  int get port => _port;

  void ondata(Uint8List data) {
//    print(data.toString());



    ByteDataReader byteDataReader = new ByteDataReader();
    byteDataReader.add(data);

//    print(Utf8Codec().decode(data.sublist(0, 4)));
//    print(magic);
//    print(data.sublist(0, 4));

//    print(Utf8Codec().decode(data.sublist(0, 4)) == "k3gV");

//    Uint8List readMagic = byteDataReader.read(4);
//    print(readMagic);
//
//    int version = byteDataReader.readUint8();
//    print("version $version");
//
//    if (!_listsAreEqual(magic, readMagic)) {
//      print("wrong magic, disconnect!");
//    }
//
//    Uint8List nonce = byteDataReader.read(20);
//    print("server identity: " + HEX.encode(nonce).toUpperCase());
//    print(Base58Codec(_bitcoinAlphabet).encode(nonce));
//
//
//    print(byteDataReader.remainingLength);
//
//    print(byteDataReader.readUint(2));

    ByteBuffer buffer = ByteBuffer.fromBuffer(data.buffer);

    if (!handshakeParsed) {
//    print(buffer.readBytes(4));
      if (!Utils.listsAreEqual(Utils.MAGIC, buffer.readBytes(4))) {
        print("wrong magic, disconnect!");
      }

      int version = buffer.readByte();
      print("version $version");

      Uint8List nonce = buffer.readBytes(20);
//    print("server identity: " + HEX.encode(nonce).toUpperCase());

      KademliaId kademliaId = new KademliaId.fromBytes(nonce);

      print('Found node with id: ' + kademliaId.toString());

      handshakeParsed = true;

      print(buffer.readUnsignedShort());
    } else {
      print("cmd: " + buffer.readByte().toString());
    }
  }

  bool operator ==(other) {
    Peer otherPeer = other as Peer;

    if (otherPeer.ip == ip) {
      return true;
    }
  }

  void onError(error) {
//    print("error found: $error");
    print("error found...");
  }
}
