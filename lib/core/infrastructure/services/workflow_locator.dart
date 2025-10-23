import 'package:thot/core/infrastructure/services/service_locator.dart';
class WorkflowLocator {
  static final WorkflowLocator instance = WorkflowLocator._internal();
  factory WorkflowLocator() => instance;
  WorkflowLocator._internal();
  void initialize() {
  }
  static void resetForTest() {
  }
}