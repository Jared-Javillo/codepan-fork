import 'package:codepan/bloc/parent_bloc.dart';
import 'package:codepan/bloc/parent_event.dart';
import 'package:codepan/bloc/parent_state.dart';
import 'package:codepan/resources/dimensions.dart';
import 'package:codepan/widgets/placeholder_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef WidgetBlocBuilder = Widget Function(
  BuildContext context,
  ParentState state,
);
typedef BlocObserver = void Function(
  BuildContext context,
  ParentState state,
);
typedef BlocCreator = ParentBloc Function(
  BuildContext context,
);
enum PageScrollBehaviour {
  whole,
  none,
}

class PageBlocBuilder<E extends ParentEvent, B extends ParentBloc<E, S>,
    S extends ParentState> extends StatelessWidget {
  final Color? background, statusBarColor;
  final PageScrollBehaviour behaviour;
  final Widget? bottomNavigationBar;
  final WidgetBlocBuilder builder;
  final WidgetBlocBuilder? layer;
  final Brightness? brightness;
  final BlocObserver observer;
  final BlocCreator creator;

  const PageBlocBuilder({
    Key? key,
    required this.creator,
    required this.observer,
    required this.builder,
    this.layer,
    this.background,
    this.brightness,
    this.statusBarColor = Colors.transparent,
    this.behaviour = PageScrollBehaviour.whole,
    this.bottomNavigationBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final d = Dimension.of(context, isSafeArea: true);
    final t = Theme.of(context);
    PreferredSize? appBar;
    if (bottomNavigationBar == null) {
      appBar = PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: statusBarColor,
        ),
      );
    }
    return BlocProvider<B>(
      create: creator as B Function(BuildContext),
      child: Scaffold(
        backgroundColor: background ?? t.backgroundColor,
        appBar: appBar,
        body: _PageBlocBody<E, B, S>(
          builder: builder,
          maxHeight: d.max,
          layer: layer,
          behaviour: behaviour,
          observer: observer,
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class _PageBlocBody<E extends ParentEvent, B extends ParentBloc<E, S>,
    S extends ParentState> extends StatelessWidget {
  final PageScrollBehaviour behaviour;
  final WidgetBlocBuilder? layer;
  final WidgetBlocBuilder builder;
  final BlocObserver observer;
  final double maxHeight;

  const _PageBlocBody({
    Key? key,
    required this.observer,
    required this.builder,
    required this.maxHeight,
    required this.behaviour,
    this.layer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listener: observer,
      child: BlocBuilder<B, S>(
        builder: (context, state) {
          switch (behaviour) {
            case PageScrollBehaviour.none:
              return Stack(
                children: [
                  builder.call(context, state),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return PlaceholderHandler(
                        condition:
                            maxHeight == constraints.maxHeight && layer != null,
                        childBuilder: (context) {
                          return layer!.call(context, state);
                        },
                      );
                    },
                  ),
                ],
              );
            default:
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Stack(
                      children: [
                        builder.call(context, state),
                        PlaceholderHandler(
                          condition: maxHeight == constraints.maxHeight &&
                              layer != null,
                          childBuilder: (context) {
                            return SafeArea(
                              child: Container(
                                height: maxHeight,
                                child: layer!.call(context, state),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}

class PageBuilder extends StatelessWidget {
  final Color? background, statusBarColor;
  final PageScrollBehaviour behaviour;
  final Widget? bottomNavigationBar;
  final Brightness? brightness;
  final WidgetBuilder builder;
  final WidgetBuilder? layer;

  const PageBuilder({
    Key? key,
    required this.builder,
    this.background,
    this.layer,
    this.brightness,
    this.bottomNavigationBar,
    this.statusBarColor = Colors.transparent,
    this.behaviour = PageScrollBehaviour.whole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final d = Dimension.of(context, isSafeArea: true);
    final t = Theme.of(context);
    PreferredSize? appBar;
    if (bottomNavigationBar == null) {
      appBar = PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: statusBarColor,
        ),
      );
    }
    return Scaffold(
      backgroundColor: background ?? t.backgroundColor,
      appBar: appBar,
      body: _PageBody(
        builder: builder,
        maxHeight: d.max,
        layer: layer,
        behaviour: behaviour,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _PageBody extends StatelessWidget {
  final PageScrollBehaviour? behaviour;
  final WidgetBuilder builder;
  final WidgetBuilder? layer;
  final double? maxHeight;

  const _PageBody({
    Key? key,
    required this.builder,
    this.layer,
    this.behaviour,
    this.maxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (behaviour) {
      case PageScrollBehaviour.none:
        return Stack(
          children: [
            builder.call(context),
            LayoutBuilder(
              builder: (context, constraints) {
                return PlaceholderHandler(
                  condition:
                      maxHeight == constraints.maxHeight && layer != null,
                  childBuilder: (context) {
                    return layer!.call(context);
                  },
                );
              },
            ),
          ],
        );
      default:
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Stack(
                children: [
                  builder.call(context),
                  PlaceholderHandler(
                    condition:
                        maxHeight == constraints.maxHeight && layer != null,
                    childBuilder: (context) {
                      return SafeArea(
                        child: Container(
                          height: maxHeight,
                          child: layer!.call(context),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
    }
  }
}
