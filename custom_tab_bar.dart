import 'package:flutter/material.dart';

import '../../../core/constant/const.dart';
import '../../common/app_colors.dart';
import 'custom_text.dart';

class CustomTabBar extends StatelessWidget {
  final PageController pageController;
  final int currentPageIndex;
  final Function(int) onPageChanged;
  final List<String> titles;

  const CustomTabBar({
    super.key,
    required this.pageController,
    required this.currentPageIndex,
    required this.onPageChanged,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: kcWhiteColor,
        borderRadius: roundedBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double totalWidth = constraints.maxWidth;
          double tabWidth = totalWidth / titles.length;

          return Stack(
            children: [
              AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double page = pageController.hasClients
                      ? (pageController.page ?? 0)
                      : 0;
                  double position = page * tabWidth;

                  return Positioned(
                    left: position,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: tabWidth,
                      decoration: const BoxDecoration(
                        color: kcPrimaryColor,
                        borderRadius: roundedBorder,
                      ),
                    ),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(titles.length, (index) {
                  return _buildTab(
                    title: titles[index],
                    onTap: () => onPageChanged(index),
                    isSelected: currentPageIndex == index,
                    width: tabWidth,
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  InkWell _buildTab({
    required String title,
    required void Function() onTap,
    required bool isSelected,
    required double width,
  }) {
    return InkWell(
      overlayColor: kOverlayColor,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Center(
          child: ParagraphP1(
            title,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? kcWhiteColor : kcBlackColor,
          ),
        ),
      ),
    );
  }
}
