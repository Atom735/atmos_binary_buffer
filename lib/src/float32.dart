library float32;

import 'dart:typed_data';

/// {@template atmos.float32.endian.en}
/// ### Endianness
///
/// Internal bit-cast operations use fixed `Endian.big` for both write
/// and read, so conversion is deterministic and platform independent.
/// {@endtemplate}
///
/// {@template atmos.float32.uint32.en}
/// Only lower 32 bits of integer input are used.
/// {@endtemplate}
///
/// {@template atmos.float32.endian.ru}
/// ### Порядок байтов
///
/// Внутренние bit-cast операции используют фиксированный `Endian.big`
/// и на запись, и на чтение, поэтому преобразование детерминировано и не
/// зависит от платформы.
/// {@endtemplate}
///
/// {@template atmos.float32.uint32.ru}
/// Из целочисленного входа используются только младшие 32 бита.
/// {@endtemplate}
///
extension Float32XDouble on double {
  /// ### Encode to float32 raw bits
  ///
  /// Encodes this [double] to IEEE 754 `float32` raw `uint32` bits.
  ///
  /// {@macro atmos.float32.endian.en}
  ///
  /// ### Кодирование в сырые биты float32
  ///
  /// Кодирует этот [double] в сырые `uint32` биты IEEE 754 `float32`.
  ///
  /// {@macro atmos.float32.endian.ru}
  int get toFloat32Bits => doubleToFloat32Bits(this);
}

extension Float32XInt on int {
  /// ### Decode from float32 raw bits
  ///
  /// Reinterprets this integer as IEEE 754 `float32` bits and returns
  /// [double].
  ///
  /// {@macro atmos.float32.uint32.en}
  ///
  /// ### Декодирование из сырых битов float32
  ///
  /// Реинтерпретирует это целое как биты IEEE 754 `float32` и
  /// возвращает [double].
  ///
  /// {@macro atmos.float32.uint32.ru}
  double get fromFloat32Bits => float32BitsToDouble(this);
}

/// ### Convert [double] to `float32` raw bits
///
/// Returns IEEE 754 `float32` bit pattern as `uint32`.
///
/// {@macro atmos.float32.endian.en}
///
/// ### Преобразование [double] в сырые биты `float32`
///
/// Возвращает битовый паттерн IEEE 754 `float32` как `uint32`.
///
/// {@macro atmos.float32.endian.ru}
int doubleToFloat32Bits(double value) {
  final data = ByteData(4)..setFloat32(0, value);
  return data.getUint32(0);
}

/// ### Convert `float32` raw bits to [double]
///
/// Reinterprets `uint32` bit pattern as IEEE 754 `float32`.
///
/// {@macro atmos.float32.uint32.en}
///
/// {@macro atmos.float32.endian.en}
///
/// ### Преобразование сырых битов `float32` в [double]
///
/// Реинтерпретирует `uint32` битовый паттерн как IEEE 754 `float32`.
///
/// {@macro atmos.float32.uint32.ru}
///
/// {@macro atmos.float32.endian.ru}
double float32BitsToDouble(int bits) {
  final data = ByteData(4)..setUint32(0, bits & 0xFFFFFFFF);
  return data.getFloat32(0);
}
