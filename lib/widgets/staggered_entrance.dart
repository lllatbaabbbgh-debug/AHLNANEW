import 'package:flutter/material.dart';

class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration initialDelay;
  final Duration delayBetweenItems;
  final Duration animationDuration;
  final double offsetY;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.initialDelay = const Duration(milliseconds: 60),
    this.delayBetweenItems = const Duration(milliseconds: 80),
    this.animationDuration = const Duration(milliseconds: 420),
    this.offsetY = 24,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _opacity = _controller.drive(Tween(begin: 0.0, end: 1.0));
    _translateY = _controller
        .drive(CurveTween(curve: Curves.easeOut))
        .drive(Tween(begin: widget.offsetY, end: 0));

    final computedDelay =
        widget.initialDelay +
        Duration(
          milliseconds: widget.delayBetweenItems.inMilliseconds * widget.index,
        );
    Future.delayed(computedDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
