import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'utils.dart';

///
class MyBinaryWriter implements BytesBuilder {
  ///
  factory MyBinaryWriter() => MyBinaryWriter._(_emptyList);

  ///
  factory MyBinaryWriter.withBuffer(Uint8List buffer) = MyBinaryWriter._;

  MyBinaryWriter._(this._buffer);

  /// Начальный размер буффера
  static const int _initSize = 1024;

  /// Переиспользуемый пустой лист [Uint8List].
  static final _emptyList = Uint8List(0);

  /// Current count of bytes written to buffer.
  int _length = 0;

  ByteData? _byteDataInstance;

  /// Internal buffer accumulating bytes.
  ///
  /// Will grow as necessary
  Uint8List _buffer;

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get length => _length;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  ByteData get _byteData {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance!;
  }

  @override
  void add(List<int> bytes) {
    final byteCount = bytes.length;
    _reserveBytes(byteCount);
    _buffer.setRange(_length, _length + byteCount, bytes);
    _length += byteCount;
  }

  @override
  void addByte(int byte) {
    if (_buffer.length == _length) {
      // The grow algorithm always at least doubles.
      // If we added one to _length it would quadruple unnecessarily.
      _grow(_length);
    }
    _buffer[_length] = byte;
    _length++;
  }

  @override
  void clear() {
    _length = 0;
    _buffer = _emptyList;
    _byteDataInstance = null;
  }

  @override
  Uint8List takeBytes() {
    if (_length == 0) return _emptyList;
    final buffer =
        Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length);
    clear();
    return buffer;
  }

  @override
  Uint8List toBytes() {
    if (_length == 0) return _emptyList;
    return Uint8List.fromList(
        Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length));
  }

  ///
  void writeDateTime(DateTime val) => writeInt64(val.millisecondsSinceEpoch);

  ///
  void writeFloat32(double val) {
    _reserveBytes(4);
    _byteData.setFloat32(_length, val);
    _length += 4;
  }

  ///
  void writeFloat64(double val) {
    _reserveBytes(8);
    _byteData.setFloat64(_length, val);
    _length += 8;
  }

  ///
  void writeInt16(int val) {
    _reserveBytes(2);
    _byteData.setInt16(_length, val);
    _length += 2;
  }

  ///
  void writeInt32(int val) {
    _reserveBytes(4);
    _byteData.setInt32(_length, val);
    _length += 4;
  }

  ///
  void writeInt64(int val) {
    _reserveBytes(8);
    _byteData.setInt64(_length, val);
    _length += 8;
  }

  ///
  void writeInt8(int val) {
    _reserveBytes(1);
    _byteData.setInt8(_length, val);
    _length += 1;
  }

  /// Функция записи списка объектов, где на каждый объект вызывается [func]
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество считываемых элементов, если известно
  void writeList<T>(
      List<T> val, void Function(T val, int i, MyBinaryWriter writer) func,
      {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    for (var i = 0; i < _l; i++) {
      func(val[i], i, this);
    }
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListFloat32AV(List<double> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(4);
    _reserveBytes(_l * 4);
    Float32List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 4;
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListFloat64AV(List<double> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(8);
    _reserveBytes(_l * 8);
    Float64List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 8;
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListInt16AV(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(2);
    _reserveBytes(_l * 2);
    Int16List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 2;
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListInt32AV(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(4);
    _reserveBytes(_l * 4);
    Int32List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 4;
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListInt64AV(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(8);
    _reserveBytes(_l * 8);
    Int64List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 8;
  }

  ///
  void writeListInt8(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(1);
    _reserveBytes(_l * 1);
    Int8List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 1;
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListUint16AV(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(2);
    _reserveBytes(_l * 2);
    Uint16List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 2;
  }

  /// {@macro atmos.binnaryWriter.av}
  void writeListUint32AV(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(4);
    _reserveBytes(_l * 4);
    Uint32List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 4;
  }

  /// {@template atmos.binnaryWriter.av}
  /// Запись списка чисел как отображение буффера.
  ///
  /// Происходит педварительное
  /// выравнивание указателя записи по размеру элемента.
  ///
  ///
  /// {@endtemplate}
  void writeListUint64AV(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(8);
    _reserveBytes(_l * 8);
    Uint64List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 8;
  }

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListUint64(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterUint64, csz: csz, size: size);
  static void _listWriteterUint64(int val, int i, MyBinaryWriter writer) =>
      writer.writeUint64(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListUint32(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterUint32, csz: csz, size: size);
  static void _listWriteterUint32(int val, int i, MyBinaryWriter writer) =>
      writer.writeUint32(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListUint16(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterUint16, csz: csz, size: size);
  static void _listWriteterUint16(int val, int i, MyBinaryWriter writer) =>
      writer.writeUint16(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListInt64(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterInt64, csz: csz, size: size);
  static void _listWriteterInt64(int val, int i, MyBinaryWriter writer) =>
      writer.writeInt64(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListInt32(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterInt32, csz: csz, size: size);
  static void _listWriteterInt32(int val, int i, MyBinaryWriter writer) =>
      writer.writeInt32(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListInt16(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterInt16, csz: csz, size: size);
  static void _listWriteterInt16(int val, int i, MyBinaryWriter writer) =>
      writer.writeInt16(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListFloat64(List<double> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterFloat64, csz: csz, size: size);
  static void _listWriteterFloat64(double val, int i, MyBinaryWriter writer) =>
      writer.writeFloat64(val);

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListFloat32(List<double> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriteterFloat32, csz: csz, size: size);
  static void _listWriteterFloat32(double val, int i, MyBinaryWriter writer) =>
      writer.writeFloat32(val);

  ///
  void writeListUint8(List<int> val, {int csz = 0, int? size}) {
    final _l = size ?? writeSize(val.length, csz);
    if (_l == 0) return;
    align(1);
    _reserveBytes(_l * 1);
    Uint8List.view(_buffer.buffer, _length).setAll(0, val);
    _length += _l * 1;
  }

  /// Записывает строку
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество записываемых байт, если известно
  /// * [encoder] - задаёт энкодер строки, по умолчанию стоит [Utf8Encoder]
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString(
    String val, {
    int csz = 0,
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeListUint8(encoder.convert(val), csz: csz, size: size);

  /// Укороченная запись записи строки через [writeString], с максимальной
  /// длинной в 256 байт.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString1(
    String val, {
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeString(val, size: size, encoder: encoder, csz: 1);

  /// Укороченная запись записи строки через [writeString], с максимальной
  /// длинной в 64 килобайт.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString2(
    String val, {
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeString(val, size: size, encoder: encoder, csz: 2);

  /// Укороченная запись записи строки через [writeString], с максимальной
  /// длинной в 4 гигабайта.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString3(
    String val, {
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeString(val, size: size, encoder: encoder, csz: 3);

  /// Записывает широкую строку, в кодировке UTF-16
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW(String val, {int csz = 0, int? size}) =>
      writeListUint16(val.codeUnits, csz: csz, size: size);

  /// Укороченная запись записи строки через [writeStringW], с максимальной
  /// длинной в 256 символов.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW1(
    String val, {
    int? size,
  }) =>
      writeStringW(val, size: size, csz: 1);

  /// Укороченная запись записи строки через [writeStringW], с максимальной
  /// длинной в 64 тысячи символов.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW2(
    String val, {
    int? size,
  }) =>
      writeStringW(val, size: size, csz: 2);

  /// Укороченная запись записи строки через [writeStringW], с максимальной
  /// длинной в 4 миллиарда символов.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW3(
    String val, {
    int? size,
  }) =>
      writeStringW(val, size: size, csz: 3);

  /// Записывает широкую строку, в кодировке UTF-16
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество записываемых байт, если известно
  ///
  /// {@macro atmos.binnaryWriter.av}
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV(String val, {int csz = 0, int? size}) =>
      writeListUint16AV(val.codeUnits, size: size, csz: csz);

  /// Укороченная запись записи строки через [writeStringW], с максимальной
  /// длинной в 256 символов.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV1(
    String val, {
    int? size,
  }) =>
      writeStringWV(val, size: size, csz: 1);

  /// Укороченная запись записи строки через [writeStringWV], с максимальной
  /// длинной в 64 тысячи символов.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV2(
    String val, {
    int? size,
  }) =>
      writeStringWV(val, size: size, csz: 2);

  /// Укороченная запись записи строки через [writeStringWV], с максимальной
  /// длинной в 4 миллиарда символов.
  /// * [size] - задаёт количество записываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV3(
    String val, {
    int? size,
  }) =>
      writeStringWV(val, size: size, csz: 3);

  ///
  void writeUint16(int val) {
    _reserveBytes(2);
    _byteData.setUint16(_length, val);
    _length += 2;
  }

  ///
  void writeUint32(int val) {
    _reserveBytes(4);
    _byteData.setUint32(_length, val);
    _length += 4;
  }

  ///
  void writeUint64(int val) {
    _reserveBytes(8);
    _byteData.setUint64(_length, val);
    _length += 8;
  }

  ///
  void writeUint8(int val) {
    _reserveBytes(1);
    _byteData.setUint8(_length, val);
    _length += 1;
  }

  void _grow(int required) {
    // We will create a list in the range of 2-4 times larger than
    // required.
    var newSize = required * 2;
    if (newSize < _initSize) {
      newSize = _initSize;
    } else {
      newSize = pow2roundup(newSize);
    }
    final newBuffer = Uint8List(newSize)..setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
    _byteDataInstance = null;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _reserveBytes(int byteCount) {
    if (byteCount == 0) return;
    final required = _length + byteCount;
    if (_buffer.length < required) {
      _grow(required);
    }
    assert(_buffer.length >= required, 'cant reserve bytes');
  }

  /// Записывает число как размер
  ///
  /// * [csz]=0 - специальная упаковка числа
  /// * [csz]=1 - [writeUint8]
  /// * [csz]=2 - [writeUint16]
  /// * [csz]=3 - [writeUint32]
  /// * [csz]=4 - [writeUint64]
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int writeSize(int count, [int csz = 0]) {
    assert(count >= 0, 'count cant be negative');
    assert(csz >= 0 && csz <= 4, 'CSZ incorrect');
    switch (csz) {
      case 0:
        var _count = count;
        while (_count >= 0x80) {
          writeUint8((_count & 0x7f) | 0x80);
          _count >>= 7;
        }
        writeUint8(_count);
        break;
      case 1:
        writeUint8(count);
        break;
      case 2:
        writeUint16(count);
        break;
      case 3:
        writeUint32(count);
        break;
      case 4:
        writeUint64(count);
        break;
    }
    return count;
  }

  /// Выравнивание указателя чтения до кратного значения байт
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void align(int bytes) {
    if (bytes == 1) return;
    assert(
        bytes == pow2roundup(bytes), 'Указано не кратное степени 2 значение');
    final _n = bytes - (_length & (bytes - 1));
    if (_n == bytes) {
      return;
    }
    skip(_n);
  }

  /// Пропускает некоторое количество байт.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int bytes) {
    _reserveBytes(bytes);
    // Uint8List.view(_buffer.buffer, _length).fillRange(0, bytes, 0);
    _length += bytes;
  }
}
