import 'package:codepan/extensions/list.dart';
import 'package:flutter/material.dart';

typedef ListItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

typedef ListItemCallback<T> = void Function(
  T item,
);

class ReorderableAnimatedList<T> extends StatefulWidget {
  final ListItemCallback<T>? onRemoveItem, onAddItem;
  final AnimatedListController<T> itemController;
  final ScrollController? scrollController;
  final ListItemBuilder<T> itemBuilder;
  final ReorderCallback onReorder;
  final EdgeInsets? padding;
  final List<T> items;

  const ReorderableAnimatedList({
    Key? key,
    required this.itemController,
    required this.onReorder,
    required this.itemBuilder,
    required this.items,
    this.onRemoveItem,
    this.onAddItem,
    this.scrollController,
    this.padding,
  }) : super(key: key);

  @override
  State<ReorderableAnimatedList<T>> createState() =>
      _ReorderableAnimatedListState<T>();
}

class _ReorderableAnimatedListState<T>
    extends State<ReorderableAnimatedList<T>> {
  AnimatedListController<T> get itemController => widget.itemController;

  @override
  void initState() {
    super.initState();
    itemController.addListener(() {
      if (itemController.action == AnimatedListAction.add) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: widget.onReorder,
      padding: widget.padding,
      scrollController: widget.scrollController,
      children: widget.items.transform<Widget>((item, index) {
        final child = widget.itemBuilder.call(context, item, index);
        return AnimatedListItem<T>(
          key: child.key,
          child: child,
          index: index,
          item: item,
          onRemoveItem: widget.onRemoveItem,
          onAddItem: widget.onAddItem,
          itemController: itemController,
          visibility: itemController.willInsert(item)
              ? Visibility.gone
              : Visibility.visible,
        );
      }),
    );
  }
}

class AnimatedListItem<T> extends StatefulWidget {
  final ListItemCallback<T>? onRemoveItem, onAddItem;
  final AnimatedListController<T> itemController;
  final Visibility visibility;
  final Widget child;
  final int index;
  final T item;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    required this.itemController,
    required this.item,
    this.visibility = Visibility.visible,
    this.onRemoveItem,
    this.onAddItem,
  }) : super(key: key);

  @override
  State<AnimatedListItem<T>> createState() => _AnimatedListItemState<T>();
}

class _AnimatedListItemState<T> extends State<AnimatedListItem<T>>
    with TickerProviderStateMixin {
  late Animation<double> _size, _opacity;
  late AnimationController _animController;
  late Visibility _visibility;

  AnimatedListController<T> get itemController => widget.itemController;

  Visibility get visibility => _visibility;

  @override
  void initState() {
    super.initState();
    _visibility = widget.visibility;
    _animController = AnimationController(
      duration: Duration(milliseconds: 500),
      value: visibility == Visibility.visible ? 1 : 0,
      vsync: this,
    );
    _size = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(0.5, 1, curve: Curves.easeInOut),
      ),
    );
    _animController.addStatusListener((status) {
      final item = widget.item;
      switch (status) {
        case AnimationStatus.dismissed:
          widget.onRemoveItem?.call(item);
          _visibility = Visibility.gone;
          break;
        case AnimationStatus.completed:
          widget.onAddItem?.call(item);
          _visibility = Visibility.visible;
          break;
        default:
          break;
      }
    });
    itemController.addListener(() {
      if (widget.item == itemController.item) {
        switch (itemController.action) {
          case AnimatedListAction.remove:
            _animController.reverse();
            break;
          case AnimatedListAction.add:
            _animController.forward();
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SizeTransition(
        axis: Axis.vertical,
        sizeFactor: _size,
        child: widget.child,
      ),
    );
  }
}

enum Visibility {
  visible,
  gone,
}

enum AnimatedListAction {
  remove,
  add,
}

class AnimatedListController<T> extends ChangeNotifier {
  AnimatedListAction? _action;
  T? _item;

  AnimatedListController();

  AnimatedListAction? get action => _action;

  T? get item => _item;

  bool willInsert(T item) {
    return _action == AnimatedListAction.add && _item == item;
  }

  void notifyItemChange({
    required T item,
    required AnimatedListAction action,
  }) {
    _action = action;
    _item = item;
    notifyListeners();
  }
}
