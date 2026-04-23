import 'dart:convert';
import 'dart:typed_data';

import 'bfloat16.dart';
import 'float16.dart';
import 'utils.dart';

/// ## BinaryWriter
/// Writer for a growable binary buffer with helpers for primitive
/// values, strings, packed integers, and typed lists.
///
/// Писатель для расширяемого бинарного буфера с методами для
/// примитивных значений, строк, упакованных целых и типизированных списков.
class BinaryWriter implements BytesBuilder {
  /// Creates writer with optional [endian].
  ///
  /// Создаёт writer с опциональным [endian].
  BinaryWriter([Endian endian = Endian.big]) : this._(_emptyList, endian);

  /// Creates writer over an existing [buffer].
  ///
  /// Создаёт writer поверх существующего [buffer].
  BinaryWriter.withBuffer(Uint8List buffer, [Endian endian = Endian.big])
      : this._(buffer, endian);

  /// Creates writer over an existing [data].
  ///
  /// Создаёт writer поверх существующего [data].
  BinaryWriter.withTypedData(TypedData data, [Endian endian = Endian.big])
      : this._(
          Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes),
          endian,
        );

  /// Creates writer over an existing [buffer].
  ///
  /// Создаёт writer поверх существующего [buffer].
  BinaryWriter.withByteBuffer(
    ByteBuffer buffer, {
    Endian endian = Endian.big,
    int offsetInBytes = 0,
    int? lengthInBytes,
  }) : this._(
            Uint8List.view(buffer, offsetInBytes,
                lengthInBytes ?? (buffer.lengthInBytes - offsetInBytes)),
            endian);

  BinaryWriter._(this._buffer, [this.endian = Endian.big]);

  Endian endian;

  /// Initial buffer size.
  ///
  /// Начальный размер буффера.
  static const int _initSize = 1024;

  /// Reused empty [Uint8List] instance.
  ///
  /// Переиспользуемый пустой лист [Uint8List].
  static final _emptyList = Uint8List(0);

  /// Current count of bytes written to buffer.
  ///
  /// Текущее количество байт, записанных в буфер.
  int _length = 0;

  ByteData? _byteDataInstance;

  /// Internal buffer accumulating bytes.
  ///
  /// Will grow as necessary.
  ///
  /// Внутренний буфер, накапливающий байты.
  ///
  /// Растёт по мере необходимости.
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
    _byteDataInstance ??= ByteData.view(
      _buffer.buffer,
      _buffer.offsetInBytes,
    );
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
    final buffer = Uint8List.view(
      _buffer.buffer,
      _buffer.offsetInBytes,
      _length,
    );
    clear();
    return buffer;
  }

  @override
  Uint8List toBytes() {
    if (_length == 0) return _emptyList;
    return Uint8List.fromList(
      Uint8List.view(_buffer.buffer, _buffer.offsetInBytes, _length),
    );
  }

  /// {@template atmos.binaryWriter.scalar.en}
  /// Writes one scalar value at current position and advances internal length
  /// by value size.
  /// {@endtemplate}
  ///
  /// {@template atmos.binaryWriter.scalar.ru}
  /// Записывает одно скалярное значение в текущую позицию и сдвигает
  /// внутреннюю длину на размер значения.
  /// {@endtemplate}
  ///
  /// Writes [DateTime] as Unix epoch milliseconds.
  ///
  /// Записывает [DateTime] как миллисекунды Unix epoch.
  void writeDateTime(DateTime val) => writeInt64(val.millisecondsSinceEpoch);

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Writes IEEE 754 `float32`.
  ///
  /// Записывает IEEE 754 `float32`.
  void writeFloat32(double val) {
    _reserveBytes(4);
    _byteData.setFloat32(_length, val, endian);
    _length += 4;
  }

  /// {@template atmos.binaryWriter.floatAliases.en}
  /// Short aliases:
  /// - `wF16`, `wF32`, `wF64` for float values.
  /// - `wBF16` for bfloat16.
  /// {@endtemplate}
  ///
  /// {@template atmos.binaryWriter.floatAliases.ru}
  /// Короткие алиасы:
  /// - `wF16`, `wF32`, `wF64` для float-значений.
  /// - `wBF16` для bfloat16.
  /// {@endtemplate}
  ///
  /// Short alias for [writeFloat32].
  ///
  /// Короткий алиас для [writeFloat32].
  void wF32(double val) => writeFloat32(val);

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Writes IEEE 754 `float64`.
  ///
  /// Записывает IEEE 754 `float64`.
  void writeFloat64(double val) {
    _reserveBytes(8);
    _byteData.setFloat64(_length, val, endian);
    _length += 8;
  }

  /// {@macro atmos.binaryWriter.floatAliases.en}
  ///
  /// {@macro atmos.binaryWriter.floatAliases.ru}
  void wF64(double val) => writeFloat64(val);

  /// Writes IEEE 754 `binary16` (`float16`) as `uint16`.
  ///
  /// Записывает IEEE 754 `binary16` (`float16`) как `uint16`.
  void writeFloat16(double val) => writeUint16(doubleToFloat16(val));

  /// {@macro atmos.binaryWriter.floatAliases.en}
  ///
  /// {@macro atmos.binaryWriter.floatAliases.ru}
  void wF16(double val) => writeFloat16(val);

  /// Writes `bfloat16` as `uint16`.
  ///
  /// Записывает `bfloat16` как `uint16`.
  void writeBFloat16(double val) => writeUint16(doubleToBFloat16(val));

  /// {@macro atmos.binaryWriter.floatAliases.en}
  ///
  /// {@macro atmos.binaryWriter.floatAliases.ru}
  void wBF16(double val) => writeBFloat16(val);

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Writes signed `int16`.
  ///
  /// Записывает знаковый `int16`.
  void writeInt16(int val) {
    _reserveBytes(2);
    _byteData.setInt16(_length, val, endian);
    _length += 2;
  }

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Writes signed `int32`.
  ///
  /// Записывает знаковый `int32`.
  void writeInt32(int val) {
    _reserveBytes(4);
    _byteData.setInt32(_length, val, endian);
    _length += 4;
  }

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Writes signed `int64`.
  ///
  /// Записывает знаковый `int64`.
  void writeInt64(int val) {
    _reserveBytes(8);
    _byteData.setInt64(_length, val, endian);
    _length += 8;
  }

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Writes signed `int8`.
  ///
  /// Записывает знаковый `int8`.
  void writeInt8(int val) {
    _reserveBytes(1);
    _byteData.setInt8(_length, val);
    _length += 1;
  }

  /// {@template atmos.binaryWriter.intWidth.en}
  /// Supported byte widths are `1`, `2`, `4`, `8`.
  /// {@endtemplate}
  ///
  /// {@template atmos.binaryWriter.intWidth.ru}
  /// Поддерживаемые размеры в байтах: `1`, `2`, `4`, `8`.
  /// {@endtemplate}
  /// ### Write signed integer by byte width
  ///
  /// Shortcut for writing signed integers with width `1/2/4/8` bytes.
  ///
  /// {@macro atmos.binaryWriter.intWidth.en}
  ///
  /// ### Запись знакового целого по ширине в байтах
  ///
  /// Сокращённый метод записи знаковых целых шириной `1/2/4/8` байт.
  ///
  /// {@macro atmos.binaryWriter.intWidth.ru}
  void wI(int value, [int width = 4]) {
    switch (width) {
      case 1:
        writeInt8(value);
        return;
      case 2:
        writeInt16(value);
        return;
      case 4:
        writeInt32(value);
        return;
      case 8:
        writeInt64(value);
        return;
      default:
        throw ArgumentError.value(width, 'width', 'Expected 1, 2, 4 or 8');
    }
  }

  /// ### Write unsigned integer by byte width
  ///
  /// Shortcut for writing unsigned integers with width `1/2/4/8`
  /// bytes.
  ///
  /// {@macro atmos.binaryWriter.intWidth.en}
  ///
  /// ### Запись беззнакового целого по ширине в байтах
  ///
  /// Сокращённый метод записи беззнаковых целых шириной `1/2/4/8`
  /// байт.
  ///
  /// {@macro atmos.binaryWriter.intWidth.ru}
  void wU(int value, [int width = 4]) {
    switch (width) {
      case 1:
        writeUint8(value);
        return;
      case 2:
        writeUint16(value);
        return;
      case 4:
        writeUint32(value);
        return;
      case 8:
        writeUint64(value);
        return;
      default:
        throw ArgumentError.value(width, 'width', 'Expected 1, 2, 4 or 8');
    }
  }

  /// Writes a list and calls [func] for each item.
  /// * [csz] sets encoded length size (ignored when [size] is provided).
  /// * [size] sets number of written items when known in advance.
  ///
  /// Функция записи списка объектов, где на каждый объект вызывается [func].
  /// * [csz] задаёт размер данных о длине (игнорируется, если задана [size]).
  /// * [size] задаёт количество записываемых элементов, если известно.
  void writeList<T>(
    List<T> val,
    void Function(T val, int i, BinaryWriter writer) func, {
    int csz = 0,
    int? size,
  }) {
    final l = size ?? writeSize(val.length, csz);
    for (var i = 0; i < l; i++) {
      func(val[i], i, this);
    }
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListFloat32AV(List<double> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(4);
    _reserveBytes(l * 4);
    Float32List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 4;
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListFloat64AV(List<double> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(8);
    _reserveBytes(l * 8);
    Float64List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 8;
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListInt16AV(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(2);
    _reserveBytes(l * 2);
    Int16List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 2;
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListInt32AV(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(4);
    _reserveBytes(l * 4);
    Int32List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 4;
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListInt64AV(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(8);
    _reserveBytes(l * 8);
    Int64List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 8;
  }

  /// {@template atmos.binaryWriter.list.en}
  /// Writes a list using [csz] as encoded length size unless [size] is passed
  /// explicitly.
  /// {@endtemplate}
  ///
  /// {@template atmos.binaryWriter.list.ru}
  /// Записывает список, используя [csz] как размер кодирования длины, если
  /// [size] не задан явно.
  /// {@endtemplate}
  ///
  /// Writes `int8` list as typed view.
  ///
  /// Записывает список `int8` как типизированное представление.
  void writeListInt8(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(1);
    _reserveBytes(l * 1);
    Int8List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 1;
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListUint16AV(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(2);
    _reserveBytes(l * 2);
    Uint16List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 2;
  }

  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  void writeListUint32AV(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(4);
    _reserveBytes(l * 4);
    Uint32List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 4;
  }

  /// {@template atmos.binaryWriter.av.en}
  /// Writes numeric list through a typed view of the destination buffer.
  /// The write pointer is aligned to the element size before writing.
  /// {@endtemplate}
  ///
  /// {@template atmos.binaryWriter.av.ru}
  /// Записывает список чисел через типизированное представление целевого
  /// буфера. Перед записью указатель выравнивается по размеру элемента.
  /// {@endtemplate}
  void writeListUint64AV(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(8);
    _reserveBytes(l * 8);
    Uint64List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 8;
  }

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `uint64` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `uint64`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListUint64(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterUint64, csz: csz, size: size);
  static void _listWriterUint64(int val, int i, BinaryWriter writer) =>
      writer.writeUint64(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `uint32` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `uint32`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListUint32(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterUint32, csz: csz, size: size);
  static void _listWriterUint32(int val, int i, BinaryWriter writer) =>
      writer.writeUint32(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `uint16` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `uint16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListUint16(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterUint16, csz: csz, size: size);
  static void _listWriterUint16(int val, int i, BinaryWriter writer) =>
      writer.writeUint16(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `int64` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `int64`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListInt64(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterInt64, csz: csz, size: size);
  static void _listWriterInt64(int val, int i, BinaryWriter writer) =>
      writer.writeInt64(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `int32` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `int32`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListInt32(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterInt32, csz: csz, size: size);
  static void _listWriterInt32(int val, int i, BinaryWriter writer) =>
      writer.writeInt32(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `int16` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `int16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListInt16(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterInt16, csz: csz, size: size);
  static void _listWriterInt16(int val, int i, BinaryWriter writer) =>
      writer.writeInt16(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `float64` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `float64`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListFloat64(List<double> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterFloat64, csz: csz, size: size);
  static void _listWriterFloat64(double val, int i, BinaryWriter writer) =>
      writer.writeFloat64(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `float32` list.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `float32`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListFloat32(List<double> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterFloat32, csz: csz, size: size);
  static void _listWriterFloat32(double val, int i, BinaryWriter writer) =>
      writer.writeFloat32(val);

  /// ### Write list of `float16`
  ///
  /// Writes each element as IEEE 754 `binary16`.
  ///
  /// ### Запись списка `float16`
  ///
  /// Записывает каждый элемент как IEEE 754 `binary16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListFloat16(List<double> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterFloat16, csz: csz, size: size);
  static void _listWriterFloat16(double val, int i, BinaryWriter writer) =>
      writer.writeFloat16(val);

  /// ### Write list of `bfloat16`
  ///
  /// Writes each element as `bfloat16`.
  ///
  /// ### Запись списка `bfloat16`
  ///
  /// Записывает каждый элемент как `bfloat16`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListBFloat16(List<double> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterBFloat16, csz: csz, size: size);
  static void _listWriterBFloat16(double val, int i, BinaryWriter writer) =>
      writer.writeBFloat16(val);

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes `uint8` list as typed view.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список `uint8` как типизированное представление.
  void writeListUint8(List<int> val, {int csz = 0, int? size}) {
    final l = size ?? writeSize(val.length, csz);
    if (l == 0) return;
    align(1);
    _reserveBytes(l * 1);
    Uint8List.view(
      _buffer.buffer,
      _buffer.offsetInBytes + _length,
    ).setAll(0, val);
    _length += l * 1;
  }

  /// Writes a string.
  /// * [csz] sets encoded length size (ignored when [size] is provided).
  /// * [size] sets number of bytes to write when known in advance.
  /// * [encoder] sets string encoder, defaults to [Utf8Encoder].
  ///
  /// Записывает строку.
  /// * [csz] задаёт размер данных о длине (игнорируется, если задана [size]).
  /// * [size] задаёт количество записываемых байт, если известно.
  /// * [encoder] задаёт энкодер строки, по умолчанию [Utf8Encoder].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString(
    String val, {
    int csz = 0,
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeListUint8(encoder.convert(val), csz: csz, size: size);

  /// Short form of [writeString] with maximum length of 256 bytes.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeString], с максимальной
  /// длиной в 256 байт.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString1(
    String val, {
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeString(val, size: size, encoder: encoder, csz: 1);

  /// Short form of [writeString] with maximum length of 64 kilobytes.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeString], с максимальной
  /// длиной в 64 килобайта.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString2(
    String val, {
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeString(val, size: size, encoder: encoder, csz: 2);

  /// Short form of [writeString] with maximum length of 4 gigabytes.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeString], с максимальной
  /// длиной в 4 гигабайта.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeString3(
    String val, {
    int? size,
    Converter<String, List<int>> encoder = const Utf8Encoder(),
  }) =>
      writeString(val, size: size, encoder: encoder, csz: 3);

  /// Writes a wide string encoded as UTF-16.
  /// * [csz] sets encoded length size (ignored when [size] is provided).
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Записывает широкую строку в кодировке UTF-16.
  /// * [csz] задаёт размер данных о длине (игнорируется, если задана [size]).
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW(String val, {int csz = 0, int? size}) =>
      writeListUint16(val.codeUnits, csz: csz, size: size);

  /// Short form of [writeStringW] with maximum length of 256 symbols.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeStringW], с максимальной
  /// длиной в 256 символов.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW1(String val, {int? size}) =>
      writeStringW(val, size: size, csz: 1);

  /// Short form of [writeStringW] with maximum length of 64 thousand symbols.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeStringW], с максимальной
  /// длиной в 64 тысячи символов.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW2(String val, {int? size}) =>
      writeStringW(val, size: size, csz: 2);

  /// Short form of [writeStringW] with maximum length of 4 billion symbols.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeStringW], с максимальной
  /// длиной в 4 миллиарда символов.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringW3(String val, {int? size}) =>
      writeStringW(val, size: size, csz: 3);

  /// Writes a wide string encoded as UTF-16 through a typed view.
  /// * [csz] sets encoded length size (ignored when [size] is provided).
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// {@macro atmos.binaryWriter.av.en}
  ///
  /// Записывает широкую строку в кодировке UTF-16 через типизированное
  /// представление.
  /// * [csz] задаёт размер данных о длине (игнорируется, если задана [size]).
  /// * [size] задаёт количество записываемых байт, если известно.
  ///
  /// {@macro atmos.binaryWriter.av.ru}
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV(String val, {int csz = 0, int? size}) =>
      writeListUint16AV(val.codeUnits, size: size, csz: csz);

  /// Short form of [writeStringWV] with maximum length of 256 symbols.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeStringWV], с максимальной
  /// длиной в 256 символов.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV1(String val, {int? size}) =>
      writeStringWV(val, size: size, csz: 1);

  /// Short form of [writeStringWV] with maximum length of 64 thousand symbols.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeStringWV], с максимальной
  /// длиной в 64 тысячи символов.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV2(String val, {int? size}) =>
      writeStringWV(val, size: size, csz: 2);

  /// Short form of [writeStringWV] with maximum length of 4 billion symbols.
  /// * [size] sets number of bytes to write when known in advance.
  ///
  /// Укороченная запись строки через [writeStringWV], с максимальной
  /// длиной в 4 миллиарда символов.
  /// * [size] задаёт количество записываемых байт, если известно.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringWV3(String val, {int? size}) =>
      writeStringWV(val, size: size, csz: 3);

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// Writes unsigned `uint16`.
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Записывает беззнаковый `uint16`.
  void writeUint16(int val) {
    _reserveBytes(2);
    _byteData.setUint16(_length, val, endian);
    _length += 2;
  }

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// Writes unsigned `uint32`.
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Записывает беззнаковый `uint32`.
  void writeUint32(int val) {
    _reserveBytes(4);
    _byteData.setUint32(_length, val, endian);
    _length += 4;
  }

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// Writes unsigned `uint64`.
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Записывает беззнаковый `uint64`.
  void writeUint64(int val) {
    _reserveBytes(8);
    _byteData.setUint64(_length, val, endian);
    _length += 8;
  }

  /// {@macro atmos.binaryWriter.scalar.en}
  ///
  /// Writes unsigned `uint8`.
  ///
  /// {@macro atmos.binaryWriter.scalar.ru}
  ///
  /// Записывает беззнаковый `uint8`.
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

  /// Writes a number as encoded size.
  ///
  /// * [csz]=0 uses special compact packing.
  /// * [csz]=1 uses [writeUint8].
  /// * [csz]=2 uses [writeUint16].
  /// * [csz]=3 uses [writeUint32].
  /// * [csz]=4 uses [writeUint64].
  ///
  /// {@macro atmos.binaryBuffer.packInt}
  ///
  /// Записывает число как размер.
  ///
  /// * [csz]=0 - специальная упаковка числа.
  /// * [csz]=1 - [writeUint8].
  /// * [csz]=2 - [writeUint16].
  /// * [csz]=3 - [writeUint32].
  /// * [csz]=4 - [writeUint64].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int writeSize(int count, [int csz = 0]) {
    assert(count >= 0, 'count cant be negative');
    assert(csz >= 0 && csz <= 4, 'CSZ incorrect');
    switch (csz) {
      case 0:
        final n = count;
        if (n < 0x80) {
          writeUint8(n);
          return count;
        }
        if (n < 0x4000) {
          writeUint8(((n >> 8) & 0xFF) | 0x80);
          writeUint8(n & 0xFF);
          return count;
        }
        if (n < 0x200000) {
          writeUint8(((n >> 16) & 0xFF) | 0xC0);
          writeUint8((n >> 8) & 0xFF);
          writeUint8(n & 0xFF);
          return count;
        }

        if (n < 0x10000000) {
          writeUint8(((n >> 24) & 0xFF) | 0xE0);
          writeUint8((n >> 16) & 0xFF);
          writeUint8((n >> 8) & 0xFF);
          writeUint8(n & 0xFF);
          return count;
        }

        if (n < 0x0800000000) {
          writeUint8(((n >> 32) & 0xFF) | 0xF0);
          writeUint8((n >> 24) & 0xFF);
          writeUint8((n >> 16) & 0xFF);
          writeUint8((n >> 8) & 0xFF);
          writeUint8(n & 0xFF);
          return count;
        }

        if (n < 0x040000000000) {
          writeUint8(((n >> 40) & 0xFF) | 0xF8);
          writeUint8((n >> 32) & 0xFF);
          writeUint8((n >> 24) & 0xFF);
          writeUint8((n >> 16) & 0xFF);
          writeUint8((n >> 8) & 0xFF);
          writeUint8(n & 0xFF);
          return count;
        }

        if (n < 0x02000000000000) {
          writeUint8(((n >> 48) & 0xFF) | 0xFC);
          writeUint8((n >> 40) & 0xFF);
          writeUint8((n >> 32) & 0xFF);
          writeUint8((n >> 24) & 0xFF);
          writeUint8((n >> 16) & 0xFF);
          writeUint8((n >> 8) & 0xFF);
          writeUint8(n & 0xFF);
          return count;
        }
        if (n < 0x0100000000000000) {
          writeUint8(((n >> 56) & 0xFF) | 0xFE);
          writeUint8((n >> 48) & 0xFF);
          writeUint8((n >> 40) & 0xFF);
          writeUint8((n >> 32) & 0xFF);
          writeUint8((n >> 24) & 0xFF);
          writeUint8((n >> 16) & 0xFF);
          writeUint8((n >> 8) & 0xFF);
          writeUint8(n & 0xFF);
          return count;
        }

        writeUint8(0xFF);
        writeUint8((n >> 56) & 0xFF);
        writeUint8((n >> 48) & 0xFF);
        writeUint8((n >> 40) & 0xFF);
        writeUint8((n >> 32) & 0xFF);
        writeUint8((n >> 24) & 0xFF);
        writeUint8((n >> 16) & 0xFF);
        writeUint8((n >> 8) & 0xFF);
        writeUint8(n & 0xFF);
        return count;
      case 1:
        writeUint8(count);
        return count;
      case 2:
        writeUint16(count);
        return count;
      case 3:
        writeUint32(count);
        return count;
      case 4:
        writeUint64(count);
        return count;
    }
    return count;
  }

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes list of packed sizes.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список упакованных размеров.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListSize(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterSize, csz: csz, size: size);
  static void _listWriterSize(int val, int i, BinaryWriter writer) =>
      writer.writeSize(val);

  /// Writes a zigzag-packed signed integer.
  ///
  /// {@macro atmos.binaryBuffer.packInt}
  ///
  /// Записывает запакованное знаковое целое число.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writePackedInt(int value) {
    // Zigzag encoding: (n << 1) ^ (n < 0 ? -1 : 0)
    // Преобразует знаковые числа в беззнаковые для эффективной упаковки
    final unsigned = (value << 1) ^ (value < 0 ? -1 : 0);
    writeSize(unsigned);
  }

  /// {@macro atmos.binaryWriter.list.en}
  ///
  /// Writes list of zigzag-packed signed integers.
  ///
  /// {@macro atmos.binaryWriter.list.ru}
  ///
  /// Записывает список знаковых целых в zigzag-упаковке.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeListPackedInt(List<int> val, {int csz = 0, int? size}) =>
      writeList(val, _listWriterPackedInt, csz: csz, size: size);
  static void _listWriterPackedInt(int val, int i, BinaryWriter writer) =>
      writer.writePackedInt(val);

  /// Aligns write pointer to a multiple of [bytes].
  ///
  /// Выравнивает указатель записи до кратного значения [bytes].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void align(int bytes) {
    if (bytes == 1) return;
    assert(
      bytes == pow2roundup(bytes),
      'Указано не кратное степени 2 значение',
    );
    final n = bytes - (_length & (bytes - 1));
    if (n == bytes) {
      return;
    }
    skip(n);
  }

  /// Skips a number of bytes.
  ///
  /// Пропускает некоторое количество байт.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int bytes) {
    _reserveBytes(bytes);
    // Uint8List.view(_buffer.buffer, _length).fillRange(0, bytes, 0);
    _length += bytes;
  }
}
