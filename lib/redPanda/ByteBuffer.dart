import 'dart:typed_data';
import 'dart:typed_data' as prefix0;

import 'package:typed_data/typed_buffers.dart';

/// Read and write to an array of bytes
class ByteBuffer {
  ByteData _byteData;
  Endian endian;
  int _offset = 0;

  ByteData get byteData => _byteData;

  ByteBuffer([int length = 0, this.endian = Endian.big]) {
    final buff = Uint8Buffer(length);
    _byteData = ByteData.view(buff.buffer);
  }

  ByteBuffer.fromByteData(this._byteData, [this.endian = Endian.big]);

  factory ByteBuffer.fromBuffer(prefix0.ByteBuffer buffer,
      [int offset = 0, int length = null, Endian endian = Endian.big]) {
    length ??= buffer.lengthInBytes - offset;

    final view = ByteData.view(buffer, offset, length);
    return ByteBuffer.fromByteData(view, endian);
  }

  int readByte() => _getNum<int>((i, _) => _byteData.getInt8(i), 1);

  int readUnsignedByte() => _getNum<int>((i, _) => _byteData.getUint8(i), 1);

  /// Returns true if not equal to zero
  bool readBoolean() => readByte() != 0;

  int readShort() => _getNum<int>(_byteData.getInt16, 2);

  int readUnsignedShort() => _getNum<int>(_byteData.getUint16, 2);

  int readInt() => _getNum<int>(_byteData.getInt32, 4);

  int readUnsignedInt() => _getNum<int>(_byteData.getUint32, 4);

  int readLong() => _getNum<int>(_byteData.getInt64, 8);

  int readUnsignedLong() => _getNum<int>(_byteData.getUint64, 8);

  double readFloat() => _getNum<double>(_byteData.getFloat32, 4);

  double readDouble() => _getNum<double>(_byteData.getFloat64, 8);

  void writeByte(int value) =>
      _setNum<int>((i, v, _) => _byteData.setInt8(i, v), value, 1);

  void writeList(List<int> bytes) {
    Uint8List asUint8List = byteData.buffer.asUint8List();
    asUint8List.setAll(_offset, bytes);
    _offset += bytes.length;
  }

  void writeUnsignedByte(int value) =>
      _setNum<int>((i, v, _) => _byteData.setUint8(i, v), value, 1);

  /// Writes [int], 1 if true, zero if false
  void writeBoolean(bool value) => writeByte(value ? 1 : 0);

  void writeShort(int value) => _setNum(_byteData.setInt16, value, 2);

  void writeUnsignedShort(int value) => _setNum(_byteData.setUint16, value, 2);

  void writeInt(int value) => _setNum(_byteData.setInt32, value, 4);

  void writeUnsignedInt(int value) => _setNum(_byteData.setUint32, value, 4);

  void writeLong(int value) => _setNum(_byteData.setInt64, value, 8);

  void writeUnsignedLong(int value) => _setNum(_byteData.setUint64, value, 8);

  void writeFloat(double value) => _setNum(_byteData.setFloat32, value, 4);

  void writeDouble(double value) => _setNum(_byteData.setFloat64, value, 8);

  /// Get byte at given index
  int operator [](int i) => _byteData.getInt8(i);

  /// Set byte at given index
  void operator []=(int i, int value) => _byteData.setInt8(i, value);

  /// Appends [other] to [this]
  ByteBuffer operator +(ByteBuffer other) =>
      ByteBuffer(length + other.length)..writeBytes(this)..writeBytes(other);

  Iterable<int> byteStream() sync* {
    while (offset < length) yield this[offset++];
  }

  /// Returns true if every byte in both [ByteBuffer]s are equal
  /// Note: offsets will not be affected
  @override
  bool operator ==(Object otherObject) {
    if (otherObject is! ByteBuffer) return false;

    final ByteBuffer other = otherObject;

    if (length != other.length) return false;

    for (var i = 0; i < length; i++) if (this[i] != other[i]) return false;

    return true;
  }

  @override
  int get hashCode {
    final tempOffset = offset;

    const p = 16777619;
    var hash = 2166136261;

    for (var i = 0; i < length; i++) hash = (hash ^ this[i]) * p;

    offset = tempOffset;

    hash += hash << 13;
    hash ^= hash >> 7;
    hash += hash << 3;
    hash ^= hash >> 17;
    hash += hash << 5;
    return hash;
  }

  /// Copies bytes from [bytes] to [this]
  void writeBytes(ByteBuffer bytes, [int offset = 0, int byteCount = 0]) {
    if (byteCount == 0) byteCount = bytes.length;

    // Copy old offset so we can reset it after copy
    final oldOffset = bytes.offset;
    bytes.offset = offset;

    for (var i = 0; i < byteCount; i++) writeByte(bytes.readByte());

    bytes.offset = oldOffset;
  }

  void _setNum<T extends num>(
      void Function(int, T, Endian) f, T value, int size) {
    if (_offset + size > length)
      throw RangeError(
          'attempted to write to offset ${_offset + size}, length is $length');

    f(offset, value, endian);
    _offset += size;
  }

  T _getNum<T extends num>(T Function(int, Endian) f, int size) {
    if (_offset + size > length)
      throw RangeError(
          'attempted to read from offset ${_offset + size}, length is $length');

    final data = f(_offset, endian);
    _offset += size;
    return data;
  }

  int get length => _byteData.lengthInBytes;

  prefix0.ByteBuffer get buffer => _byteData.buffer;

  int get bytesAvailable => length - _offset;

  int get offset => _offset;

  set offset(int value) {
    if (value < 0 || value > length)
      throw RangeError('attempting to set offset to $value, length is $length');

    _offset = value;
  }

  List<int> readBytes(int len) {
    Uint8List ret = new Uint8List(len);

    for (int i = 0; i < len; i++) {
      ret[i] = (_byteData.getUint8(_offset));
      _offset++;
    }

    return ret;
  }
}
