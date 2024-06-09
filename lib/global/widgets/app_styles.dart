  import 'package:flutter/material.dart';

Color primary = Color.fromARGB(255, 255, 255, 255);

class Styles {
  static Color primaryColor = primary;
  static Color textColor = const Color(0xff3b3b3b);
  static Color bgcolor = const Color(0XFFEEEDF2);
  static Color orangeColor = const Color(0xFF526799);

  static TextStyle textStyle =
      TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500);

  static TextStyle textStylehome =
      TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold);
  static TextStyle headLineStyle =
      TextStyle(fontSize: 26, color: textColor, fontWeight: FontWeight.bold);

  static TextStyle headLineStyle2 =
      TextStyle(fontSize: 23, color: textColor, fontWeight: FontWeight.bold);

  static TextStyle headLineStyle3 =
      TextStyle(fontSize: 17, color: textColor, fontWeight: FontWeight.w500);

  static TextStyle headLineStyle4 = TextStyle(
      fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500);
  static TextStyle headLineStyle5 = const TextStyle(
      fontSize: 14,
      color: Color.fromARGB(255, 255, 254, 254),
      fontWeight: FontWeight.w500);
  static TextStyle headLineStyle6 = const TextStyle(
      fontSize: 20,
      color: Color.fromARGB(255, 255, 254, 254),
      fontWeight: FontWeight.w500);

  static getButtonColor(int index) {}

  static getButtonTextStyle(int index) {}
}