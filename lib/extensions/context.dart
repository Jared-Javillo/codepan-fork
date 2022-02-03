import 'package:codepan/bloc/parent_bloc.dart';
import 'package:codepan/transitions/route_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension BuildContextUtils on BuildContext {
  void popAllRoutes() {
    final navigator = Navigator.of(this);
    while (navigator.canPop()) {
      navigator.pop();
    }
  }

  void pop() {
    Navigator.of(this).pop();
  }

  void push({required Widget page}) {
    Navigator.of(this).push(
      CupertinoPageRoute(
        builder: (context) {
          return page;
        },
      ),
    );
  }

  void replace({required Widget page}) {
    Navigator.of(this).pushReplacement(
      FadeRoute(
        enter: page,
      ),
    );
  }

  void fadeIn({required Widget page}) {
    Navigator.of(this).push(
      FadeRoute(
        enter: page,
      ),
    );
  }

  void slideDialog({required Widget page}) {
    showGeneralDialog(
      context: this,
      transitionDuration: Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return page;
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: Offset(0, 1),
            end: Offset(0, 0),
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  T blocOf<T extends ParentBloc>() {
    return BlocProvider.of<T>(this);
  }
}
