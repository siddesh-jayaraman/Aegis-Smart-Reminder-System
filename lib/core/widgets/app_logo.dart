import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor,
    this.borderRadius = 20,
  });

  final double size;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset('assets/icon.png', fit: BoxFit.contain),
    );
  }
}
