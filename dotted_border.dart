import 'dart:ui';
import 'package:flutter/material.dart';

/// A dotted border that can be used inside BoxDecoration's border parameter.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     border: DottedBorder(
///       color: Colors.grey,
///       strokeWidth: 1.5,
///       dashLength: 6.0,
///       dashSpacing: 4.0,
///     ),
///     borderRadius: BorderRadius.circular(12),
///   ),
/// )
/// ```
class DottedBorder extends BoxBorder {
  /// The color of the dotted border.
  final Color color;

  /// The width/thickness of the border stroke.
  final double strokeWidth;

  /// The length of each dash.
  final double dashLength;

  /// The spacing between dashes.
  final double dashSpacing;

  const DottedBorder({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.dashLength = 5.0,
    this.dashSpacing = 3.0,
  });

  @override
  BorderSide get top => BorderSide(color: color, width: strokeWidth);

  @override
  BorderSide get bottom => BorderSide(color: color, width: strokeWidth);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path;

    if (shape == BoxShape.circle) {
      path = Path()..addOval(rect.deflate(strokeWidth / 2));
    } else if (borderRadius != null) {
      path = Path()
        ..addRRect(borderRadius.toRRect(rect).deflate(strokeWidth / 2));
    } else {
      path = Path()..addRect(rect.deflate(strokeWidth / 2));
    }

    canvas.drawPath(_createDashedPath(path), paint);
  }

  Path _createDashedPath(Path source) {
    final Path dashedPath = Path();
    final double dashPlusSpace = dashLength + dashSpacing;

    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashLength > metric.length)
            ? metric.length - distance
            : dashLength;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashPlusSpace;
      }
    }
    return dashedPath;
  }

  @override
  ShapeBorder scale(double t) {
    return DottedBorder(
      color: color,
      strokeWidth: strokeWidth * t,
      dashLength: dashLength * t,
      dashSpacing: dashSpacing * t,
    );
  }
}
