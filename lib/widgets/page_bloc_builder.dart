import 'package:codepan/bloc/parent_bloc.dart';
import 'package:codepan/bloc/parent_event.dart';
import 'package:codepan/bloc/parent_state.dart';
import 'package:codepan/resources/dimensions.dart';
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
  final Color background, statusBarColor;
  final WidgetBlocBuilder builder, layer;
  final PageScrollBehaviour behaviour;
  final Brightness brightness;
  final BlocObserver observer;
  final BlocCreator creator;

  const PageBlocBuilder({
    Key key,
    @required this.builder,
    @required this.creator,
    @required this.observer,
    this.layer,
    this.background,
    this.statusBarColor = Colors.transparent,
    this.brightness,
    this.behaviour = PageScrollBehaviour.whole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final d = Dimension.of(context, isSafeArea: true);
    final t = Theme.of(context);
    final a = t.appBarTheme;
    return BlocProvider<B>(
      create: creator,
      child: Scaffold(
        backgroundColor: background ?? t.backgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(
            elevation: 0,
            brightness: brightness ?? a.brightness,
            backgroundColor: statusBarColor,
          ),
        ),
        body: _PageBody<E, B, S>(
          builder: builder,
          maxHeight: d.max,
          layer: layer,
          behaviour: behaviour,
          observer: observer,
        ),
      ),
    );
  }
}

class _PageBody<E extends ParentEvent, B extends ParentBloc<E, S>,
    S extends ParentState> extends StatelessWidget {
  final WidgetBlocBuilder builder, layer;
  final PageScrollBehaviour behaviour;
  final BlocObserver observer;
  final double maxHeight;

  const _PageBody({
    Key key,
    @required this.builder,
    @required this.maxHeight,
    @required this.behaviour,
    @required this.observer,
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
                  Container(
                    child: layer?.call(context, state),
                  ),
                ],
              );
              break;
            default:
              return SingleChildScrollView(
                child: Stack(
                  children: [
                    builder.call(context, state),
                    SafeArea(
                      child: Container(
                        height: maxHeight,
                        child: layer?.call(context, state),
                      ),
                    ),
                  ],
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
