import 'package:thot/core/constants/api_routes_helper.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/core/network/api_client.dart';
import 'package:thot/core/connectivity/connectivity_service.dart';
import 'package:thot/core/storage/token_service.dart';
import 'package:thot/core/infrastructure/exceptions/api_exception.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
class LoginResponse {
  final UserProfile userProfile;
  final String token;
  LoginResponse({
    required this.userProfile,
    required this.token,
  });
}
class AuthException implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic>? data;
  AuthException(this.message, {this.code = 'unknown', this.data});
  @override
  String toString() => message;
}
class AuthRepositoryImpl with ConnectivityAware {
  static const String _userKey = 'user_profile';
  final ApiService _apiService;
  AuthRepositoryImpl({required ApiService apiService})
      : _apiService = apiService;
  dynamic _extractUserData(Map<String, dynamic> response, String context) {
    dynamic userData;
    if (response['data'] != null && response['data']['user'] != null) {
      userData = response['data']['user'];
      developer.log(
        '$context: API response has nested user structure',
        name: 'AuthRepository',
        error: {
          'using': 'response[data][user]',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } else if (response['data'] != null) {
      userData = response['data'];
    } else {
      userData = response;
    }
    return userData;
  }
  Future<bool> isAuthenticated() async {
    try {
      final isLoggedIn = await TokenService.isLoggedIn();
      if (!isLoggedIn) {
        return false;
      }
      if (await TokenService.needsRefresh()) {
        try {
          await refreshToken();
        } catch (e) {
          return await TokenService.isLoggedIn();
        }
      }
      return true;
    } catch (e) {
      developer.log(
        'Error checking authentication status',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return false;
    }
  }
  Future<void> refreshToken() async {
    try {
      developer.log(
        'Attempting to refresh token',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
      final currentToken = await TokenService.getToken();
      if (currentToken == null) {
        throw AuthException('No token to refresh', code: 'no_token');
      }
      final response = await _apiService.post(
        ApiRoutesHelper.refreshToken,
        data: {'token': currentToken},
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Token refresh failed',
          code: 'refresh_failed',
        );
      }
      final data = response.data['data'] ?? response.data;
      final newToken = data['token'];
      if (newToken == null) {
        throw AuthException('No token in response', code: 'invalid_response');
      }
      final userType = await TokenService.getUserType();
      await TokenService.saveToken(newToken, userType);
      developer.log(
        'Token refreshed successfully',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Token refresh error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (e is AuthException) rethrow;
      throw AuthException('Failed to refresh token', code: 'refresh_error');
    }
  }
  Future<LoginResponse> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      throw AuthException('Email is required', code: 'email_required');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(normalizedEmail)) {
      throw AuthException('Invalid email format', code: 'invalid_email');
    }
    if (password.isEmpty) {
      throw AuthException('Password is required', code: 'password_required');
    }
    try {
      final response = await _apiService.post(
        ApiRoutesHelper.login,
        data: {
          'email': normalizedEmail,
          'password': password,
        },
      );
      developer.log(
        'Login response received',
        name: 'AuthRepository',
        error: {
          'success': response.data['success'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (response.statusCode == 403) {
        final errorCode = response.data['code'] ?? 'account_suspended';
        final errorMessage = response.data['message'] ?? 'Account is suspended';
        final details = response.data['details'];
        final Map<String, dynamic> errorData = {
          'code': errorCode,
          'message': errorMessage,
        };
        if (details != null) {
          errorData['details'] = details;
        }
        throw AuthException(
          errorMessage,
          code: errorCode,
          data: errorData,
        );
      }
      if (response.data['success'] == false) {
        final errorCode = response.data['code'] ?? 'login_failed';
        final errorMessage = response.data['message'] ?? 'Login failed';
        String userMessage;
        switch (errorCode) {
          case 'USER_NOT_FOUND':
            userMessage = 'Aucun compte trouvé avec cet email';
            break;
          case 'INVALID_PASSWORD':
            userMessage = 'Email ou mot de passe incorrect';
            break;
          case 'ACCOUNT_SUSPENDED':
            userMessage = 'Votre compte a été suspendu';
            break;
          default:
            userMessage = errorMessage;
        }
        throw AuthException(userMessage, code: errorCode);
      }
      final data = response.data['data'] ?? response.data;
      if (!data.containsKey('token') || !data.containsKey('user')) {
        throw AuthException('Invalid server response',
            code: 'invalid_response');
      }
      final token = data['token'];
      final profile = UserProfile.fromJson(data['user']);
      await _saveProfile(profile);
      return LoginResponse(
        userProfile: profile,
        token: token,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      if (e.toString().contains('Invalid credentials')) {
        throw AuthException('Email ou mot de passe incorrect',
            code: 'invalid_credentials');
      }
      if (e.toString().contains('User not found')) {
        throw AuthException('Utilisateur non trouvé', code: 'user_not_found');
      }
      if (e.toString().contains('Account suspended')) {
        throw AuthException('Compte suspendu', code: 'account_suspended');
      }
      throw AuthException('Une erreur est survenue lors de la connexion',
          code: 'unknown');
    }
  }
  Future<UserProfile> register({
    required String username,
    required String email,
    required String password,
    required UserType type,
    String? name,
    String? organization,
    String? pressCard,
  }) async {
    if (email.trim().isEmpty) {
      throw AuthException('L\'email est requis', code: 'email_required');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw AuthException('Format d\'email invalide', code: 'invalid_email');
    }
    if (password.length < 8) {
      throw AuthException('Le mot de passe doit contenir au moins 8 caractères',
          code: 'password_too_short');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      throw AuthException(
          'Le mot de passe doit contenir au moins une majuscule',
          code: 'password_no_uppercase');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      throw AuthException(
          'Le mot de passe doit contenir au moins une minuscule',
          code: 'password_no_lowercase');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      throw AuthException('Le mot de passe doit contenir au moins un chiffre',
          code: 'password_no_digit');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      throw AuthException(
          'Le mot de passe doit contenir au moins un caractère spécial',
          code: 'password_no_special');
    }
    if (type == UserType.journalist) {
      if (pressCard != null && pressCard.trim().isNotEmpty) {
        if (!RegExp(r'^\d{4,}$').hasMatch(pressCard)) {
          throw AuthException('Format de carte de presse invalide',
              code: 'invalid_press_card');
        }
      }
      if (organization == null || organization.trim().isEmpty) {
        throw AuthException('L\'organisation est requise',
            code: 'organization_required');
      }
    }
    try {
      final Map<String, dynamic> requestData = {
        'email': email.trim(),
        'password': password,
        'isJournalist': type == UserType.journalist,
      };
      String finalUsername = username.trim();
      if (type == UserType.journalist) {
        requestData['name'] = finalUsername;
        requestData['organization'] = organization!.trim();
        if (pressCard != null && pressCard.isNotEmpty) {
          requestData['pressCard'] = pressCard.trim();
        }
        requestData['journalistRole'] = 'journalist';
      } else {
        if (finalUsername.isEmpty) {
          throw AuthException('Le nom d\'utilisateur est requis',
              code: 'username_required');
        }
        if (finalUsername.length < 3) {
          throw AuthException(
              'Le nom d\'utilisateur doit contenir au moins 3 caractères',
              code: 'username_too_short');
        }
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(finalUsername)) {
          throw AuthException(
              'Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et _',
              code: 'invalid_username');
        }
        requestData['username'] = finalUsername;
      }
      developer.log(
        'Registration data prepared',
        name: 'AuthRepository',
        error: {
          'data': {
            ...requestData,
            'password': '***',
            'pressCard': pressCard,
            'organization': organization,
          },
          'isJournalist': type == UserType.journalist,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final response = await _apiService.post(
        ApiRoutesHelper.register,
        data: requestData,
      );
      developer.log(
        'Registration response received',
        name: 'AuthRepository',
        error: {
          'success': response.data['success'],
          'response': response.data,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final responseData = response.data['data'] ?? response.data;
      final token = responseData['token'];
      final userData = responseData['user'];
      if (token == null || userData == null) {
        developer.log(
          'Invalid response structure',
          name: 'AuthRepository',
          error: {
            'response': response,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        throw AuthException('Structure de réponse invalide',
            code: 'invalid_response_structure');
      }
      await TokenService.saveToken(token, type == UserType.journalist);
      final Map<String, dynamic> enrichedUserData = {
        ...userData,
        'name': username,
        'isJournalist': type == UserType.journalist,
        'stats': {
          'articles': 0,
          'followers': 0,
          'following': 0,
        },
        'verified': false,
        'status': 'active',
        'avatarUrl': userData['avatarUrl'],
      };
      final profile = UserProfile.fromJson(enrichedUserData);
      await _saveProfile(profile);
      developer.log(
        'Registration completed successfully',
        name: 'AuthRepository',
        error: {
          'userId': profile.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return profile;
    } catch (e, stackTrace) {
      developer.log(
        'Registration error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'type': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (e is AuthException) rethrow;
      if (e is ApiException) {
        developer.log(
          'API Exception details',
          name: 'AuthRepository',
          error: {
            'message': e.message,
            'statusCode': e.statusCode,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        if (e.message.isNotEmpty) {
          final message = e.message;
          if (message.contains('Email already registered')) {
            throw AuthException('Cet email est déjà utilisé',
                code: 'email_exists');
          }
          if (message.contains('Username already exists')) {
            throw AuthException('Ce nom d\'utilisateur est déjà utilisé',
                code: 'username_exists');
          }
          throw AuthException(message, code: 'api_error');
        }
      }
      if (e.toString().contains('Email already registered')) {
        throw AuthException('Cet email est déjà utilisé', code: 'email_exists');
      }
      if (e.toString().contains('Username already exists')) {
        throw AuthException('Ce nom d\'utilisateur est déjà utilisé',
            code: 'username_exists');
      }
      throw AuthException(
          'Une erreur est survenue lors de l\'inscription: ${e.toString()}',
          code: 'unknown');
    }
  }
  Future<UserProfile> getProfile() async {
    try {
      final cachedProfile = await getCachedProfile();
      if (cachedProfile != null) {
        developer.log(
          'Using cached profile',
          name: 'AuthRepository',
          error: {
            'userId': cachedProfile.id,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      final response = await _apiService.get(ApiRoutesHelper.profile);
      developer.log(
        'Get profile response received',
        name: 'AuthRepository',
        error: {
          'success': response.data['success'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
            response.data['message'] ?? 'Échec de la récupération du profil',
            code: 'profile_fetch_failed');
      }
      final userData = _extractUserData(response.data, 'Get profile');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      developer.log(
        'Get profile error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (e is AuthException) rethrow;
      throw AuthException('Impossible de récupérer le profil',
          code: 'profile_fetch_error');
    }
  }
  Future<UserProfile> addFormation({
    required String title,
    required String institution,
    required int year,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        ApiRoutesHelper.addFormation,
        data: {
          'title': title.trim(),
          'institution': institution.trim(),
          'year': year,
          if (description != null) 'description': description.trim(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Failed to add formation',
          code: 'formation_add_failed',
        );
      }
      final userData = _extractUserData(response.data, 'Add formation');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to add formation',
        code: 'formation_add_error',
      );
    }
  }
  Future<UserProfile> updateFormation({
    required String formationId,
    String? title,
    String? institution,
    int? year,
    String? description,
  }) async {
    try {
      final response = await _apiService.put(
        ApiRoutesHelper.updateFormation(formationId),
        data: {
          if (title != null) 'title': title.trim(),
          if (institution != null) 'institution': institution.trim(),
          if (year != null) 'year': year,
          if (description != null) 'description': description.trim(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Failed to update formation',
          code: 'formation_update_failed',
        );
      }
      final userData = _extractUserData(response.data, 'Update formation');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to update formation',
        code: 'formation_update_error',
      );
    }
  }
  Future<UserProfile> deleteFormation(String formationId) async {
    try {
      final response = await _apiService.delete(
        ApiRoutesHelper.deleteFormation(formationId),
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Failed to delete formation',
          code: 'formation_delete_failed',
        );
      }
      final userData = _extractUserData(response.data, 'Delete formation');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to delete formation',
        code: 'formation_delete_error',
      );
    }
  }
  Future<UserProfile> addExperience({
    required String title,
    required String company,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    bool current = false,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        ApiRoutesHelper.addExperience,
        data: {
          'title': title.trim(),
          'company': company.trim(),
          if (location != null) 'location': location.trim(),
          'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          'current': current,
          if (description != null) 'description': description.trim(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Failed to add experience',
          code: 'experience_add_failed',
        );
      }
      final userData = _extractUserData(response.data, 'Add experience');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to add experience',
        code: 'experience_add_error',
      );
    }
  }
  Future<UserProfile> updateExperience({
    required String experienceId,
    String? title,
    String? company,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? current,
    String? description,
  }) async {
    try {
      final response = await _apiService.put(
        ApiRoutesHelper.updateExperience(experienceId),
        data: {
          if (title != null) 'title': title.trim(),
          if (company != null) 'company': company.trim(),
          if (location != null) 'location': location.trim(),
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (current != null) 'current': current,
          if (description != null) 'description': description.trim(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Failed to update experience',
          code: 'experience_update_failed',
        );
      }
      final userData = _extractUserData(response.data, 'Update experience');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to update experience',
        code: 'experience_update_error',
      );
    }
  }
  Future<UserProfile> deleteExperience(String experienceId) async {
    try {
      final response = await _apiService.delete(
        ApiRoutesHelper.deleteExperience(experienceId),
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Failed to delete experience',
          code: 'experience_delete_failed',
        );
      }
      final userData = _extractUserData(response.data, 'Delete experience');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to delete experience',
        code: 'experience_delete_error',
      );
    }
  }
  Future<UserProfile> updateProfile({
    String? name,
    String? bio,
    String? location,
    String? avatarUrl,
    String? coverUrl,
    String? organization,
    String? journalistRole,
    Map<String, String>? socialLinks,
    List<Map<String, dynamic>>? formations,
    List<Map<String, dynamic>>? experience,
    List<String>? specialties,
  }) async {
    try {
      if (await TokenService.needsRefresh()) {
        developer.log(
          'Token needs refresh before profile update',
          name: 'AuthRepository',
          error: {
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        await refreshToken();
      }
      final data = {
        if (name != null) 'name': name.trim(),
        if (bio != null) 'bio': bio.trim(),
        if (location != null) 'location': location.trim(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
        if (coverUrl != null) 'coverUrl': coverUrl.trim(),
        if (organization != null) 'organization': organization.trim(),
        if (journalistRole != null) 'journalistRole': journalistRole.trim(),
        if (socialLinks != null) 'socialLinks': socialLinks,
        if (formations != null) 'formations': formations,
        if (experience != null) 'experience': experience,
        if (specialties != null) 'specialties': specialties,
      };
      developer.log(
        'Update profile attempt',
        name: 'AuthRepository',
        error: {
          'data': data,
          'hasToken': await TokenService.getToken() != null,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final response = await _apiService.patch(
        ApiRoutesHelper.updateProfile,
        data: data,
      );
      developer.log(
        'Update profile response received',
        name: 'AuthRepository',
        error: {
          'success': response.data['success'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
            response.data['message'] ?? 'Échec de la mise à jour du profil',
            code: 'profile_update_failed');
      }
      final userData = _extractUserData(response.data, 'Update profile');
      final profile = UserProfile.fromJson(userData);
      await _saveProfile(profile);
      return profile;
    } catch (e) {
      developer.log(
        'Update profile error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (e is AuthException) rethrow;
      if (e is ApiException && e.statusCode == 401) {
        developer.log(
          'Authentication error detected in updateProfile',
          name: 'AuthRepository',
          error: {
            'statusCode': e.statusCode,
            'message': e.message,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        throw AuthException('Session expirée. Veuillez vous reconnecter.',
            code: 'auth_expired');
      }
      throw AuthException('Impossible de mettre à jour le profil',
          code: 'profile_update_error');
    }
  }
  Future<void> _saveProfile(UserProfile profile) async {
    try {
      developer.log(
        'Saving profile to local storage',
        name: 'AuthRepository',
        error: {
          'profileId': profile.id,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final prefs = await SharedPreferences.getInstance();
      final profileJson = profile.toJson();
      await prefs.setString(_userKey, json.encode(profileJson));
      developer.log(
        'Profile saved successfully',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Failed to save profile',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw AuthException('Impossible de sauvegarder le profil localement',
          code: 'local_save_error');
    }
  }
  Future<UserProfile?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userKey);
      if (profileJson != null) {
        return UserProfile.fromJson(json.decode(profileJson));
      }
      return null;
    } catch (e) {
      developer.log(
        'Failed to get cached profile',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return null;
    }
  }
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentPassword.isEmpty) {
        throw AuthException('Le mot de passe actuel est requis',
            code: 'current_password_required');
      }
      if (newPassword.length < 8) {
        throw AuthException(
            'Le nouveau mot de passe doit contenir au moins 8 caractères',
            code: 'password_too_short');
      }
      if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
        throw AuthException(
            'Le nouveau mot de passe doit contenir au moins une majuscule',
            code: 'password_no_uppercase');
      }
      if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
        throw AuthException(
            'Le nouveau mot de passe doit contenir au moins une minuscule',
            code: 'password_no_lowercase');
      }
      if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
        throw AuthException(
            'Le nouveau mot de passe doit contenir au moins un chiffre',
            code: 'password_no_digit');
      }
      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
        throw AuthException(
            'Le nouveau mot de passe doit contenir au moins un caractère spécial',
            code: 'password_no_special');
      }
      developer.log(
        'Attempting to change password',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
      final response = await _apiService.post(
        ApiRoutesHelper.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Échec du changement de mot de passe',
          code: 'password_change_failed',
        );
      }
      developer.log(
        'Password changed successfully',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Change password error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (e is AuthException) rethrow;
      if (e.toString().contains('Invalid current password')) {
        throw AuthException('Mot de passe actuel incorrect',
            code: 'invalid_current_password');
      }
      throw AuthException('Impossible de changer le mot de passe',
          code: 'password_change_error');
    }
  }
  Future<void> logout() async {
    try {
      developer.log(
        'Logout attempt',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
      try {
        await _apiService.post(ApiRoutesHelper.logout);
        developer.log(
          'API logout successful',
          name: 'AuthRepository',
          error: {'timestamp': DateTime.now().toIso8601String()},
        );
      } catch (e) {
        developer.log(
          'API logout failed (continuing with local cleanup)',
          name: 'AuthRepository',
          error: {
            'error': e.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await TokenService.clearToken();
      await clearAllCache();
      await _clearProvidersCache();
      developer.log(
        'Logout successful',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Logout error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      throw AuthException('Impossible de se déconnecter', code: 'logout_error');
    }
  }
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log(
        'Cache cleared successfully',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Failed to clear cache',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }
  Future<void> deleteAccount() async {
    try {
      developer.log(
        'Delete account attempt',
        name: 'AuthRepository',
        error: {
          'hasToken': await TokenService.getToken() != null,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final response = await _apiService.delete(
        ApiRoutesHelper.deleteAccount,
      );
      developer.log(
        'Delete account response received',
        name: 'AuthRepository',
        error: {
          'success': response.data['success'],
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (response.data['success'] == false) {
        throw AuthException(
          response.data['message'] ?? 'Échec de la suppression du compte',
          code: 'account_delete_failed',
        );
      }
      await logout();
      developer.log(
        'Account deleted successfully',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Delete account error',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (e is AuthException) rethrow;
      if (e is ApiException) {
        throw AuthException(
          e.message,
          code: 'account_delete_error',
        );
      }
      throw AuthException(
        'Erreur lors de la suppression du compte',
        code: 'account_delete_error',
      );
    }
  }
  Future<void> _clearProvidersCache() async {
    try {
      developer.log(
        'Clearing providers cache',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
      try {
        ServiceLocator.instance.postsStateProvider.clearCache();
        developer.log('PostsStateProvider cache cleared',
            name: 'AuthRepository');
      } catch (e) {
        developer.log('Failed to clear PostsStateProvider cache: $e',
            name: 'AuthRepository');
      }
      try {
        developer.log('UserService cache cleared', name: 'AuthRepository');
      } catch (e) {
        developer.log('Failed to clear UserService cache: $e',
            name: 'AuthRepository');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_posts');
        await prefs.remove('last_sync');
        developer.log('Offline cache cleared', name: 'AuthRepository');
      } catch (e) {
        developer.log('Failed to clear offline cache: $e',
            name: 'AuthRepository');
      }
      developer.log(
        'Providers cache cleared successfully',
        name: 'AuthRepository',
        error: {'timestamp': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      developer.log(
        'Error clearing providers cache',
        name: 'AuthRepository',
        error: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }
  UserProfile? get currentUser {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }
  bool get isAuthenticatedSync {
    return false;
  }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response =
        await loginWithCredentials(email: email, password: password);
    return {
      'token': response.token,
      'user': {
        'id': response.userProfile.id,
        'username': response.userProfile.username,
        'email': response.userProfile.email,
      }
    };
  }
}