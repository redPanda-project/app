import 'dart:io';
import 'dart:typed_data';

class FlutterUtils {
  static Future<Uint8List> readFileByte(String filePath) async {
    File file = new File(filePath);
    return await file.readAsBytes();
  }

  static void writeFileBytes(String filePath, Uint8List data) async {
    File file = new File(filePath);
    await file.writeAsBytes(data);
    return;
  }
}
