import 'package:carpool/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

import '../../common/ui_helpers.dart';

/// Generic Dropdown container that uses a builder to render custom items.
/// This is useful for creating dropdowns with complex item layouts.
class AppBuilderDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final Function(T) onChanged;
  final Widget Function(
      BuildContext context, T item, bool isSelected, bool isLast) itemBuilder;
  final Widget Function(BuildContext context, T item)?
      selectedItemBuilder; // For the collapsed header view
  final String? hintText;

  const AppBuilderDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    this.selectedItemBuilder,
    this.hintText,
  });

  @override
  AppBuilderDropdownState<T> createState() => AppBuilderDropdownState<T>();
}

class AppBuilderDropdownState<T> extends State<AppBuilderDropdown<T>> {
  late T? _selectedValue;

  @override
  void initState() {
    _selectedValue = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AppBuilderDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value;
    }
  }

  void _onItemSelected(T item) {
    setState(() {
      _selectedValue = item;
    });
    widget.onChanged(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidthValue = screenWidth(context);
    // Define constraints to make the popup menu match the width of the button
    final BoxConstraints menuConstraints = BoxConstraints(
      minWidth: screenWidthValue * 0.5, // Full screen width minus some margin
      maxWidth: screenWidthValue * 0.8, // Fixed width
    );

    return PopupMenuButton<T>(
        initialValue: _selectedValue,
        onSelected: _onItemSelected,
        constraints: menuConstraints,
        itemBuilder: (BuildContext context) {
          return widget.items.map((item) {
            final isSelected = item == _selectedValue;
            final isLast = item == widget.items.last;
            return PopupMenuItem<T>(
              value: item,
              padding: const EdgeInsets.only(left: 16),
              height: 56.0,
              child: SizedBox(
                width: double.infinity, // Ensure the container takes full width
                child: widget.itemBuilder(context, item, isSelected, isLast),
              ),
            );
          }).toList();
        },
        color: kcPrimaryBackgroundColor,
        elevation: 1,
        enableFeedback: true,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.over,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: kcWhiteColor, width: 2),
        ),
        menuPadding: EdgeInsets.zero,
        child: _selectedValue != null
            ? widget.selectedItemBuilder?.call(context, _selectedValue as T) ??
                widget.itemBuilder(context, _selectedValue as T, true, false)
            : Text(
                widget.hintText ?? 'Select an item',
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: kcBlackColor),
                overflow: TextOverflow.ellipsis,
              ));
  }
}
