import 'dart:ui';
import 'package:flutter/rendering.dart';

class CustomLayer extends Layer {
  CustomLayer();

  @override
  void addToScene(SceneBuilder builder) {
  }

  @override
  bool supportsRasterization() {
    return false;
  }
}