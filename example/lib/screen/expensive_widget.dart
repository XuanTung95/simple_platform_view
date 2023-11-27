

import 'package:flutter/material.dart';

class ExpensiveWidget extends StatefulWidget {
  const ExpensiveWidget({Key? key, this.val, this.count = 50}) : super(key: key);

  final double? val;
  final int count;

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
      if (widget.val == null) {
        controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  initWidgets() {
    children = List.generate(widget.count, (index) {
      int i = index % 50;
      bool r1 = index < 50;
      return Positioned(
        top: 700 * (widget.val != null ? widget.val! : controller.value) + 1 * i + (r1 ? 0 : 80),
        left: 10 * i.toDouble(),
        child: const FlutterLogo(
          size: 35,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.val != null) {
      initWidgets();
    }
    return SizedBox(
      width: 1000,
      height: 1000,
      child: widget.val != null ? Stack(
        children: children,
      ): AnimatedBuilder(
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
