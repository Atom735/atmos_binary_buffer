# Atmos Binary Buffer Package

Binary reader/writer utilities for Dart with compact integer packing, typed list
views, and IEEE 754 float helpers (`float16`, `bfloat16`, `float32`, `float64`).

## Install

```yaml
dependencies:
  atmos_binary_buffer: ^2.0.0
```

## Import

```dart
import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
```

## Highlights

- `BinaryReader` / `BinaryWriter` for primitive values and strings.
- Compact size/int packing (`readSize`/`writeSize`, zigzag packed ints).
- Typed list methods and aligned typed-view methods (`*AV`).
- `float16` and `bfloat16` read/write support (including list methods).
- `float32` bit reinterpretation helpers.

## Quick Example

```dart
import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';

void main() {
  final writer = BinaryWriter();
  writer.writeInt32(42);
  writer.writeFloat16(0.1);
  writer.writeBFloat16(3.14159);
  writer.writeListPackedInt([1, -1, 127, -128]);

  final bytes = writer.toBytes();
  final reader = bytes.reader;

  final a = reader.readInt32();
  final f16 = reader.readFloat16();
  final bf16 = reader.readBFloat16();
  final packed = reader.readListPackedInt();

  print('$a, $f16, $bf16, $packed');
}
```
