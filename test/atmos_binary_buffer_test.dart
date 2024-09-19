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
}
