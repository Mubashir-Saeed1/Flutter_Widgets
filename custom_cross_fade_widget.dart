import 'package:flutter/material.dart';

class CustomCrossFadeWidget extends StatelessWidget {
  final Widget secondaryChild;
  final Widget child;
  final bool isShowChild;
  final Alignment? alignment;
  const CustomCrossFadeWidget(
      {super.key,
      this.secondaryChild = const SizedBox(),
      this.alignment,
      this.isShowChild = false,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
        firstCurve: Curves.easeInOut, // Smoother transition
        secondCurve: Curves.easeInOut, // Smoother transition
        layoutBuilder: (Widget topChild, Key topChildKey, Widget bottomChild,
            Key bottomChildKey) {
          return Stack(
            alignment: alignment ??
                Alignment.center, // Ensures alignment during transition
            children: [
              Positioned(
                key: bottomChildKey,
                child: bottomChild,
              ),
              Positioned(
                key: topChildKey,
                child: topChild,
              ),
            ],
          );
        },
        firstChild: secondaryChild,
        secondChild: child,
        crossFadeState:
            isShowChild ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: Durations.medium4);
  }
}
