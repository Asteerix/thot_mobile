import 'package:flutter/material.dart';

class WelcomeLogo extends StatelessWidget {
  final double size;
  final bool usePrimaryColor;
  final bool withHero;
  const WelcomeLogo({
    super.key,
    this.size = 100,
    this.usePrimaryColor = false,
    this.withHero = true,
  });
  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/logo.jpeg',
      width: size * 2,
      height: size,
      fit: BoxFit.contain,
    );
    if (withHero) {
      return Hero(
        tag: 'app_logo',
        child: logo,
      );
    }
    return logo;
  }
}
