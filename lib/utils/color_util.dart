import 'package:flutter/material.dart';

class ColorUtil {
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  static Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static bool isColorSimilar(Color a, Color b, {double tolerance = 0.1}) {
    return (a.red - b.red).abs() < 255 * tolerance &&
        (a.green - b.green).abs() < 255 * tolerance &&
        (a.blue - b.blue).abs() < 255 * tolerance;
  }
}