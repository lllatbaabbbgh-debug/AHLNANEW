import 'package:flutter/material.dart';

class ElasticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double minScale;
  final Duration pressDuration;
  final Duration bounceDuration;
  final Curve bounceCurve;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const ElasticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.minScale = 0.92,
    this.pressDuration = const Duration(milliseconds: 80),
    this.bounceDuration = const Duration(milliseconds: 450),
    this.bounceCurve = Curves.elasticOut,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  State<ElasticButton> createState() => _ElasticButtonState();
}

class _ElasticButtonState extends State<ElasticButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.bounceDuration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.bounceCurve)
        .drive(Tween(begin: widget.minScale, end: 1.0));
    _animation.addListener(() {
      setState(() {
        _scale = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.stop();
    setState(() {
      _scale = widget.minScale;
    });
  }

  Future<void> _onTapUp(TapUpDetails details) async {
    _controller.reset();
    await _controller.forward();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _scale,
      duration: widget.pressDuration,
      child: widget.child,
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: child,
    );
  }
}

