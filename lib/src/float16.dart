library float16;

import 'float32.dart';

/// {@template atmos.float16.rounding.en}
/// ### Rounding
///
/// Encoding uses round-to-nearest-even (RNE), including subnormal
/// numbers.
/// {@endtemplate}
///
/// {@template atmos.float16.special.en}
/// ### Special values
///
/// Supports `+0`, `-0`, subnormal and normal numbers, `+/-infinity`,
/// and `NaN`.
/// {@endtemplate}
///
/// {@template atmos.float16.uint16.en}
/// Only lower 16 bits of integer inputs are used.
/// {@endtemplate}
///
/// {@template atmos.float16.rounding.ru}
/// ### Округление
///
/// При кодировании используется округление к ближайшему чётному (RNE),
/// включая субнормальные значения.
/// {@endtemplate}
///
/// {@template atmos.float16.special.ru}
/// ### Особые значения
///
/// Поддерживает `+0`, `-0`, субнормальные и нормальные числа,
/// `+/-infinity` и `NaN`.
/// {@endtemplate}
///
/// {@template atmos.float16.uint16.ru}
/// Из целочисленного входа используются только младшие 16 бит.
/// {@endtemplate}
///
extension Float16XDouble on double {
  /// ### Encode to float16 bits
  ///
  /// Encodes this [double] into raw `float16` (`uint16`) bits.
  ///
  /// {@macro atmos.float16.rounding.en}
  ///
  /// ### Кодирование в биты float16
  ///
  /// Кодирует этот [double] в сырые биты `float16` (`uint16`).
  ///
  /// {@macro atmos.float16.rounding.ru}
  int get toFloat16 => doubleToFloat16(this);
}

extension Float16XInt on int {
  /// ### Decode from float16 bits
  ///
  /// Decodes raw `float16` (`uint16`) bits into [double].
  ///
  /// {@macro atmos.float16.uint16.en}
  ///
  /// ### Декодирование из битов float16
  ///
  /// Декодирует сырые биты `float16` (`uint16`) в [double].
  ///
  /// {@macro atmos.float16.uint16.ru}
  double get toFloat16 => float16ToDouble(this);
}

/// ### Convert [double] to float16 bits
///
/// Converts [value] to raw IEEE 754 `binary16` (`uint16`) bits.
///
/// {@macro atmos.float16.rounding.en}
/// {@macro atmos.float16.special.en}
///
/// ### Преобразование [double] в биты float16
///
/// Преобразует [value] в сырые биты IEEE 754 `binary16` (`uint16`).
///
/// {@macro atmos.float16.rounding.ru}
/// {@macro atmos.float16.special.ru}
int doubleToFloat16(double value) {
  final bits = doubleToFloat32Bits(value);

  final sign = (bits >> 16) & 0x8000;
  final exponent = (bits >> 23) & 0xFF;
  final mantissa = bits & 0x7FFFFF;

  if (exponent == 0xFF) {
    if (mantissa == 0) {
      return sign | 0x7C00;
    }
    var nanMantissa = mantissa >> 13;
    if (nanMantissa == 0) nanMantissa = 1;
    nanMantissa |= 0x0200;
    return sign | 0x7C00 | (nanMantissa & 0x03FF);
  }

  final exponent16 = exponent - 127 + 15;

  if (exponent16 >= 0x1F) {
    return sign | 0x7C00;
  }

  if (exponent16 <= 0) {
    if (exponent16 < -10) {
      return sign;
    }

    final mantissaWithHiddenBit = mantissa | 0x800000;
    final shift = 14 - exponent16;

    var halfMantissa = mantissaWithHiddenBit >> shift;

    final roundBit = 1 << (shift - 1);
    final remainder = mantissaWithHiddenBit & (roundBit - 1);
    final hasTie = (mantissaWithHiddenBit & roundBit) != 0;
    if (hasTie && (remainder != 0 || (halfMantissa & 1) != 0)) {
      halfMantissa++;
    }

    return sign | (halfMantissa & 0x03FF);
  }

  var halfExponent = exponent16 << 10;
  var halfMantissa = mantissa >> 13;

  final discarded = mantissa & 0x1FFF;
  if (discarded > 0x1000 || (discarded == 0x1000 && (halfMantissa & 1) != 0)) {
    halfMantissa++;
    if (halfMantissa == 0x0400) {
      halfMantissa = 0;
      halfExponent += 0x0400;
      if (halfExponent >= 0x7C00) {
        return sign | 0x7C00;
      }
    }
  }

  return sign | halfExponent | (halfMantissa & 0x03FF);
}

/// ### Convert float16 bits to [double]
///
/// Converts raw IEEE 754 `binary16` (`uint16`) bits back to [double].
///
/// {@macro atmos.float16.special.en}
/// {@macro atmos.float16.uint16.en}
///
/// ### Преобразование битов float16 в [double]
///
/// Преобразует сырые биты IEEE 754 `binary16` (`uint16`) обратно в
/// [double].
///
/// {@macro atmos.float16.special.ru}
/// {@macro atmos.float16.uint16.ru}
double float16ToDouble(int float16) {
  final h = float16 & 0xFFFF;

  final sign = (h & 0x8000) << 16;
  final exponent = (h >> 10) & 0x1F;
  final mantissa = h & 0x03FF;

  late int bits32;

  if (exponent == 0) {
    if (mantissa == 0) {
      bits32 = sign;
    } else {
      var normalizedMantissa = mantissa;
      var exp = -14;
      while ((normalizedMantissa & 0x0400) == 0) {
        normalizedMantissa <<= 1;
        exp--;
      }
      normalizedMantissa &= 0x03FF;
      final exp32 = (exp + 127) << 23;
      final mantissa32 = normalizedMantissa << 13;
      bits32 = sign | exp32 | mantissa32;
    }
  } else if (exponent == 0x1F) {
    bits32 = sign | 0x7F800000 | (mantissa << 13);
    if (mantissa != 0) {
      bits32 |= 0x00400000;
    }
  } else {
    final exp32 = (exponent - 15 + 127) << 23;
    final mantissa32 = mantissa << 13;
    bits32 = sign | exp32 | mantissa32;
  }

  return float32BitsToDouble(bits32);
}
