import 'package:flutter/services.dart';

extension Matrix4Helpers on Matrix4 {
  double getScaleX() {
    return this[0];
  }

  double getScaleY() {
    return this[5];
  }
}
