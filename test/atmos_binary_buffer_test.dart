import 'package:atmos_binary_buffer/atmos_binary_buffer.dart';
import 'package:test/test.dart';

void t(int i) {
  final writer = BinaryWriter()..writeSize(i);
  final buf = writer.takeBytes();
  final reader = BinaryReader(buf);
  final sz = reader.readSize();
  // ignore: avoid_print
  print('$i = $sz = $buf');
}

void f16(double f) {
  final writer = BinaryWriter()..wF16(f);
  final buf = writer.takeBytes();
  final reader = BinaryReader(buf);
  final sz = reader.rF16();
  final err = (f - sz).abs();
  // ignore: avoid_print
  print('F16: $f = $sz = $err = $buf');
}

void f32(double f) {
  final writer = BinaryWriter()..wF32(f);
  final buf = writer.takeBytes();
  final reader = BinaryReader(buf);
  final sz = reader.rF32();
  final err = (f - sz).abs();
  // ignore: avoid_print
  print('F32: $f = $sz = $err = $buf');
}

void f64(double f) {
  final writer = BinaryWriter()..wF64(f);
  final buf = writer.takeBytes();
  final reader = BinaryReader(buf);
  final sz = reader.rF64();
  final err = (f - sz).abs();
  // ignore: avoid_print
  print('F64: $f = $sz = $err = $buf');
}

void bf16(double f) {
  final writer = BinaryWriter()..wBF16(f);
  final buf = writer.takeBytes();
  final reader = BinaryReader(buf);
  final sz = reader.rBF16();
  final err = (f - sz).abs();
  // ignore: avoid_print
  print('BF16: $f = $sz = $err = $buf');
}

void main() {
  const i = [
    0,
    0x80,
    0x4000,
    0x200000,
    0x10000000,
    0x0800000000,
    0x040000000000,
    0x02000000000000,
    0x0100000000000000,
    0x7F,
    0x3FFF,
    0x1FFFFF,
    0x0FFFFFFF,
    0x07FFFFFFFF,
    0x03FFFFFFFFFF,
    0x01FFFFFFFFFFFF,
    // ignore: avoid_js_rounded_ints
    0x00FFFFFFFFFFFFFF,
    0x7FFFFFFFFFFFFFFF,
  ];
  test('atmos binary buffer...', () async {
    i.forEach(t);
  });

  const f = [
    0.0,
    1.0,
    -1.0,
    0.1,
    -0.1,
    0.001,
    -0.001,
    0.0001,
    -0.0001,
    0.00001,
    -0.00001,
    0.000001,
    -0.000001,
    10.0,
    -10.0,
    100.0,
    -100.0,
    1000.0,
    -1000.0,
    10000.0,
    -10000.0,
    100000.0,
    -100000.0,
    1000000.0,
    -1000000.0,
    10000000.0,
    -10000000.0,
    100000000.0,
    -100000000.0,
    1000000000.0,
    -1000000000.0,
    10000000000.0,
    double.infinity,
    -double.infinity,
    double.nan,
    double.maxFinite,
    -double.maxFinite,
    double.minPositive,
    -double.minPositive,
  ];

  test('atmos binary buffer F16...', () async {
    f.forEach(f16);
  });
  test('atmos binary buffer F32...', () async {
    f.forEach(f32);
  });
  test('atmos binary buffer F64...', () async {
    f.forEach(f64);
  });
  test('atmos binary buffer BF16...', () async {
    f.forEach(bf16);
  });
}
