import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class StaggeredGridView extends StatelessWidget {
  final List<String> items;
  final void Function(int) onTap;
  final List<int> selectedItems;
  final num? crossAxisMaxCount;
  const StaggeredGridView({
    super.key,
    required this.items,
    required this.onTap,
    required this.selectedItems,
    this.crossAxisMaxCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final minTileWidth =
            (constraints.maxWidth - spacing * 2) / (crossAxisMaxCount ?? 3);
        final textStyles = <TextStyle>[];
        final naturalTileWidths = <double>[];
        final tileWidths = <double>[];

        for (var index = 0; index < items.length; index++) {
          final isSelected = selectedItems.contains(index);
          final textStyle = GoogleFonts.inter(
            color: isSelected ? AppColors.primary : AppColors.body,
            fontSize: 12,
          );
          final textPainter = TextPainter(
            text: TextSpan(text: items[index], style: textStyle),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          textStyles.add(textStyle);
          naturalTileWidths.add(textPainter.width + 60);
          tileWidths.add(
            (textPainter.width + 60)
                .clamp(minTileWidth, constraints.maxWidth)
                .toDouble(),
          );
        }

        final rows = <List<int>>[];
        for (var index = 0; index < items.length; index++) {
          if (rows.isEmpty) rows.add([]);
          final row = rows.last;
          final usedWidth = row.fold<double>(
            0,
            (total, itemIndex) => total + tileWidths[itemIndex],
          );
          final requiredWidth =
              usedWidth +
              tileWidths[index] +
              (row.isEmpty ? 0 : spacing * row.length);
          if (row.length == 3 || requiredWidth > constraints.maxWidth) {
            rows.add([index]);
          } else {
            row.add(index);
          }
        }

        return Column(
          children: List.generate(rows.length, (rowIndex) {
            final row = rows[rowIndex];
            return Padding(
              padding: EdgeInsets.only(
                bottom: rowIndex == rows.length - 1 ? 0 : spacing,
              ),
              child: Row(
                children: List.generate(row.length * 2 - 1, (position) {
                  if (position.isOdd) return const SizedBox(width: spacing);
                  final index = row[position ~/ 2];
                  return Expanded(
                    flex: (naturalTileWidths[index] * 100).round(),
                    child: _buildTile(index, textStyles[index]),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTile(int index, TextStyle textStyle) {
    final isSelected = selectedItems.contains(index);
    return InkWell(
      overlayColor: WidgetStateProperty.all(AppColors.transparent),
      onTap: () => onTap(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.muted,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(6),
              ),
              value: isSelected,
              onChanged: (t) => onTap(index),
            ),
            Expanded(
              child: Text(
                items[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

mixin MultiSelectMixin on ChangeNotifier {
  void toggleSelection(List<int> selected, int index, {int? maxSelected}) {
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      if (maxSelected != null && selected.length >= maxSelected) return;
      selected.add(index);
    }
    notifyListeners();
  }
}
