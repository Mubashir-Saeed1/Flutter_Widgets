import 'package:flutter/material.dart';

import '../../../core/constant/const.dart';
import '../../common/app_colors.dart';

class CustomPageIndicator extends StatelessWidget {
  final double currentPageValue;
  final int pageCount;

  const CustomPageIndicator({
    super.key,
    required this.currentPageValue,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    const double gap = 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Row(
            children: List.generate(pageCount, (i) {
              EdgeInsets margin;
              if (i == 0) {
                margin = const EdgeInsets.only(right: gap);
              } else if (i == pageCount - 1) {
                margin = const EdgeInsets.only(left: gap);
              } else {
                margin = const EdgeInsets.symmetric(horizontal: gap);
              }

              return Expanded(
                child: Container(
                  height: 6,
                  margin: margin,
                  decoration: const BoxDecoration(
                    borderRadius: roundedBorder,
                    color: kcWhiteColor,
                  ),
                ),
              );
            }),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              double segmentWidth =
                  (constraints.maxWidth - ((pageCount - 1) * (gap * 2))) /
                      pageCount;
              return Transform.translate(
                offset: Offset(
                  currentPageValue * (segmentWidth + (gap * 2)),
                  0,
                ),
                child: Container(
                  height: 6,
                  width: segmentWidth,
                  decoration: const BoxDecoration(
                    borderRadius: roundedBorder,
                    color: kcPrimaryColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
