import 'dart:math';

String formatStoreApiPrice(String minorUnitValue, {int minorUnit = 2}) {
  final parsed = int.tryParse(minorUnitValue) ?? 0;
  final divisor = pow(10, minorUnit).toDouble();
  final value = parsed / divisor;
  return 'AED ${value.toStringAsFixed(minorUnit)}';
}
