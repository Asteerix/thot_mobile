class ValidationConstants {
  const ValidationConstants._();
  static const int maxTitleLength = 150;
  static const int maxContentLength = 5000;
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;
}
class ErrorMessages {
  const ErrorMessages._();
  static const String requiredField = 'Ce champ est requis';
  static const String invalidEmail = 'Email invalide';
  static const String weakPassword =
      'Le mot de passe doit contenir au moins 8 caractères';
  static const String passwordsDoNotMatch =
      'Les mots de passe ne correspondent pas';
  static const String invalidCredentials = 'Email ou mot de passe incorrect';
  static const String accountBanned = 'Votre compte a été suspendu';
  static const String tooManyRequests =
      'Trop de tentatives, veuillez réessayer plus tard';
  static const String networkError = 'Erreur de connexion';
  static const String unknownError = 'Une erreur inattendue s\'est produite';
}