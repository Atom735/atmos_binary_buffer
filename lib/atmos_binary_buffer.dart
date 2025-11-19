/// {@template atmos.binaryBuffer.packInt}
///
/// ## ENG
///
/// ## Special number packing
///
/// The first bits indicate how many bytes the number is written in:
///
/// - from `                 0` to `                0x7F` - 1 byte  (first bits = `0xxxxxxx`)
/// - from `              0x80` to `              0x3FFF` - 2 bytes (first bits = `10xxxxxx`)
/// - from `            0x4000` to `            0x1FFFFF` - 3 bytes (first bits = `110xxxxx`)
/// - from `          0x200000` to `          0x0FFFFFFF` - 4 bytes (first bits = `1110xxxx`)
/// - from `        0x10000000` to `        0x07FFFFFFFF` - 5 bytes (first bits = `11110xxx`)
/// - from `      0x0800000000` to `      0x03FFFFFFFFFF` - 6 bytes (first bits = `111110xx`)
/// - from `    0x040000000000` to `    0x01FFFFFFFFFFFF` - 7 bytes (first bits = `1111110x`)
/// - from `  0x02000000000000` to `  0x00FFFFFFFFFFFFFF` - 8 bytes (first byte = `0xFE`)
/// - from `0x0100000000000000` to `  0xFFFFFFFFFFFFFFFF` - 9 bytes (first byte = `0xFF`)
///
/// ## Zigzag encoding for signed integers
///
/// For efficient packing of signed integers, **zigzag encoding** is used.
/// This algorithm converts signed numbers to unsigned, allowing efficient
/// packing of both positive and negative numbers.
///
/// ### How it works
///
/// Zigzag encoding transforms signed numbers as follows:
///
/// - **Positive numbers** (including 0): multiplied by 2
///   - `0` → `0`
///   - `1` → `2`
///   - `63` → `126`
///
/// - **Negative numbers**: `(n << 1) ^ (-1)`
///   - `-1` → `1`
///   - `-2` → `3`
///   - `-64` → `127`
///
/// ### Encoding formula
///
/// ```dart
/// unsigned = (value << 1) ^ (value < 0 ? -1 : 0)
/// ```
///
/// ### Decoding formula
///
/// ```dart
/// value = (unsigned >> 1) ^ (-(unsigned & 1))
/// ```
///
/// ### Transformation examples
///
/// | Original value | Zigzag | Packed size |
/// |---------------|--------|-------------|
/// | `0`           | `0`     | 1 byte      |
/// | `1`           | `2`     | 1 byte      |
/// | `-1`          | `1`     | 1 byte      |
/// | `63`          | `126`   | 1 byte      |
/// | `-64`         | `127`   | 1 byte      |
/// | `64`          | `128`   | 2 bytes     |
/// | `-65`         | `129`   | 2 bytes     |
///
/// ### Advantages
///
/// 1. **Small numbers take little space**: numbers from `-64` to `63` are packed
///    into 1 byte
/// 2. **Symmetry**: absolute values are packed equally efficiently
/// 3. **Web compatibility**: uses operations that work correctly in JavaScript
///
/// ## Web limitations (Flutter Web)
///
/// When compiling to JavaScript via dart2js, the following limitations exist:
///
/// ### Bit operations
///
/// - **Unsigned right shift (`>>>`)**: in JavaScript works only with 32-bit
///   numbers. The code uses `>>` for web compatibility
/// - **Large integers**: JavaScript uses 64-bit floating-point numbers, precision
///   is lost after `2^53`. For numbers larger than this, special handling may
///   be required
///
/// ### Performance
///
/// - Bit operations may be slower on the web compared to native platforms
/// - `ByteData.view()` and typed array operations compile to JavaScript typed
///   arrays, providing acceptable performance
///
/// ### Compatibility
///
/// The library uses only web-compatible APIs:
/// - `dart:typed_data` - typed arrays
/// - `dart:convert` - string encoding/decoding
///
/// All bit and number operations are implemented with web compatibility in mind.
///
/// ---
///
/// ## RU
///
/// ## Специальная упаковка числа
///
/// Первые биты показывают в скольки байтах записано число:
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
/// ## Zigzag кодирование для знаковых чисел
///
/// Для эффективной упаковки знаковых целых чисел используется **zigzag encoding**.
/// Этот алгоритм преобразует знаковые числа в беззнаковые, что позволяет
/// эффективно упаковывать как положительные, так и отрицательные числа.
///
/// ### Принцип работы
///
/// Zigzag encoding преобразует знаковые числа следующим образом:
///
/// - **Положительные числа** (включая 0): умножаются на 2
///   - `0` → `0`
///   - `1` → `2`
///   - `63` → `126`
///
/// - **Отрицательные числа**: `(n << 1) ^ (-1)`
///   - `-1` → `1`
///   - `-2` → `3`
///   - `-64` → `127`
///
/// ### Формула кодирования
///
/// ```dart
/// unsigned = (value << 1) ^ (value < 0 ? -1 : 0)
/// ```
///
/// ### Формула декодирования
///
/// ```dart
/// value = (unsigned >> 1) ^ (-(unsigned & 1))
/// ```
///
/// ### Примеры преобразования
///
/// | Исходное число | Zigzag | Упакованное |
/// |----------------|--------|-------------|
/// | `0`            | `0`     | 1 байт      |
/// | `1`            | `2`     | 1 байт      |
/// | `-1`           | `1`     | 1 байт      |
/// | `63`           | `126`   | 1 байт      |
/// | `-64`          | `127`   | 1 байт      |
/// | `64`           | `128`   | 2 байта     |
/// | `-65`          | `129`   | 2 байта     |
///
/// ### Преимущества
///
/// 1. **Малые числа занимают мало места**: числа от `-64` до `63` упаковываются
///    в 1 байт
/// 2. **Симметричность**: абсолютные значения чисел упаковываются одинаково
///    эффективно
/// 3. **Веб-совместимость**: использует операции, корректно работающие
///    в JavaScript
///
/// ## Ограничения для веба (Flutter Web)
///
/// При компиляции в JavaScript через dart2js существуют следующие ограничения:
///
/// ### Операции с битами
///
/// - **Unsigned right shift (`>>>`)**: в JavaScript работает только с 32-битными
///   числами. В коде используется `>>` для веб-совместимости
/// - **Большие целые числа**: JavaScript использует 64-битные числа с плавающей
///   точкой, точность теряется после `2^53`. Для чисел больше этого значения
///   может потребоваться специальная обработка
///
/// ### Производительность
///
/// - Операции с битами могут быть медленнее в вебе по сравнению с нативными
///   платформами
/// - `ByteData.view()` и операции с типизированными массивами компилируются
///   в JavaScript типизированные массивы, что обеспечивает приемлемую
///   производительность
///
/// ### Совместимость
///
/// Библиотека использует только веб-совместимые API:
/// - `dart:typed_data` - типизированные массивы
/// - `dart:convert` - кодирование/декодирование строк
///
/// Все операции с битами и числами реализованы с учётом веб-совместимости.
///
/// {@endtemplate}
// ignore_for_file: lines_longer_than_80_chars

library atmos_binary_buffer;

export 'src/binary_reader.dart';
export 'src/binary_writer.dart';
export 'src/utils.dart';
