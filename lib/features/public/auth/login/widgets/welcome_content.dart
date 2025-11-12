import 'package:flutter/material.dart';

class WelcomeTitle extends StatelessWidget {
  final bool usePrimaryColor;
  const WelcomeTitle({
    super.key,
    this.usePrimaryColor = false,
  });
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class WelcomeSubtitle extends StatelessWidget {
  final bool usePrimaryColor;
  const WelcomeSubtitle({
    super.key,
    this.usePrimaryColor = false,
  });
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
