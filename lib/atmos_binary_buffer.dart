/// {@template atmos.binnaryBuffer.packInt}
///
/// ## Специальная упаковка числа
///
/// Первые биты показывают в скольки байтах записано число
///
/// - от `                 0` до `                0x7F` - 1 байт  (первые биты = `0xxxxxxx`)
/// - от `              0x80` до `              0x3FFF` - 2 байта (первые биты = `10xxxxxx`)
/// - от `            0x4000` до `            0x1FFFFF` - 3 байта (первые биты = `110xxxxx`)
/// - от `          0x200000` до `          0x0FFFFFFF` - 4 байта (первые биты = `1110xxxx`)
/// - от `        0x10000000` до `        0x07FFFFFFFF` - 5 байт  (первые биты = `11110xxx`)
/// - от `      0x0800000000` до `      0x03FFFFFFFFFF` - 6 байт  (первые биты = `111110xx`)
/// - от `    0x040000000000` до `    0x01FFFFFFFFFFFF` - 7 байт  (первые биты = `1111110x`)
/// - от `  0x02000000000000` до `  0x00FFFFFFFFFFFFFF` - 8 байт  (первые байт = `0xFE`)
/// - от `0x0100000000000000` до `  0xFFFFFFFFFFFFFFFF` - 9 байт  (первые байт = `0xFF`)
///
/// {@endtemplate}
// ignore_for_file: lines_longer_than_80_chars

library atmos_binary_buffer;

export 'src/binary_reader.dart';
export 'src/binary_writer.dart';
export 'src/utils.dart';
