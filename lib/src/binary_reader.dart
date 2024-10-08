import 'dart:convert';
import 'dart:typed_data';

import 'utils.dart';

/// Binary buffer reader, for read data from buffer.
///
/// @RU Класс для чтения данных из байт-буффера для чтения различных данных.
class BinaryReader {
  /// Создаёт ридер для чтения байтового буффера переданного в [buffer]
  factory BinaryReader(Uint8List buffer, [Endian endian]) = BinaryReader._;

  BinaryReader._(this._buffer, [this.endian = Endian.big])
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes),
        _byteDataOffset = _buffer.offsetInBytes;

  /// Количество считанных байт в буффере
  int _offset = 0;

  Endian endian;

  /// Количество считанных байт в буффере
  final int _byteDataOffset;

  final ByteData _byteData;

  /// Internal buffer accumulating bytes.
  final Uint8List _buffer;

  /// Количество считанных байт в буффере
  int get offset => _offset;

  /// Количество считанных байт в буффере
  set offset(int val) {
    if (_buffer.length < val || val < 0) {
      throw RangeError('Not enough bytes available.');
    }
    _offset = val;
  }

  /// Количество оставшихся байт в буффере
  int get peek => _buffer.length - _offset;

  static final _emptyBuffer = Uint8List.fromList(const []).buffer;

  ///
  DateTime readDateTime() => DateTime.fromMillisecondsSinceEpoch(readInt64());

  ///
  double readFloat32() {
    _reserveBytes(4);
    _offset += 4;
    return _byteData.getFloat32(_offset - 4, endian);
  }

  ///
  double readFloat64() {
    _reserveBytes(8);
    _offset += 8;
    return _byteData.getFloat64(_offset - 8, endian);
  }

  ///
  int readInt16() {
    _reserveBytes(2);
    _offset += 2;
    return _byteData.getInt16(_offset - 2, endian);
  }

  ///
  int readInt32() {
    _reserveBytes(4);
    _offset += 4;
    return _byteData.getInt32(_offset - 4, endian);
  }

  ///
  int readInt64() {
    _reserveBytes(8);
    _offset += 8;
    return _byteData.getInt64(_offset - 8, endian);
  }

  ///
  int readInt8() {
    _reserveBytes(1);
    _offset += 1;
    return _byteData.getInt8(_offset - 1);
  }

  /// {@macro atmos.binnaryReader.av}
  Float32List readListFloat32AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Float32List.view(_emptyBuffer, 0, 0);
    align(4);
    _reserveBytes(l * 4);
    _offset += l * 4;
    return Float32List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 4, l);
  }

  /// {@macro atmos.binnaryReader.av}
  Float64List readListFloat64AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Float64List.view(_emptyBuffer, 0, 0);
    align(8);
    _reserveBytes(l * 8);
    _offset += l * 8;
    return Float64List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 8, l);
  }

  /// {@macro atmos.binnaryReader.av}
  Int16List readListInt16AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int16List.view(_emptyBuffer, 0, 0);
    align(2);
    _reserveBytes(l * 2);
    _offset += l * 2;
    return Int16List.view(_buffer.buffer, _offset + _byteDataOffset - l * 2, l);
  }

  /// {@macro atmos.binnaryReader.av}
  Int32List readListInt32AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int32List.view(_emptyBuffer, 0, 0);
    align(4);
    _reserveBytes(l * 4);
    _offset += l * 4;
    return Int32List.view(_buffer.buffer, _offset + _byteDataOffset - l * 4, l);
  }

  /// {@macro atmos.binnaryReader.av}
  Int64List readListInt64AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int64List.view(_emptyBuffer, 0, 0);
    align(8);
    _reserveBytes(l * 8);
    _offset += l * 8;
    return Int64List.view(_buffer.buffer, _offset + _byteDataOffset - l * 8, l);
  }

  ///
  Int8List readListInt8({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int8List.view(_emptyBuffer, 0, 0);
    align(1);
    _reserveBytes(l * 1);
    _offset += l * 1;
    return Int8List.view(_buffer.buffer, _offset + _byteDataOffset - l * 1, l);
  }

  /// {@macro atmos.binnaryReader.av}
  Uint16List readListUint16AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint16List.view(_emptyBuffer, 0, 0);
    align(2);
    _reserveBytes(l * 2);
    _offset += l * 2;
    return Uint16List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 2, l);
  }

  /// {@macro atmos.binnaryReader.av}
  Uint32List readListUint32AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint32List.view(_emptyBuffer, 0, 0);
    align(4);
    _reserveBytes(l * 4);
    _offset += l * 4;
    return Uint32List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 4, l);
  }

  /// {@template atmos.binnaryReader.av}
  /// Считывание списка чисел как отображение буффера.
  ///
  /// Происходит педварительное
  /// выравнивание указателя чтения по размеру элемента.
  ///
  /// Полученный список ссылается на буффер этого ридера, так что
  /// пока возвращённый список не освобдится, данные буффера этого ридера тоже
  /// не будут освобождены.
  /// {@endtemplate}
  Uint64List readListUint64AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint64List.view(_emptyBuffer, 0, 0);
    align(8);
    _reserveBytes(l * 8);
    _offset += l * 8;
    return Uint64List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 8, l);
  }

  ///
  Uint8List readListUint8({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint8List.view(_emptyBuffer, 0, 0);
    align(1);
    _reserveBytes(l * 1);
    _offset += l * 1;
    return Uint8List.view(_buffer.buffer, _offset + _byteDataOffset - l * 1, l);
  }

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListUint16({int csz = 0, int? size}) =>
      readList(_listReaderUint16, csz: csz, size: size);
  static int _listReaderUint16(int i, BinaryReader m) => m.readUint16();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListInt16({int csz = 0, int? size}) =>
      readList(_listReaderInt16, csz: csz, size: size);
  static int _listReaderInt16(int i, BinaryReader m) => m.readInt16();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListUint32({int csz = 0, int? size}) =>
      readList(_listReaderUint32, csz: csz, size: size);
  static int _listReaderUint32(int i, BinaryReader m) => m.readUint32();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListInt32({int csz = 0, int? size}) =>
      readList(_listReaderInt32, csz: csz, size: size);
  static int _listReaderInt32(int i, BinaryReader m) => m.readInt32();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListUint64({int csz = 0, int? size}) =>
      readList(_listReaderUint64, csz: csz, size: size);
  static int _listReaderUint64(int i, BinaryReader m) => m.readUint64();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListInt64({int csz = 0, int? size}) =>
      readList(_listReaderInt64, csz: csz, size: size);
  static int _listReaderInt64(int i, BinaryReader m) => m.readInt64();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<double> readListFloat32({int csz = 0, int? size}) =>
      readList(_listReaderFloat32, csz: csz, size: size);
  static double _listReaderFloat32(int i, BinaryReader m) => m.readFloat32();

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<double> readListFloat64({int csz = 0, int? size}) =>
      readList(_listReaderFloat64, csz: csz, size: size);
  static double _listReaderFloat64(int i, BinaryReader m) => m.readFloat64();

  /// Функция чтения списка объектов, где на каждый объект вызывается [func]
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество считываемых элементов, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<T> readList<T>(
    T Function(int i, BinaryReader reader) func, {
    int csz = 0,
    int? size,
  }) {
    final l = size ?? readSize(csz);
    return List<T>.generate(l, (i) => func(i, this));
  }

  /// Считывает строку
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество считываемых байт, если известно
  /// * [decoder] - задаёт декодер строки, по умолчанию стоит [Utf8Decoder]
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readString({
    int csz = 0,
    int? size,
    Converter<List<int>, String> decoder = const Utf8Decoder(),
  }) =>
      decoder.convert(readListUint8(size: size, csz: csz));

  /// Укороченная запись считывания строки через [readString], с максимальной
  /// длинной в 256 байт.
  /// * [size] - задаёт количество считываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readString1({
    int? size,
    Converter<List<int>, String> decoder = const Utf8Decoder(),
  }) =>
      readString(size: size, decoder: decoder, csz: 1);

  /// Укороченная запись считывания строки через [readString], с максимальной
  /// длинной в 64 килобайт.
  /// * [size] - задаёт количество считываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readString2({
    int? size,
    Converter<List<int>, String> decoder = const Utf8Decoder(),
  }) =>
      readString(size: size, decoder: decoder, csz: 2);

  /// Укороченная запись считывания строки через [readString], с максимальной
  /// длинной в 4 гигабайта.
  /// * [size] - задаёт количество считываемых байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readString3({
    int? size,
    Converter<List<int>, String> decoder = const Utf8Decoder(),
  }) =>
      readString(size: size, decoder: decoder, csz: 3);

  /// Считывает широкую строку, где символы предоставлены в кодировке UTF-16
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringW({int csz = 0, int? size}) =>
      String.fromCharCodes(readListUint16(size: size, csz: csz));

  /// Считывает широкую строку, где символы предоставлены в кодировке UTF-16
  /// * [csz] - задаёт размер данных о длине (игнорируется если задана [size])
  /// * [size] - задаёт количество считываемых пар байт, если известно
  ///
  /// {@macro atmos.binnaryReader.av}
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringWV({int csz = 0, int? size}) =>
      String.fromCharCodes(readListUint16AV(size: size, csz: csz));

  /// Укороченная запись считывания строки через [readStringW], с максимальной
  /// длинной в 256 символов.
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringW1({int? size}) => readStringW(size: size, csz: 1);

  /// Укороченная запись считывания строки через [readStringW], с максимальной
  /// длинной в 64 тысячи символов.
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringW2({int? size}) => readStringW(size: size, csz: 2);

  /// Укороченная запись считывания строки через [readStringW], с максимальной
  /// длинной в 4 миллиарда символов.
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringW3({int? size}) => readStringW(size: size, csz: 3);

  /// Укороченная запись считывания строки через [readStringWV], с максимальной
  /// длинной в 256 символов.
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringWV1({int? size}) => readStringWV(size: size, csz: 1);

  /// Укороченная запись считывания строки через [readStringWV], с максимальной
  /// длинной в 64 тысячи символов.
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringWV2({int? size}) => readStringWV(size: size, csz: 2);

  /// Укороченная запись считывания строки через [readStringWV], с максимальной
  /// длинной в 4 миллиарда символов.
  /// * [size] - задаёт количество считываемых пар байт, если известно
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringWV3({int? size}) => readStringWV(size: size, csz: 3);

  ///
  int readUint8() {
    _reserveBytes(1);
    _offset += 1;
    return _byteData.getUint8(_offset - 1);
  }

  ///
  int readUint16() {
    _reserveBytes(2);
    _offset += 2;
    return _byteData.getUint16(_offset - 2, endian);
  }

  ///
  int readUint32() {
    _reserveBytes(4);
    _offset += 4;
    return _byteData.getUint32(_offset - 4, endian);
  }

  ///
  int readUint64() {
    _reserveBytes(8);
    _offset += 8;
    return _byteData.getUint64(_offset - 8, endian);
  }

  /// Пропустить несколько байт
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int bytes) {
    _reserveBytes(bytes);
    _offset += bytes;
  }

  /// Считывает число как размер
  ///
  /// * [csz]=0 - специальная упаковка числа
  /// * [csz]=1 - [readUint8]
  /// * [csz]=2 - [readUint16]
  /// * [csz]=3 - [readUint32]
  /// * [csz]=4 - [readUint64]
  ///
  /// {@macro atmos.binnaryBuffer.packInt}
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readSize([int csz = 0]) {
    assert(csz >= 0 && csz <= 4, 'CSZ incorrect');
    switch (csz) {
      case 0:
        final byte = readUint8();
        if (byte & 0x80 == 0) return byte;
        var a = readUint8();
        if (byte & 0xC0 == 0x80) {
          return ((byte ^ 0x80) << 8) | a;
        }
        a = readUint8() | (a << 8);
        if (byte & 0xE0 == 0xC0) {
          return ((byte ^ 0xC0) << 16) | a;
        }
        a = readUint8() | (a << 8);
        if (byte & 0xF0 == 0xE0) {
          return ((byte ^ 0xE0) << 24) | a;
        }
        a = readUint8() | (a << 8);
        if (byte & 0xF8 == 0xF0) {
          return ((byte ^ 0xF0) << 32) | a;
        }
        a = readUint8() | (a << 8);
        if (byte & 0xFC == 0xF8) {
          return ((byte ^ 0xF8) << 40) | a;
        }
        a = readUint8() | (a << 8);
        if (byte & 0xFE == 0xFC) {
          return ((byte ^ 0xFC) << 48) | a;
        }
        a = readUint8() | (a << 8);
        if (byte == 0xFE) {
          return ((byte ^ 0xFE) << 56) | a;
        }
        return readUint8() | (a << 8);
      case 1:
        return readUint8();
      case 2:
        return readUint16();
      case 3:
        return readUint32();
      case 4:
        return readUint64();
    }
    return -1;
  }

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListSize({int csz = 0, int? size}) =>
      readList(_listReaderSize, csz: csz, size: size);
  static int _listReaderSize(int i, BinaryReader m) => m.readSize();

  /// Считывает запакованное целое число
  ///
  /// {@macro atmos.binnaryBuffer.packInt}
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readPackedInt() {
    final i = readSize();
    if (i & 1 == 1) {
      return (i >>> 1) ^ 0xffffffffffffffff;
    }
    return i >>> 1;
  }

  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListPackedInt({int csz = 0, int? size}) =>
      readList(_listReaderPackedInt, csz: csz, size: size);
  static int _listReaderPackedInt(int i, BinaryReader m) => m.readPackedInt();

  /// Выравнивание указателя чтения до кратного значения байт
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void align(int bytes) {
    assert(
      bytes == pow2roundup(bytes),
      'Указано не кратное степени 2 значение',
    );
    final n = bytes - (_offset & (bytes - 1));
    if (n == bytes) {
      return;
    }
    skip(n);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _reserveBytes(int byteCount) {
    if (byteCount == 0) return;
    final required = _offset + byteCount;
    assert(_buffer.length >= required, 'cant reserve bytes');
  }
}
