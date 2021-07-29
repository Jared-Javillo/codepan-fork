import 'package:codepan/extensions/extensions.dart';
import 'package:codepan/resources/colors.dart';
import 'package:codepan/resources/dimensions.dart';
import 'package:codepan/widgets/button.dart';
import 'package:codepan/widgets/line_divider.dart';
import 'package:codepan/widgets/placeholder_handler.dart';
import 'package:codepan/widgets/text.dart';
import 'package:flutter/material.dart';

import 'dialog_config.dart';

class InformationDialog extends StatefulWidget {
  final String? title, message, positive, negative, titleFont;
  final VoidCallback? onPositiveTap, onNegativeTap, onDetach;
  final InformationController? controller;
  final bool dismissible, withDivider;
  final List<InlineSpan>? children;
  final Color fontColor;
  final Widget? child;

  const InformationDialog({
    Key? key,
    this.child,
    this.children,
    this.controller,
    this.dismissible = true,
    this.message,
    this.negative,
    this.onDetach,
    this.onNegativeTap,
    this.onPositiveTap,
    this.positive,
    this.title,
    this.withDivider = false,
    this.titleFont,
    this.fontColor = PanColors.text,
  }) : super(key: key);

  @override
  _InformationDialogState createState() => _InformationDialogState();
}

class _InformationDialogState extends State<InformationDialog> {
  late InformationController _controller;

  String? get message => _controller.value;

  @override
  void initState() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = InformationController(value: widget.message);
    }
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final d = Dimension.of(context);
    final t = Theme.of(context);
    final titleFont = t.dialogTheme.titleTextStyle?.fontFamily;
    return WillPopScope(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            GestureDetector(
              onTap: widget.dismissible ? () => _detach(context) : null,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(d.at(dialogRadius)),
                  ),
                  margin: EdgeInsets.all(d.at(dialogMargin)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(d.at(dialogRadius)),
                    child: Column(
                      children: <Widget>[
                        PanText(
                          text: widget.title,
                          fontSize: d.at(15),
                          fontFamily: widget.titleFont ?? titleFont,
                          fontWeight: FontWeight.bold,
                          fontColor: widget.fontColor,
                          alignment: Alignment.centerLeft,
                          textAlign: TextAlign.left,
                          padding: EdgeInsets.symmetric(
                            horizontal: d.at(20),
                            vertical: d.at(15),
                          ),
                        ),
                        PlaceholderHandler(
                          condition: widget.withDivider,
                          childBuilder: (context) {
                            return LineDivider(
                              color: t.primaryColor,
                              thickness: d.at(2),
                            );
                          },
                        ),
                        PlaceholderHandler(
                          condition: widget.child != null,
                          childBuilder: (context) => widget.child!,
                          placeholderBuilder: (context) {
                            return PanText(
                              text: message,
                              fontSize: d.at(13),
                              fontColor: widget.fontColor,
                              alignment: Alignment.centerLeft,
                              textAlign: TextAlign.left,
                              margin: EdgeInsets.only(
                                left: d.at(20),
                                right: d.at(20),
                                bottom: d.at(20),
                              ),
                              children: widget.children,
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            right: d.at(20),
                            bottom: d.at(5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PlaceholderHandler(
                                condition: widget.positive != null,
                                childBuilder: (context) {
                                  return PanButton(
                                    text: widget.positive,
                                    fontColor: t.primaryColor,
                                    fontSize: d.at(13),
                                    fontWeight: FontWeight.w600,
                                    radius: d.at(3),
                                    padding: EdgeInsets.all(d.at(10)),
                                    onPressed: () {
                                      _detach(context);
                                      widget.onPositiveTap?.call();
                                    },
                                  );
                                },
                              ),
                              PlaceholderHandler(
                                condition: widget.negative != null,
                                childBuilder: (context) {
                                  return PanButton(
                                    text: widget.negative,
                                    fontColor: widget.fontColor,
                                    fontSize: d.at(13),
                                    fontWeight: FontWeight.w600,
                                    radius: d.at(3),
                                    padding: EdgeInsets.all(d.at(10)),
                                    onPressed: () {
                                      _detach(context);
                                      widget.onNegativeTap?.call();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onWillPop: () {
        return Future.value(widget.dismissible);
      },
    );
  }

  void _detach(BuildContext context) {
    context.pop();
    widget.onDetach?.call();
  }
}

class InformationController extends ValueNotifier<String> {
  InformationController({
    String? value,
  }) : super(value ?? '');

  void setMessage(String message) {
    value = message;
  }
}
