import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Color colorFromHex(String hex, {Color fallback = AppColors.primary}) {
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) return fallback;
  final value = int.tryParse('ff$clean', radix: 16);
  return value == null ? fallback : Color(value);
}
