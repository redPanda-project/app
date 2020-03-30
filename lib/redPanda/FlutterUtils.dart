import 'dart:io';
import 'dart:typed_data';

class FlutterUtils {
  static Future<Uint8List> _readFileByte(String filePath) async {
    File audioFile = new File(filePath);
    Uint8List bytes;
    await audioFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
    }).catchError((onError) {
      print('Exception Error while reading audio from path:' + onError.toString());
    });
    return bytes;
  }
}
