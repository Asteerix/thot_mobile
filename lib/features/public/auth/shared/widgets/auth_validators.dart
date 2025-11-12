class AuthValidators {
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!value.contains('@')) {
      return 'Veuillez entrer un email valide';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  static String? strongPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }
    return null;
  }

  static String? confirmPasswordValidator(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static bool hasMinLength(String password, {int minLength = 8}) {
    return password.length >= minLength;
  }

  static bool hasUppercase(String password) {
    return RegExp(r'[A-Z]').hasMatch(password);
  }

  static bool hasLowercase(String password) {
    return RegExp(r'[a-z]').hasMatch(password);
  }

  static bool hasDigit(String password) {
    return RegExp(r'[0-9]').hasMatch(password);
  }

  static bool hasSpecialChar(String password) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  static String? requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Le champ $fieldName est requis';
    }
    return null;
  }

  static String? minLengthValidator(
      String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Le champ $fieldName est requis';
    }
    if (value.length < minLength) {
      return '$fieldName doit contenir au moins $minLength caractères';
    }
    return null;
  }

  static String? maxLengthValidator(
      String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Le champ $fieldName est requis';
    }
    if (value.length > maxLength) {
      return '$fieldName ne peut pas dépasser $maxLength caractères';
    }
    return null;
  }

  static String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un nom d\'utilisateur';
    }
    if (value.length < 3) {
      return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    }
    if (value.length > 20) {
      return 'Le nom d\'utilisateur ne peut pas dépasser 20 caractères';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et underscores';
    }
    return null;
  }

  static String? displayNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (value.length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }
    return null;
  }

  static String? bioValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > 500) {
      return 'La bio ne peut pas dépasser 500 caractères';
    }
    return null;
  }
}
