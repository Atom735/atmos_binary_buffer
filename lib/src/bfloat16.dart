library bfloat16;

import 'float32.dart';

/// {@template atmos.bfloat16.module.en}
/// ### BFloat16
///
/// Utilities for converting between [double] and raw `bfloat16`
/// bit pattern.
/// {@endtemplate}
///
/// {@template atmos.bfloat16.rounding.en}
/// ### Rounding
///
/// Encoding from float32 to bfloat16 uses round-to-nearest-even (RNE).
/// {@endtemplate}
///
/// {@template atmos.bfloat16.nan.en}
/// ### NaN handling
///
/// `NaN` is preserved as `NaN`; payload and sign are retained as much
/// as possible for 16-bit storage.
/// {@endtemplate}
///
/// {@template atmos.bfloat16.uint16.en}
/// Only lower 16 bits of integer inputs are used.
/// {@endtemplate}
///
/// {@template atmos.bfloat16.module.ru}
/// ### BFloat16
///
/// Утилиты для преобразования между [double] и сырым битовым
/// представлением `bfloat16`.
/// {@endtemplate}
///
/// {@template atmos.bfloat16.rounding.ru}
/// ### Округление
///
/// При кодировании из float32 в bfloat16 используется округление
/// к ближайшему чётному (RNE).
/// {@endtemplate}
///
/// {@template atmos.bfloat16.nan.ru}
/// ### Обработка NaN
///
/// `NaN` сохраняется как `NaN`; payload и знак сохраняются настолько,
/// насколько это возможно в 16-битном формате.
/// {@endtemplate}
///
/// {@template atmos.bfloat16.uint16.ru}
/// Из целочисленного входа используются только младшие 16 бит.
/// {@endtemplate}
///
extension BFloat16XDouble on double {
  /// ### Encode to bfloat16 bits
  ///
  /// Encodes this [double] into raw `bfloat16` (`uint16`) bits.
  ///
  /// {@macro atmos.bfloat16.rounding.en}
  ///
  /// ### Кодирование в биты bfloat16
  ///
  /// Кодирует этот [double] в сырые биты `bfloat16` (`uint16`).
  ///
  /// {@macro atmos.bfloat16.rounding.ru}
  int get toBFloat16 => doubleToBFloat16(this);
}

extension BFloat16XInt on int {
  /// ### Decode from bfloat16 bits
  ///
  /// Decodes raw `bfloat16` (`uint16`) bits into [double].
  ///
  /// {@macro atmos.bfloat16.uint16.en}
  ///
  /// ### Декодирование из битов bfloat16
  ///
  /// Декодирует сырые биты `bfloat16` (`uint16`) в [double].
  ///
  /// {@macro atmos.bfloat16.uint16.ru}
  double get toBFloat16 => bFloat16ToDouble(this);
}

/// ### Convert [double] to bfloat16 bits
///
/// Converts [value] to raw `bfloat16` (`uint16`) bits.
///
/// {@macro atmos.bfloat16.rounding.en}
///
/// {@macro atmos.bfloat16.nan.en}
///
/// ### Преобразование [double] в биты bfloat16
///
/// Преобразует [value] в сырые биты `bfloat16` (`uint16`).
///
/// {@macro atmos.bfloat16.rounding.ru}
///
/// {@macro atmos.bfloat16.nan.ru}
int doubleToBFloat16(double value) {
  final bits = doubleToFloat32Bits(value);

  final exponent = bits & 0x7F800000;
  final mantissa = bits & 0x007FFFFF;

  if (exponent == 0x7F800000) {
    if (mantissa != 0) {
      return ((bits >> 16) | 0x0040) & 0xFFFF;
    }
    return (bits >> 16) & 0xFFFF;
  }

  final lsb = (bits >> 16) & 1;
  final rounded = bits + 0x7FFF + lsb;
  return (rounded >> 16) & 0xFFFF;
}

/// ### Convert bfloat16 bits to [double]
///
/// Converts raw `bfloat16` (`uint16`) bits back to [double].
///
/// {@macro atmos.bfloat16.uint16.en}
///
/// ### Преобразование битов bfloat16 в [double]
///
/// Преобразует сырые биты `bfloat16` (`uint16`) обратно в [double].
///
/// {@macro atmos.bfloat16.uint16.ru}
double bFloat16ToDouble(int bFloat16) {
  final bits = (bFloat16 & 0xFFFF) << 16;
  return float32BitsToDouble(bits);
}
