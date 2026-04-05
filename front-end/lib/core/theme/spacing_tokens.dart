import 'package:flutter/widgets.dart';

class SpacingTokens {
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;

  static const EdgeInsets allS = EdgeInsets.all(s);
  static const EdgeInsets allM = EdgeInsets.all(m);
  static const EdgeInsets allL = EdgeInsets.all(l);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalS = EdgeInsets.symmetric(horizontal: s);
  static const EdgeInsets horizontalM = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets horizontalL = EdgeInsets.symmetric(horizontal: l);
  static const EdgeInsets verticalS = EdgeInsets.symmetric(vertical: s);
  static const EdgeInsets verticalM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets verticalL = EdgeInsets.symmetric(vertical: l);

  const SpacingTokens._();
}

class RadiusTokens {
  static const double form = 18;
  static const double card = 24;
  static const double chip = 999;

  const RadiusTokens._();
}
