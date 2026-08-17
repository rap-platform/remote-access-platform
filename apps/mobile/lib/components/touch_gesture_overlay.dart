import 'package:flutter/material.dart';

class TouchGestureOverlay extends StatefulWidget {
  final Widget child;
  final Function(Offset pos, String clickType)? onTapEvent;
  final Function(double scale)? onZoomEvent;

  const TouchGestureOverlay({
    Key? key,
    required this.child,
    this.onTapEvent,
    this.onZoomEvent,
  }) : super(key: key);

  @override
  State<TouchGestureOverlay> createState() => _TouchGestureOverlayState();
}

class _TouchGestureOverlayState extends State<TouchGestureOverlay> {
  double _scale = 1.0;
  Offset _position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        widget.onTapEvent?.call(details.localPosition, "LEFT_CLICK");
      },
      onSecondaryTapDown: (details) {
        widget.onTapEvent?.call(details.localPosition, "RIGHT_CLICK");
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.8, 4.0);
          _position += details.focalPointDelta;
        });
        widget.onZoomEvent?.call(_scale);
      },
      child: Transform.translate(
        offset: _position,
        child: Transform.scale(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
