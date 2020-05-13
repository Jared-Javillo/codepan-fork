import 'package:codepan/config/properties.dart';
import 'package:flutter/material.dart';
import 'package:codepan/widgets/text.dart';
import 'package:codepan/resources/colors.dart';

class PanButton extends StatelessWidget {
  final double fontSize, fontHeight, radius, borderWidth, width, height;
  final Color fontColor, background, borderColor;
  final EdgeInsetsGeometry margin, padding;
  final String text, fontFamily;
  final VoidCallback onPressed;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final Alignment alignment;
  final Widget child;

  const PanButton({
    Key key,
    this.text,
    this.fontSize,
    this.fontHeight,
    this.fontColor = Default.fontColor,
    this.fontFamily = Default.fontFamily,
    this.fontStyle = FontStyle.normal,
    this.fontWeight = FontWeight.normal,
    this.alignment = Alignment.center,
    this.background = C.none,
    this.margin,
    this.padding,
    this.radius = 0,
    this.borderWidth = 0,
    this.borderColor = C.none,
    this.onPressed,
    this.width,
    this.height,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var child = this.child != null
        ? this.child
        : PanText(
            text: text,
            fontSize: fontSize,
            fontColor: fontColor,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
          );
    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      child: FlatButton(
          color: background,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(color: borderColor, width: borderWidth)),
          padding: padding,
          child: child,
          onPressed: onPressed),
    );
  }
}
