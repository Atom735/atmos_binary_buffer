import 'dart:convert';
import 'dart:typed_data';

import 'bfloat16.dart';
import 'float16.dart';
import 'utils.dart';

/// {@template atmos.binaryReader.scalar.en}
/// Reads one scalar value from the current offset and advances it by value
/// size.
/// {@endtemplate}
///
/// {@template atmos.binaryReader.scalar.ru}
/// Считывает одно скалярное значение из текущей позиции и сдвигает указатель
/// на размер значения.
/// {@endtemplate}
// ignore: unused_element
const Object? _binaryReaderScalarDocTemplate = null;

/// {@template atmos.binaryReader.floatAliases.en}
/// Short aliases:
/// - `rF16`, `rF32`, `rF64` for float values.
/// - `rBF16` for bfloat16.
/// {@endtemplate}
///
/// {@template atmos.binaryReader.floatAliases.ru}
/// Короткие алиасы:
/// - `rF16`, `rF32`, `rF64` для float-значений.
/// - `rBF16` для bfloat16.
/// {@endtemplate}
// ignore: unused_element
const Object? _binaryReaderFloatAliasesDocTemplate = null;

/// {@template atmos.binaryReader.list.en}
/// Reads a list using `csz` as encoded length size unless `size` is provided
/// explicitly.
/// {@endtemplate}
///
/// {@template atmos.binaryReader.list.ru}
/// Считывает список, используя `csz` как размер кодирования длины, если
/// `size` не задан явно.
/// {@endtemplate}
// ignore: unused_element
const Object? _binaryReaderListDocTemplate = null;

/// {@template atmos.binaryReader.av.en}
/// Reads numeric list as a typed view over the underlying buffer.
/// The read pointer is aligned to the element size before reading.
/// Returned list references this reader buffer; while that list is alive,
/// underlying buffer memory also stays alive.
/// {@endtemplate}
///
/// {@template atmos.binaryReader.av.ru}
/// Считывает список чисел как типизированное представление исходного буфера.
/// Перед чтением указатель выравнивается по размеру элемента.
/// Возвращённый список ссылается на буфер ридера; пока список жив, память
/// буфера также остаётся занятой.
/// {@endtemplate}
// ignore: unused_element
const Object? _binaryReaderAvDocTemplate = null;

/// ## BinaryReader
///
/// Reader over a binary buffer with helpers for primitive values,
/// strings, packed integers, and typed lists.
///
/// Ридер поверх бинарного буфера с методами для примитивных значений,
/// строк, упакованных целых и типизированных списков.
class BinaryReader {
  /// Creates a reader over [buffer].
  ///
  /// Создаёт ридер поверх [buffer].
  BinaryReader(Uint8List buffer, [Endian endian = Endian.big])
      : this._(buffer, endian);

  /// Creates a reader over [data] preserving its visible byte range.
  ///
  /// Создаёт ридер поверх [data] с сохранением видимого диапазона байтов.
  BinaryReader.fromTypedData(TypedData data, [Endian endian = Endian.big])
      : this._(
          Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes),
          endian,
        );

  /// Creates a reader over [buffer].
  ///
  /// Creates a full-range reader when [offsetInBytes] and [lengthInBytes] are
  /// omitted.
  ///
  /// Создаёт ридер поверх [buffer].
  ///
  /// Если [offsetInBytes] и [lengthInBytes] не заданы, используется весь
  /// диапазон буфера.
  BinaryReader.fromByteBuffer(
    ByteBuffer buffer, {
    Endian endian = Endian.big,
    int offsetInBytes = 0,
    int? lengthInBytes,
  }) : this._(
          Uint8List.view(buffer, offsetInBytes,
              lengthInBytes ?? (buffer.lengthInBytes - offsetInBytes)),
          endian,
        );

  BinaryReader._(this._buffer, [this.endian = Endian.big])
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes),
        _byteDataOffset = _buffer.offsetInBytes;

  /// Количество считанных байт в буффере
  int _offset = 0;

  /// Active byte order used for multi-byte values.
  ///
  /// Активный порядок байтов, используемый для многобайтовых значений.
  Endian endian;

  /// Количество считанных байт в буффере
  final int _byteDataOffset;

  final ByteData _byteData;

  /// Internal buffer accumulating bytes.
  final Uint8List _buffer;

  /// Current read offset in bytes.
  ///
  /// Текущее смещение чтения в байтах.
  int get offset => _offset;

  /// Sets current read offset.
  ///
  /// Устанавливает текущее смещение чтения.
  set offset(int val) {
    if (_buffer.length < val || val < 0) {
      throw RangeError('Not enough bytes available.');
    }
    _offset = val;
  }

  /// Remaining bytes available for reading.
  ///
  /// Количество оставшихся байт, доступных для чтения.
  int get peek => _buffer.length - _offset;

  static final _emptyBuffer = Uint8List.fromList(const []).buffer;

  /// Reads Unix epoch milliseconds as [DateTime].
  ///
  /// Считывает миллисекунды Unix epoch как [DateTime].
  DateTime readDateTime() => DateTime.fromMillisecondsSinceEpoch(readInt64());

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads IEEE 754 `float32`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает IEEE 754 `float32`.
  double readFloat32() {
    _reserveBytes(4);
    _offset += 4;
    return _byteData.getFloat32(_offset - 4, endian);
  }

  double f32() => readFloat32();

  /// Short alias for [readFloat32].
  ///
  /// Короткий алиас для [readFloat32].
  double rF32() => readFloat32();

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads IEEE 754 `float64`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает IEEE 754 `float64`.
  double readFloat64() {
    _reserveBytes(8);
    _offset += 8;
    return _byteData.getFloat64(_offset - 8, endian);
  }

  double f64() => readFloat64();

  /// {@macro atmos.binaryReader.floatAliases.en}
  ///
  /// {@macro atmos.binaryReader.floatAliases.ru}
  double rF64() => readFloat64();

  /// Reads IEEE 754 `binary16` (`float16`) from `uint16`.
  ///
  /// Считывает IEEE 754 `binary16` (`float16`) из `uint16`.
  double readFloat16() => float16ToDouble(readUint16());

  /// {@macro atmos.binaryReader.floatAliases.en}
  ///
  /// {@macro atmos.binaryReader.floatAliases.ru}
  double rF16() => readFloat16();

  /// Reads `bfloat16` from `uint16`.
  ///
  /// Считывает `bfloat16` из `uint16`.
  double readBFloat16() => bFloat16ToDouble(readUint16());

  /// {@macro atmos.binaryReader.floatAliases.en}
  ///
  /// {@macro atmos.binaryReader.floatAliases.ru}
  double rBF16() => readBFloat16();

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads signed `int16`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает знаковый `int16`.
  int readInt16() {
    _reserveBytes(2);
    _offset += 2;
    return _byteData.getInt16(_offset - 2, endian);
  }

  int i16() => readInt16();

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads signed `int32`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает знаковый `int32`.
  int readInt32() {
    _reserveBytes(4);
    _offset += 4;
    return _byteData.getInt32(_offset - 4, endian);
  }

  int i32() => readInt32();

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads signed `int64`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает знаковый `int64`.
  int readInt64() {
    _reserveBytes(8);
    _offset += 8;
    return _byteData.getInt64(_offset - 8, endian);
  }

  int i64() => readInt64();

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads signed `int8`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает знаковый `int8`.
  int readInt8() {
    _reserveBytes(1);
    _offset += 1;
    return _byteData.getInt8(_offset - 1);
  }

  int i8() => readInt8();

  /// ### Read signed integer by byte width
  ///
  /// Shortcut for reading signed integers with width `1/2/4/8` bytes.
  ///
  /// ### Считывание знакового целого по ширине
  ///
  /// Сокращённый метод чтения знаковых целых шириной `1/2/4/8` байт.
  int rI([int width = 4]) {
    switch (width) {
      case 1:
        return readInt8();
      case 2:
        return readInt16();
      case 4:
        return readInt32();
      case 8:
        return readInt64();
      default:
        throw ArgumentError.value(width, 'width', 'Expected 1, 2, 4 or 8');
    }
  }

  /// ### Read unsigned integer by byte width
  ///
  /// Shortcut for reading unsigned integers with width `1/2/4/8`
  /// bytes.
  ///
  /// ### Считывание беззнакового целого по ширине
  ///
  /// Сокращённый метод чтения беззнаковых целых шириной `1/2/4/8`
  /// байт.
  int rU([int width = 4]) {
    switch (width) {
      case 1:
        return readUint8();
      case 2:
        return readUint16();
      case 4:
        return readUint32();
      case 8:
        return readUint64();
      default:
        throw ArgumentError.value(width, 'width', 'Expected 1, 2, 4 or 8');
    }
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Float32List readListFloat32AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Float32List.view(_emptyBuffer, 0, 0);
    align(4);
    _reserveBytes(l * 4);
    _offset += l * 4;
    return Float32List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 4, l);
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Float64List readListFloat64AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Float64List.view(_emptyBuffer, 0, 0);
    align(8);
    _reserveBytes(l * 8);
    _offset += l * 8;
    return Float64List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 8, l);
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Int16List readListInt16AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int16List.view(_emptyBuffer, 0, 0);
    align(2);
    _reserveBytes(l * 2);
    _offset += l * 2;
    return Int16List.view(_buffer.buffer, _offset + _byteDataOffset - l * 2, l);
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Int32List readListInt32AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int32List.view(_emptyBuffer, 0, 0);
    align(4);
    _reserveBytes(l * 4);
    _offset += l * 4;
    return Int32List.view(_buffer.buffer, _offset + _byteDataOffset - l * 4, l);
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Int64List readListInt64AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int64List.view(_emptyBuffer, 0, 0);
    align(8);
    _reserveBytes(l * 8);
    _offset += l * 8;
    return Int64List.view(_buffer.buffer, _offset + _byteDataOffset - l * 8, l);
  }

  /// Reads `int8` list as a typed view over source buffer.
  ///
  /// Считывает список `int8` как типизированное представление буфера.
  Int8List readListInt8({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Int8List.view(_emptyBuffer, 0, 0);
    align(1);
    _reserveBytes(l * 1);
    _offset += l * 1;
    return Int8List.view(_buffer.buffer, _offset + _byteDataOffset - l * 1, l);
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Uint16List readListUint16AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint16List.view(_emptyBuffer, 0, 0);
    align(2);
    _reserveBytes(l * 2);
    _offset += l * 2;
    return Uint16List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 2, l);
  }

  /// {@macro atmos.binaryReader.av.en}
  ///
  /// {@macro atmos.binaryReader.av.ru}
  Uint32List readListUint32AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint32List.view(_emptyBuffer, 0, 0);
    align(4);
    _reserveBytes(l * 4);
    _offset += l * 4;
    return Uint32List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 4, l);
  }

  Uint64List readListUint64AV({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint64List.view(_emptyBuffer, 0, 0);
    align(8);
    _reserveBytes(l * 8);
    _offset += l * 8;
    return Uint64List.view(
        _buffer.buffer, _offset + _byteDataOffset - l * 8, l);
  }

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `uint8` list as a typed view over source buffer.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `uint8` как типизированное представление буфера.
  Uint8List readListUint8({int csz = 0, int? size}) {
    final l = size ?? readSize(csz);
    if (l == 0) return Uint8List.view(_emptyBuffer, 0, 0);
    align(1);
    _reserveBytes(l * 1);
    _offset += l * 1;
    return Uint8List.view(_buffer.buffer, _offset + _byteDataOffset - l * 1, l);
  }

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `uint16` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `uint16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListUint16({int csz = 0, int? size}) =>
      readList(_listReaderUint16, csz: csz, size: size);
  static int _listReaderUint16(int i, BinaryReader m) => m.readUint16();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `int16` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `int16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListInt16({int csz = 0, int? size}) =>
      readList(_listReaderInt16, csz: csz, size: size);
  static int _listReaderInt16(int i, BinaryReader m) => m.readInt16();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `uint32` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `uint32`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListUint32({int csz = 0, int? size}) =>
      readList(_listReaderUint32, csz: csz, size: size);
  static int _listReaderUint32(int i, BinaryReader m) => m.readUint32();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `int32` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `int32`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListInt32({int csz = 0, int? size}) =>
      readList(_listReaderInt32, csz: csz, size: size);
  static int _listReaderInt32(int i, BinaryReader m) => m.readInt32();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `uint64` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `uint64`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListUint64({int csz = 0, int? size}) =>
      readList(_listReaderUint64, csz: csz, size: size);
  static int _listReaderUint64(int i, BinaryReader m) => m.readUint64();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `int64` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `int64`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListInt64({int csz = 0, int? size}) =>
      readList(_listReaderInt64, csz: csz, size: size);
  static int _listReaderInt64(int i, BinaryReader m) => m.readInt64();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `float32` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `float32`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<double> readListFloat32({int csz = 0, int? size}) =>
      readList(_listReaderFloat32, csz: csz, size: size);
  static double _listReaderFloat32(int i, BinaryReader m) => m.readFloat32();

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads `float64` list.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список `float64`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<double> readListFloat64({int csz = 0, int? size}) =>
      readList(_listReaderFloat64, csz: csz, size: size);
  static double _listReaderFloat64(int i, BinaryReader m) => m.readFloat64();

  /// ### Read list of `float16`
  ///
  /// Reads a list where each element is IEEE 754 `binary16`.
  ///
  /// ### Считывание списка `float16`
  ///
  /// Считывает список, где каждый элемент — IEEE 754 `binary16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<double> readListFloat16({int csz = 0, int? size}) =>
      readList(_listReaderFloat16, csz: csz, size: size);
  static double _listReaderFloat16(int i, BinaryReader m) => m.readFloat16();

  /// ### Read list of `bfloat16`
  ///
  /// Reads a list where each element is `bfloat16`.
  ///
  /// ### Считывание списка `bfloat16`
  ///
  /// Считывает список, где каждый элемент — `bfloat16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<double> readListBFloat16({int csz = 0, int? size}) =>
      readList(_listReaderBFloat16, csz: csz, size: size);
  static double _listReaderBFloat16(int i, BinaryReader m) => m.readBFloat16();

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

  /// Reads UTF-16 wide string where characters are encoded as code units.
  /// * [csz] defines encoded length size (ignored when [size] is provided).
  /// * [size] defines number of code units when it is known.
  ///
  /// {@macro atmos.binaryReader.av.en}
  ///
  /// Считывает широкую строку, где символы предоставлены в кодировке UTF-16.
  /// * [csz] задаёт размер данных о длине (игнорируется, если задана [size]).
  /// * [size] задаёт количество считываемых пар байт, если известно.
  ///
  /// {@macro atmos.binaryReader.av.ru}
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

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads unsigned `uint8`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает беззнаковый `uint8`.
  int readUint8() {
    _reserveBytes(1);
    _offset += 1;
    return _byteData.getUint8(_offset - 1);
  }

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads unsigned `uint16`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает беззнаковый `uint16`.
  int readUint16() {
    _reserveBytes(2);
    _offset += 2;
    return _byteData.getUint16(_offset - 2, endian);
  }

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads unsigned `uint32`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает беззнаковый `uint32`.
  int readUint32() {
    _reserveBytes(4);
    _offset += 4;
    return _byteData.getUint32(_offset - 4, endian);
  }

  /// {@macro atmos.binaryReader.scalar.en}
  ///
  /// Reads unsigned `uint64`.
  ///
  /// {@macro atmos.binaryReader.scalar.ru}
  ///
  /// Считывает беззнаковый `uint64`.
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
  /// {@macro atmos.binaryBuffer.packInt}
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

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads list of packed sizes.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список упакованных размеров.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  List<int> readListSize({int csz = 0, int? size}) =>
      readList(_listReaderSize, csz: csz, size: size);
  static int _listReaderSize(int i, BinaryReader m) => m.readSize();

  /// Считывает запакованное целое число
  ///
  /// {@macro atmos.binaryBuffer.packInt}
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readPackedInt() {
    final i = readSize();
    // Zigzag decoding: (n >> 1) ^ (-(n & 1))
    // Используем >> вместо >>> для веб-совместимости
    // Это эквивалентно: если младший бит = 0, то (i >> 1)
    // если младший бит = 1, то ~(i >> 1)
    return (i >> 1) ^ (-(i & 1));
  }

  /// {@macro atmos.binaryReader.list.en}
  ///
  /// Reads list of zigzag-packed signed integers.
  ///
  /// {@macro atmos.binaryReader.list.ru}
  ///
  /// Считывает список знаковых целых в zigzag-упаковке.
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
