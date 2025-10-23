import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../mobile/screens/mode_selection_screen.dart';
mixin ModeSelectionMixin<T extends StatefulWidget> on State<T> {
  ProfileType _selectedType = ProfileType.journalist;
  ProfileType get selectedType => _selectedType;
  void selectType(ProfileType type) {
    setState(() {
      _selectedType = type;
    });
  }
  void continueToRegistration(BuildContext context) {
    if (_selectedType == ProfileType.journalist) {
      context.go(RouteNames.registrationStepper);
    } else {
      context.go(RouteNames.register);
    }
  }
}