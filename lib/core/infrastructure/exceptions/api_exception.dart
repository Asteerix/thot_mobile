import 'package:dio/dio.dart';
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  factory ApiException.fromDioError(DioException error) {
    String message;
    final statusCode = error.response?.statusCode;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'La connexion est trop lente. Réessayez dans un moment.';
        break;
      case DioExceptionType.badResponse:
        final serverMessage = error.response?.data is Map
            ? error.response?.data['message']
            : null;
        if (serverMessage != null && serverMessage is String) {
          message = serverMessage;
        } else {
          message = _getStatusCodeMessage(statusCode);
        }
        break;
      case DioExceptionType.cancel:
        message = 'Opération annulée';
        break;
      case DioExceptionType.connectionError:
        message = 'Problème de connexion. Vérifiez votre connexion internet.';
        break;
      case DioExceptionType.unknown:
        if (error.error != null &&
            error.error.toString().contains('SocketException')) {
          message = 'Pas de connexion internet';
        } else {
          message = 'Erreur réseau. Vérifiez votre connexion.';
        }
        break;
      default:
        message = 'Une erreur est survenue';
    }
    return ApiException(message, statusCode: statusCode);
  }
  static String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Données invalides';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé';
      case 404:
        return 'Contenu introuvable';
      case 429:
        return 'Trop de requêtes. Veuillez patienter.';
      case 500:
      case 503:
        return 'Erreur serveur. Nous travaillons à résoudre le problème.';
      default:
        return 'Une erreur est survenue';
    }
  }
  @override
  String toString() => message;
}