import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 单帧解码结果。
class _GifFrame {
  const _GifFrame(this.image, this.duration);

  final ui.Image image;
  final Duration duration;
}

/// 自绘的动态 GIF 播放组件。
///
/// 不依赖 [Image] 的多帧调度（Impeller 渲染器下只会渲染首帧），
/// 而是一次性解码全部帧，用 [Ticker] 按每帧各自的时长调度重绘，
/// 播完无缝从头循环，所有帧（包括最后一帧）都会完整展示。
class GifPlayer extends StatefulWidget {
  const GifPlayer({
    required this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  /// GIF 原始字节数据。
  final Uint8List bytes;

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<GifPlayer> createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  List<_GifFrame> _frames = const <_GifFrame>[];
  int _totalMs = 0;
  int _index = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(GifPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.bytes, oldWidget.bytes)) {
      _ticker?.stop();
      _resetFrames();
      _decode();
    }
  }

  /// 解码全部帧并启动播放。
  Future<void> _decode() async {
    try {
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(widget.bytes);
      // 不传目标尺寸即按 GIF 原始尺寸解码全部帧。
      final ui.Codec codec =
          await PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
      final List<_GifFrame> frames = <_GifFrame>[];
      for (int i = 0; i < codec.frameCount; i++) {
        final ui.FrameInfo info = await codec.getNextFrame();
        // 部分 GIF 编码器帧延迟为 0，兜底 100ms 避免闪帧。
        final int ms = info.duration.inMilliseconds > 0
            ? info.duration.inMilliseconds
            : 100;
        frames.add(_GifFrame(info.image, Duration(milliseconds: ms)));
      }
      codec.dispose();

      if (!mounted) {
        _disposeFrames(frames);
        return;
      }
      setState(() {
        _frames = frames;
        _totalMs = frames.fold<int>(
          0,
          (int sum, _GifFrame frame) => sum + frame.duration.inMilliseconds,
        );
        _index = 0;
        _failed = false;
      });
      _startTicker();
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  void _startTicker() {
    _ticker ??= createTicker(_onTick);
    if (!_ticker!.isActive) {
      _ticker!.start();
    }
  }

  /// 根据累计播放时长定位当前帧，仅在帧切换时重绘。
  void _onTick(Duration elapsed) {
    if (_frames.isEmpty || _totalMs <= 0) {
      return;
    }
    final int pos = elapsed.inMilliseconds % _totalMs;
    int acc = 0;
    int index = 0;
    for (int i = 0; i < _frames.length; i++) {
      acc += _frames[i].duration.inMilliseconds;
      if (pos < acc) {
        index = i;
        break;
      }
    }
    if (index != _index) {
      setState(() => _index = index);
    }
  }

  void _resetFrames() {
    _disposeFrames(_frames);
    _frames = const <_GifFrame>[];
    _totalMs = 0;
    _index = 0;
  }

  static void _disposeFrames(List<_GifFrame> frames) {
    for (final _GifFrame frame in frames) {
      frame.image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    if (_failed) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 24,
          color: Colors.grey,
        ),
      );
    }
    return RawImage(
      image: _frames[_index].image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: Alignment.center,
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _resetFrames();
    super.dispose();
  }
}
