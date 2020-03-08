import 'dart:ffi';

class Command {
  static final int GET_PEER_LIST = 1;

  static final int REQUEST_PUBLIC_KEY = 1;
  static final int SEND_PUBLIC_KEY = 2;

  static final int ACTIVATE_ENCRYPTION = 3;

  static final int PING = 5;
  static final int PONG = 6;

  static final int REQUEST_PEERLIST = 7;
  static final int SEND_PEERLIST = 8;
  static final int UPDATE_REQUEST_TIMESTAMP = 9;

  static final int UPDATE_ANSWER_TIMESTAMP = 10;
  static final int UPDATE_REQUEST_CONTENT = 11;
  static final int UPDATE_ANSWER_CONTENT = 12;
}
