import 'package:flutter/material.dart';

class PlaceholderHandler extends StatelessWidget {
  final Widget child, placeholder;
  final EdgeInsets margin, padding;
  final Alignment alignment;
  final double width, height;
  final bool condition;
  final Color color;

  const PlaceholderHandler({
    Key key,
    @required this.child,
    this.placeholder,
    this.condition = false,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      child: condition ? child : placeholder,
    );
  }
}
