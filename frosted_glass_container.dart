import 'dart:ui';

import 'package:carpool/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

class FrostedGlassContainer extends StatelessWidget {
  final double blurX;
  final double blurY;
  final double opacity;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final Widget child;

  const FrostedGlassContainer({
    super.key,
    this.blurX = 10,
    this.blurY = 10,
    this.opacity = 0.8,
    this.padding,
    this.width,
    this.height,
    this.radius,
    this.margin,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
        child: Container(
          height: height,
          width: width,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
              color: kcPrimaryBackgroundColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(radius ?? 32),
              border: Border.all(color: kcWhiteColor, width: 4)),
          child: child,
        ),
      ),
    );
  }
}
