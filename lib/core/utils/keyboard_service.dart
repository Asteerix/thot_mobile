import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class KeyboardService {
  static final KeyboardService _instance = KeyboardService._internal();
  factory KeyboardService() => _instance;
  KeyboardService._internal();
  final Set<PhysicalKeyboardKey> _pressedKeys = {};
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.physicalKey);
    } else if (event is KeyUpEvent) {
      if (!_pressedKeys.contains(event.physicalKey)) {
        return true;
      }
      _pressedKeys.remove(event.physicalKey);
    }
    return false;
  }
  void clearKeyboardState() {
    _pressedKeys.clear();
  }
}
mixin KeyboardHandlerMixin<T extends StatefulWidget> on State<T> {
  late final KeyboardService _keyboardService;
  @override
  void initState() {
    super.initState();
    _keyboardService = KeyboardService();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }
  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _keyboardService.clearKeyboardState();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    super.dispose();
  }
  bool _handleKey(KeyEvent event) {
    return _keyboardService.handleKeyEvent(event);
  }
  void dismissKeyboard() {
    KeyboardService.dismissKeyboard(context);
  }
}
extension KeyboardDismiss on BuildContext {
  void dismissKeyboard() {
    KeyboardService.dismissKeyboard(this);
  }
}