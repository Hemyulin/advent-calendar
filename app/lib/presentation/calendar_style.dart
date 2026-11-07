import 'package:flutter/material.dart';

abstract final class CalendarStyle {
  static const ivory = Color(0xFFFFF8EE);
  static const green = Color(0xFF315F50);
  static const gold = Color(0xFFAB762C);
  static const muted = Color(0xFF867464);
  static const line = Color(0xFFEDDEC9);

  static const heading = TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: ['Noto Serif', 'serif'],
    color: green,
    fontWeight: FontWeight.w400,
  );
}
