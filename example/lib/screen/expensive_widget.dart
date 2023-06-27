

import 'package:flutter/material.dart';

class ExpensiveWidget extends StatefulWidget {
  const ExpensiveWidget({Key? key}) : super(key: key);

  @override
  State<ExpensiveWidget> createState() => _ExpensiveWidgetState();
}

class _ExpensiveWidgetState extends State<ExpensiveWidget> with SingleTickerProviderStateMixin {
  List<Widget> children = [];
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    controller.addListener(() {
      initWidgets();
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.repeat();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  initWidgets() {
    children = List.generate(100, (index) {
      int i = index % 50;
      bool r1 = index < 50;
      return Positioned(
        top: 700 * controller.value + 1 * i + (r1 ? 0 : 80),
        left: 10 * i.toDouble(),
        child: const FlutterLogo(
          size: 35,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1000,
      height: 1000,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return Stack(
            children: children,
          );
        },
      ),
    );
  }
}
