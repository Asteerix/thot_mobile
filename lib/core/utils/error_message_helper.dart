class ErrorMessageHelper {
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'Une erreur inconnue est survenue';
    if (error is String) return error;
    final errorString = error.toString();
    if (errorString.contains('SocketException')) {
      return 'Pas de connexion internet. Vérifiez votre réseau.';
    }
    if (errorString.contains('TimeoutException')) {
      return 'Délai d\'attente dépassé. Réessayez.';
    }
    if (errorString.contains('FormatException')) {
      return 'Format de données invalide reçu.';
    }
    return errorString;
  }
}