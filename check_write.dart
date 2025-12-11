import 'dart:ui';

void main() {
  Color c = const Color(0xFF000000);
  // Check if this compiles:
  c.withValues(alpha: 0.5);
}
