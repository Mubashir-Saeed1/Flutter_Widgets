import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Called right before a drag starts, with the index of the item being
/// dragged.
typedef OnReorderDragStart = void Function(int index);

/// A drag-and-drop reorderable grid, built on top of [GridView.custom].
///
/// This is a trimmed down, self-contained replacement for the single
/// behaviour of the `reorderable_grid_view` package this app actually uses:
/// long-press (or custom delay) drag to reorder items laid out by an
/// arbitrary [SliverGridDelegate]. Kept in-house so the package dependency
/// isn't needed again.
class ReOrderableGridView extends StatefulWidget {
  const ReOrderableGridView({
    super.key,
    required this.onReorder,
    required this.gridDelegate,
    required this.childrenDelegate,
    this.onDragStart,
    this.dragStartDelay,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.reverse = false,
    this.padding,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  final ReorderCallback onReorder;
  final OnReorderDragStart? onDragStart;

  /// Delay before a long press starts the drag. Defaults to [kLongPressTimeout].
  final Duration? dragStartDelay;

  final SliverGridDelegate gridDelegate;
  final SliverChildDelegate childrenDelegate;

  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  @override
  State<ReOrderableGridView> createState() => _ReOrderableGridViewState();
}

class _ReOrderableGridViewState extends State<ReOrderableGridView>
    with TickerProviderStateMixin {
  final Map<int, _ReOrderableItemViewState> _items =
      <int, _ReOrderableItemViewState>{};

  MultiDragGestureRecognizer? _recognizer;
  int? _dragIndex;
  int? _dropIndex;
  _DragInfo? _dragInfo;

  Duration get _dragStartDelay => widget.dragStartDelay ?? kLongPressTimeout;

  static _ReOrderableGridViewState of(BuildContext context) {
    return context.findAncestorStateOfType<_ReOrderableGridViewState>()!;
  }

  bool _containsIndex(int index) => _items.containsKey(index);

  void _registerItem(_ReOrderableItemViewState item) {
    _items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
    }
  }

  void _unregisterItem(int index, _ReOrderableItemViewState item) {
    if (_items[index] == item) {
      _items.remove(index);
    }
  }

  void _startDragRecognizer(
    int index,
    PointerDownEvent event,
    MultiDragGestureRecognizer recognizer,
  ) {
    setState(() {
      if (_dragIndex != null) {
        _dragReset();
      }
      _dragIndex = index;
      _recognizer = recognizer
        ..onStart = _onDragStart
        ..addPointer(event);
    });
  }

  Drag _onDragStart(Offset position) {
    assert(_dragInfo == null);
    widget.onDragStart?.call(_dragIndex!);

    final item = _items[_dragIndex!]!;
    _dropIndex = _dragIndex;

    _dragInfo = _DragInfo(
      item: item,
      context: context,
      dragPosition: position,
      onUpdate: _onDragUpdate,
      onCancel: _onDragCancel,
      onEnd: _onDragEnd,
      readyCallback: () {
        item.dragging = true;
        _updateDragTarget();
      },
    )..startDrag();

    return _dragInfo!;
  }

  void _onDragUpdate(_DragInfo item, Offset position, Offset delta) {
    _updateDragTarget();
  }

  void _onDragCancel(_DragInfo item) {
    _dragReset();
    setState(() {});
  }

  void _onDragEnd(_DragInfo item) {
    widget.onReorder(_dragIndex!, _dropIndex!);
    _dragReset();
  }

  void _dragReset() {
    if (_dragIndex != null) {
      final item = _items[_dragIndex!];
      item?.dragging = false;

      _dragIndex = null;
      _dropIndex = null;

      for (final item in _items.values) {
        item.resetGap();
      }
    }

    _recognizer?.dispose();
    _recognizer = null;

    _dragInfo?.dispose();
    _dragInfo = null;
  }

  int _calcDropIndex(int defaultIndex) {
    if (_dragInfo == null) return defaultIndex;
    for (final item in _items.values) {
      final box = item.context.findRenderObject() as RenderBox;
      final pos = box.globalToLocal(_dragInfo!.centerInGlobal);
      if (pos.dx > 0 &&
          pos.dy > 0 &&
          pos.dx < box.size.width &&
          pos.dy < box.size.height) {
        return item.index;
      }
    }
    return defaultIndex;
  }

  void _updateDragTarget() {
    final newTargetIndex = _calcDropIndex(_dropIndex!);
    if (newTargetIndex != _dropIndex) {
      _dropIndex = newTargetIndex;
      for (final item in _items.values) {
        item.updateForGap(_dropIndex!);
      }
    }
  }

  Offset _posByIndex(int index) {
    if (index < 0) return Offset.zero;
    final renderObject = _items[index]?.context.findRenderObject();
    if (renderObject == null) return Offset.zero;
    final box = renderObject as RenderBox;
    final parentBox = context.findRenderObject() as RenderBox;
    return parentBox.globalToLocal(box.localToGlobal(Offset.zero));
  }

  Offset _offsetInDrag(int index) {
    if (_dragInfo == null || _dropIndex == null || _dragIndex == _dropIndex) {
      return Offset.zero;
    }

    final movingForward = _dropIndex! > _dragIndex!;
    final minPos = _dragIndex! < _dropIndex! ? _dragIndex! : _dropIndex!;
    final maxPos = _dragIndex! > _dropIndex! ? _dragIndex! : _dropIndex!;

    if (index < minPos || index > maxPos) {
      return Offset.zero;
    }

    if (movingForward) {
      if (!_containsIndex(index - 1) || !_containsIndex(index)) {
        return Offset.zero;
      }
      return _posByIndex(index - 1) - _posByIndex(index);
    } else {
      if (!_containsIndex(index + 1) || !_containsIndex(index)) {
        return Offset.zero;
      }
      return _posByIndex(index + 1) - _posByIndex(index);
    }
  }

  @override
  void dispose() {
    _recognizer?.dispose();
    _dragInfo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.custom(
      gridDelegate: widget.gridDelegate,
      childrenDelegate: widget.childrenDelegate,
      controller: widget.controller,
      reverse: widget.reverse,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      semanticChildCount: widget.semanticChildCount,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      dragStartBehavior: widget.dragStartBehavior,
    );
  }
}

/// Wraps each child so [ReOrderableGridView] can track its index, drag it,
/// and animate the gap left behind while another item is being dragged.
class ReOrderableItemView extends StatefulWidget {
  const ReOrderableItemView({
    required Key key,
    required this.child,
    required this.index,
  }) : super(key: key);

  final Widget child;
  final int index;

  /// Wraps [children] (and optional [header]/[footer] widgets, left
  /// untouched and non-draggable) into the [ReOrderableItemView]s expected
  /// by [ReOrderableGridView]'s `childrenDelegate`.
  static List<Widget> wrapMeList(
    List<Widget>? header,
    List<Widget> children,
    List<Widget>? footer,
  ) {
    final result = <Widget>[...header ?? const []];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      assert(
        child.key != null,
        'Every item of ReOrderableGridView must have a key.',
      );
      result.add(ReOrderableItemView(key: child.key!, index: i, child: child));
    }
    result.addAll(footer ?? const []);
    return result;
  }

  @override
  State<ReOrderableItemView> createState() => _ReOrderableItemViewState();
}

class _ReOrderableItemViewState extends State<ReOrderableItemView> {
  late _ReOrderableGridViewState _gridState;
  bool _dragging = false;

  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;
  AnimationController? _offsetAnimation;

  int get index => widget.index;

  set dragging(bool value) {
    if (mounted) setState(() => _dragging = value);
  }

  Offset get _offset {
    if (_offsetAnimation != null) {
      return Offset.lerp(
        _startOffset,
        _targetOffset,
        Curves.easeInOut.transform(_offsetAnimation!.value),
      )!;
    }
    return _targetOffset;
  }

  void updateForGap(int dropIndex) {
    if (!mounted || !_gridState._containsIndex(index) || _dragging) return;

    final newOffset = _gridState._offsetInDrag(index);
    if (newOffset == _targetOffset) return;
    _targetOffset = newOffset;

    if (_offsetAnimation == null) {
      _offsetAnimation = AnimationController(vsync: _gridState)
        ..duration = const Duration(milliseconds: 250)
        ..addListener(_rebuild)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _startOffset = _targetOffset;
            _offsetAnimation?.dispose();
            _offsetAnimation = null;
          }
        })
        ..forward(from: 0.0);
    } else {
      _startOffset = _offset;
      _offsetAnimation!.forward(from: 0.0);
    }
  }

  void resetGap() {
    setState(() {
      _offsetAnimation?.dispose();
      _offsetAnimation = null;
      _startOffset = Offset.zero;
      _targetOffset = Offset.zero;
    });
  }

  MultiDragGestureRecognizer _createDragRecognizer() {
    final delay = _gridState._dragStartDelay;
    if (delay == Duration.zero) {
      return ImmediateMultiDragGestureRecognizer(debugOwner: this);
    }
    return DelayedMultiDragGestureRecognizer(debugOwner: this, delay: delay);
  }

  @override
  void initState() {
    super.initState();
    _gridState = _ReOrderableGridViewState.of(context);
    _gridState._registerItem(this);
  }

  @override
  void didUpdateWidget(covariant ReOrderableItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _gridState._unregisterItem(oldWidget.index, this);
      _gridState._registerItem(this);
    }
  }

  @override
  void dispose() {
    _gridState._unregisterItem(index, this);
    _offsetAnimation?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          _gridState._startDragRecognizer(
            index,
            event,
            _createDragRecognizer(),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Transform(
              transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
              child: Offstage(
                offstage: _dragging,
                child: Container(constraints: constraints, child: widget.child),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Drives the drag proxy shown in the [Overlay] while an item is being
/// dragged, and auto-scrolls the grid when the drag reaches its edge.
class _DragInfo extends Drag {
  _DragInfo({
    required _ReOrderableItemViewState item,
    required this.context,
    required this.dragPosition,
    required this.readyCallback,
    this.onUpdate,
    this.onCancel,
    this.onEnd,
  })  : index = item.index,
        child = item.widget.child,
        itemSize = item.context.size! {
    final renderBox = item.context.findRenderObject()! as RenderBox;
    dragOffset = renderBox.globalToLocal(dragPosition);
    dragExtent = renderBox.size.height;
    dragSize = renderBox.size;
    scrollable = Scrollable.of(item.context);

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    zeroOffset = overlayBox.globalToLocal(Offset.zero);
  }

  final int index;
  final void Function(_DragInfo item, Offset position, Offset delta)?
      onUpdate;
  final void Function(_DragInfo item)? onCancel;
  final void Function(_DragInfo item)? onEnd;
  final VoidCallback readyCallback;

  final BuildContext context;
  final Widget child;
  final Size itemSize;
  late final ScrollableState scrollable;

  Offset dragPosition;
  late final Offset dragOffset;
  late final double dragExtent;
  late final Size dragSize;
  late final Offset zeroOffset;

  OverlayEntry? _overlayEntry;
  bool _hasEnded = false;
  bool _autoScrolling = false;

  Offset get _posInGlobal => dragPosition - dragOffset;
  Offset get centerInGlobal => _posInGlobal + dragSize.center(Offset.zero);

  void startDrag() {
    readyCallback();
    _overlayEntry = OverlayEntry(builder: _createProxy);
    Overlay.of(context).insert(_overlayEntry!);
    _scrollIfNeeded();
  }

  Widget _createProxy(BuildContext context) {
    final position = _posInGlobal + zeroOffset;
    return Positioned(
      top: position.dy,
      left: position.dx,
      child: SizedBox(
        width: itemSize.width,
        height: itemSize.height,
        child: Material(elevation: 3.0, child: child),
      ),
    );
  }

  @override
  void update(DragUpdateDetails details) {
    dragPosition += details.delta;
    onUpdate?.call(this, dragPosition, details.delta);
    _overlayEntry?.markNeedsBuild();
    _scrollIfNeeded();
  }

  void _scrollIfNeeded() async {
    if (_hasEnded || _autoScrolling) return;

    final position = scrollable.position;
    final scrollRenderBox = scrollable.context.findRenderObject()! as RenderBox;
    final scrollStart = scrollRenderBox.localToGlobal(Offset.zero).dy;
    final scrollEnd = scrollStart + scrollRenderBox.size.height;

    final dragStart = _posInGlobal.dy;
    final dragEnd = dragStart + dragExtent;

    const double maxStep = 5;
    double? newOffset;

    if (dragEnd > scrollEnd && position.pixels < position.maxScrollExtent) {
      final overSize = dragEnd - scrollEnd;
      final step = overSize < maxStep ? overSize : maxStep;
      newOffset = (position.pixels + step)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
    } else if (dragStart < scrollStart &&
        position.pixels > position.minScrollExtent) {
      final overSize = scrollStart - dragStart;
      final step = overSize < maxStep ? overSize : maxStep;
      newOffset = (position.pixels - step)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
    }

    if (newOffset != null && (newOffset - position.pixels).abs() >= 1.0) {
      _autoScrolling = true;
      await position.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 14),
        curve: Curves.linear,
      );
      _autoScrolling = false;
      _scrollIfNeeded();
    }
  }

  @override
  void end(DragEndDetails details) {
    onEnd?.call(this);
    _hasEnded = true;
  }

  @override
  void cancel() {
    onCancel?.call(this);
    _hasEnded = true;
  }

  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}


class SliverGridDelegateWithFirstItemBigger extends SliverGridDelegate {
  const SliverGridDelegateWithFirstItemBigger({
    required this.crossAxisCount,
    this.firstItemCrossAxisCellCount = 2,
    this.firstItemMainAxisCellCount = 2,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  }) : assert(crossAxisCount > 0),
       assert(firstItemCrossAxisCellCount > 0),
       assert(firstItemCrossAxisCellCount < crossAxisCount),
       assert(firstItemMainAxisCellCount > 0),
       assert(mainAxisSpacing >= 0),
       assert(crossAxisSpacing >= 0),
       assert(childAspectRatio > 0);

  final int crossAxisCount;
  final int firstItemCrossAxisCellCount;
  final int firstItemMainAxisCellCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double usableCrossAxisExtent =
        (constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1))
            .clamp(0.0, double.infinity);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final double childMainAxisExtent = childCrossAxisExtent / childAspectRatio;
    return _SliverGridWithFirstItemBiggerLayout(
      crossAxisCount: crossAxisCount,
      firstItemCrossAxisCellCount: firstItemCrossAxisCellCount,
      firstItemMainAxisCellCount: firstItemMainAxisCellCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithFirstItemBigger oldDelegate) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        oldDelegate.firstItemCrossAxisCellCount !=
            firstItemCrossAxisCellCount ||
        oldDelegate.firstItemMainAxisCellCount != firstItemMainAxisCellCount ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.childAspectRatio != childAspectRatio;
  }
}

class _SliverGridWithFirstItemBiggerLayout extends SliverGridLayout {
  const _SliverGridWithFirstItemBiggerLayout({
    required this.crossAxisCount,
    required this.firstItemCrossAxisCellCount,
    required this.firstItemMainAxisCellCount,
    required this.mainAxisStride,
    required this.crossAxisStride,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.childMainAxisExtent,
    required this.childCrossAxisExtent,
    required this.reverseCrossAxis,
  });

  final int crossAxisCount;
  final int firstItemCrossAxisCellCount;
  final int firstItemMainAxisCellCount;
  final double mainAxisStride;
  final double crossAxisStride;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childMainAxisExtent;
  final double childCrossAxisExtent;
  final bool reverseCrossAxis;

  // Number of regular columns to the right of the first (big) item, within
  // the header block.
  int get _sideColumnCount => crossAxisCount - firstItemCrossAxisCellCount;

  // Number of regular single-cell tiles that fill the header block beside
  // the first item (indices 1..._sideSlotCount).
  int get _sideSlotCount => _sideColumnCount * firstItemMainAxisCellCount;

  // Total cross axis extent of a full row (without a trailing gap).
  double get _rowCrossAxisExtent =>
      crossAxisCount * crossAxisStride - crossAxisSpacing;

  double get _headerMainAxisExtent => _extentForCellCount(
    firstItemMainAxisCellCount,
    childMainAxisExtent,
    mainAxisSpacing,
  );

  double _extentForCellCount(
    int cellCount,
    double childExtent,
    double spacing,
  ) {
    return cellCount * childExtent + (cellCount - 1) * spacing;
  }

  double _crossAxisExtentForCellCount(int cellCount) {
    return _extentForCellCount(
      cellCount,
      childCrossAxisExtent,
      crossAxisSpacing,
    );
  }

  double _offsetFromStart(double crossAxisStart, double childExtent) {
    if (reverseCrossAxis) {
      return _rowCrossAxisExtent - crossAxisStart - childExtent;
    }
    return crossAxisStart;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (mainAxisStride <= precisionErrorTolerance) {
      return 0;
    }
    final int row = scrollOffset ~/ mainAxisStride;
    if (row < firstItemMainAxisCellCount) {
      return 0;
    }
    return 1 +
        _sideSlotCount +
        (row - firstItemMainAxisCellCount) * crossAxisCount;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (mainAxisStride <= precisionErrorTolerance) {
      return 0;
    }
    final int mainAxisCount = (scrollOffset / mainAxisStride).ceil();
    if (mainAxisCount <= firstItemMainAxisCellCount) {
      final int sideCovered = _sideColumnCount * mainAxisCount;
      return sideCovered.clamp(0, _sideSlotCount);
    }
    return _sideSlotCount +
        (mainAxisCount - firstItemMainAxisCellCount) * crossAxisCount;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (index == 0) {
      final double extent = _crossAxisExtentForCellCount(
        firstItemCrossAxisCellCount,
      );
      return SliverGridGeometry(
        scrollOffset: 0,
        crossAxisOffset: _offsetFromStart(0, extent),
        mainAxisExtent: _headerMainAxisExtent,
        crossAxisExtent: extent,
      );
    }

    if (index <= _sideSlotCount) {
      final int sideIndex = index - 1;
      final int row = sideIndex ~/ _sideColumnCount;
      final int column =
          firstItemCrossAxisCellCount + sideIndex % _sideColumnCount;
      final double crossAxisStart = column * crossAxisStride;
      return SliverGridGeometry(
        scrollOffset: row * mainAxisStride,
        crossAxisOffset: _offsetFromStart(crossAxisStart, childCrossAxisExtent),
        mainAxisExtent: childMainAxisExtent,
        crossAxisExtent: childCrossAxisExtent,
      );
    }

    final int gridIndex = index - 1 - _sideSlotCount;
    final int row = firstItemMainAxisCellCount + gridIndex ~/ crossAxisCount;
    final int column = gridIndex % crossAxisCount;
    final double crossAxisStart = column * crossAxisStride;
    return SliverGridGeometry(
      scrollOffset: row * mainAxisStride,
      crossAxisOffset: _offsetFromStart(crossAxisStart, childCrossAxisExtent),
      mainAxisExtent: childMainAxisExtent,
      crossAxisExtent: childCrossAxisExtent,
    );
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount == 0) {
      return 0.0;
    }
    final int remaining = childCount - 1;
    int rows;
    if (remaining <= _sideSlotCount) {
      rows = firstItemMainAxisCellCount;
    } else {
      final int afterSide = remaining - _sideSlotCount;
      final int extraRows = ((afterSide - 1) ~/ crossAxisCount) + 1;
      rows = firstItemMainAxisCellCount + extraRows;
    }
    return mainAxisStride * rows - mainAxisSpacing;
  }
}
