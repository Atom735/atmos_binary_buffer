/// ### Round up to power of two
///
/// Returns the smallest power of two that is greater than or equal to
/// [x]. Works for positive integers in the `<= 2^32` range.
///
/// Возвращает наименьшую степень двойки, которая больше либо равна [x].
/// Работает для положительных целых чисел в диапазоне `<= 2^32`.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
int pow2roundup(int x) {
  assert(x > 0, 'num must be positive');
  --x;
  x |= x >> 1;
  x |= x >> 2;
  x |= x >> 4;
  x |= x >> 8;
  x |= x >> 16;
  return x + 1;
}
