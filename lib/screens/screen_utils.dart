import 'package:flutter/material.dart';

class ScreenSizeHelper {
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double heightPercentage(BuildContext context, double percent) =>
      screenHeight(context) * percent;

  static double widthPercentage(BuildContext context, double percent) =>
      screenWidth(context) * percent;
}
