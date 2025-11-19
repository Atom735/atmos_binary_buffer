import 'dart:typed_data';

import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';

void main() {
  print('=== Atmos Binary Buffer Example ===\n');

  // Example 1: Basic read/write operations
  basicExample();

  // Example 2: Packed size encoding (variable-length encoding)
  packedSizeExample();

  // Example 3: Zigzag encoding for signed integers
  zigzagExample();

  // Example 4: Working with strings
  stringExample();

  // Example 5: Working with lists
  listExample();

  // Example 6: Different data types
  dataTypesExample();

  // Example 7: Endianness support
  endianExample();
}

/// Example 1: Basic read/write operations
void basicExample() {
  print('1. Basic read/write operations:');
  final writer = BinaryWriter();

  writer.writeInt32(42);
  writer.writeFloat64(3.14159);
  writer.writeUint8(255);
  writer.writeString('Hello');

  final buffer = writer.takeBytes();
  final reader = BinaryReader(buffer);

  print('  Written: int32=42, float64=3.14159, uint8=255, string="Hello"');
  print('  Read:    int32=${reader.readInt32()}, '
      'float64=${reader.readFloat64()}, '
      'uint8=${reader.readUint8()}, '
      'string="${reader.readString()}"');
  print('  Buffer size: ${buffer.length} bytes\n');
}

/// Example 2: Packed size encoding (variable-length encoding)
void packedSizeExample() {
  print('2. Packed size encoding (variable-length):');

  final testValues = [0, 127, 128, 16383, 16384, 1000000];

  for (final value in testValues) {
    final writer = BinaryWriter();
    writer.writeSize(value); // Uses variable-length encoding

    final buffer = writer.takeBytes();
    final reader = BinaryReader(buffer);
    final readValue = reader.readSize();

    print('  Value: $value → ${buffer.length} byte(s) → Read: $readValue');
    assert(value == readValue, 'Value mismatch!');
  }
  print('');
}

/// Example 3: Zigzag encoding for signed integers
void zigzagExample() {
  print('3. Zigzag encoding for signed integers:');

  final testValues = [0, 1, -1, 63, -64, 64, -65, 1000, -1000];

  for (final value in testValues) {
    final writer = BinaryWriter();
    writer.writePackedInt(value); // Uses zigzag encoding + variable-length

    final buffer = writer.takeBytes();
    final reader = BinaryReader(buffer);
    final readValue = reader.readPackedInt();

    final sizeInfo =
        value >= -64 && value <= 63 ? '1 byte' : '${buffer.length} bytes';

    print('  Value: $value → $sizeInfo → Read: $readValue');
    assert(value == readValue, 'Value mismatch!');
  }
  print('');
}

/// Example 4: Working with strings
void stringExample() {
  print('4. Working with strings:');

  final writer = BinaryWriter();
  writer.writeString('Hello, World!');
  writer.writeString1('Short'); // Max 256 bytes
  writer.writeString2('Medium length string'); // Max 64KB

  final buffer = writer.takeBytes();
  final reader = BinaryReader(buffer);

  print('  String 1: "${reader.readString()}"');
  print('  String 2: "${reader.readString1()}"');
  print('  String 3: "${reader.readString2()}"');
  print('  Total size: ${buffer.length} bytes\n');
}

/// Example 5: Working with lists
void listExample() {
  print('5. Working with lists:');

  final writer = BinaryWriter();

  // Write list of integers
  writer.writeListInt32([1, 2, 3, 4, 5]);

  // Write list of packed integers (with zigzag encoding)
  writer.writeListPackedInt([-10, -5, 0, 5, 10]);

  // Write list of floats
  writer.writeListFloat32([1.1, 2.2, 3.3]);

  final buffer = writer.takeBytes();
  final reader = BinaryReader(buffer);

  print('  Int32 list: ${reader.readListInt32()}');
  print('  PackedInt list: ${reader.readListPackedInt()}');
  print('  Float32 list: ${reader.readListFloat32()}');
  print('  Total size: ${buffer.length} bytes\n');
}

/// Example 6: Different data types
void dataTypesExample() {
  print('6. Different data types:');

  final writer = BinaryWriter();

  writer.writeInt8(-128);
  writer.writeInt16(-32768);
  writer.writeInt32(-2147483648);
  writer.writeInt64(-9223372036854775808);
  writer.writeUint8(255);
  writer.writeUint16(65535);
  writer.writeUint32(4294967295);
  // ignore: avoid_js_rounded_ints
  writer.writeUint64(0xFFFFFFFFFFFFFFFF);
  writer.writeFloat32(3.14159);
  writer.writeFloat64(2.718281828459045);
  writer.writeDateTime(DateTime(2024, 1, 1));

  final buffer = writer.takeBytes();
  final reader = BinaryReader(buffer);

  print('  Int8:    ${reader.readInt8()}');
  print('  Int16:   ${reader.readInt16()}');
  print('  Int32:   ${reader.readInt32()}');
  print('  Int64:   ${reader.readInt64()}');
  print('  Uint8:   ${reader.readUint8()}');
  print('  Uint16:  ${reader.readUint16()}');
  print('  Uint32:  ${reader.readUint32()}');
  print('  Uint64:  ${reader.readUint64()}');
  print('  Float32: ${reader.readFloat32()}');
  print('  Float64: ${reader.readFloat64()}');
  print('  DateTime: ${reader.readDateTime()}');
  print('  Total size: ${buffer.length} bytes\n');
}

/// Example 7: Endianness support
void endianExample() {
  print('7. Endianness support:');

  final value = 0x12345678;

  // Big endian (default)
  final writerBig = BinaryWriter(Endian.big);
  writerBig.writeInt32(value);
  final bufferBig = writerBig.takeBytes();

  // Little endian
  final writerLittle = BinaryWriter(Endian.little);
  writerLittle.writeInt32(value);
  final bufferLittle = writerLittle.takeBytes();

  print('  Value: 0x${value.toRadixString(16)}');
  final bigBytes = bufferBig
      .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
      .join(' ');
  final littleBytes = bufferLittle
      .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
      .join(' ');

  print('  Big endian bytes:    $bigBytes');
  print('  Little endian bytes: $littleBytes');

  final readerBig = BinaryReader(bufferBig);
  final readerLittle = BinaryReader(bufferLittle, Endian.little);

  final bigValue = readerBig.readInt32().toRadixString(16);
  final littleValue = readerLittle.readInt32().toRadixString(16);

  print('  Read (big endian):    0x$bigValue');
  print('  Read (little endian): 0x$littleValue\n');

  print('=== All examples completed successfully! ===');
}
