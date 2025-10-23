abstract class SettingsFailure {
  final String message;
  const SettingsFailure(this.message);
}
class SettingsFailureNetwork extends SettingsFailure {
  const SettingsFailureNetwork(super.message);
}
class SettingsFailureServer extends SettingsFailure {
  const SettingsFailureServer(super.message);
}
class SettingsFailureUnauthorized extends SettingsFailure {
  const SettingsFailureUnauthorized(super.message);
}
class SettingsFailureNotFound extends SettingsFailure {
  const SettingsFailureNotFound(super.message);
}
class SettingsFailureUnknown extends SettingsFailure {
  const SettingsFailureUnknown(super.message);
}