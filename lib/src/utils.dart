/// Rounds numbers <= 2^32 up to the nearest power of 2.
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
