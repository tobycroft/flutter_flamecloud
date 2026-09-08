import 'package:flutter/material.dart';

/// 入场动画容器：位移 + 淡入（可选缩放）。
///
/// 对应 Vue 登录页 animejs 的 stagger 入场效果。
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 30),
    this.beginScale = 1,
    this.curve = Curves.easeOutQuad,
  });

  /// 子组件。
  final Widget child;

  /// 动画时长。
  final Duration duration;

  /// 延迟多久开始。
  final Duration delay;

  /// 起始位移，基于自身尺寸的倍率。
  final Offset beginOffset;

  /// 起始缩放。
  final double beginScale;

  /// 动画曲线。
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: widget.beginOffset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  late final Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
    if (widget.beginScale == 1) {
      return content;
    }
    return ScaleTransition(scale: _scale, child: content);
  }
}
