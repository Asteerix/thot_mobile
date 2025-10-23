import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thot/core/themes/app_colors.dart';
class ReportHelpers {
  ReportHelpers._();
  static Color getReasonColor(BuildContext context, String reason) {
    switch (reason) {
      case 'spam':
        return AppColors.purple;
      case 'harassment':
        return AppColors.red;
      case 'hate_speech':
        return AppColors.red;
      case 'violence':
        return Colors.deepOrange;
      case 'false_information':
        return AppColors.orange;
      case 'inappropriate_content':
        return AppColors.warning;
      case 'copyright':
        return AppColors.blue;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
  static Color getStatusColor(BuildContext context, String? status) {
    switch (status) {
      case 'pending':
        return AppColors.orange;
      case 'reviewed':
        return AppColors.blue;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return Theme.of(context).colorScheme.outline;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
  static String getReasonLabel(String reason) {
    switch (reason) {
      case 'spam':
        return 'Spam';
      case 'harassment':
        return 'Harcèlement';
      case 'hate_speech':
        return 'Discours de haine';
      case 'violence':
        return 'Violence';
      case 'false_information':
        return 'Fausse information';
      case 'inappropriate_content':
        return 'Contenu inapproprié';
      case 'copyright':
        return 'Violation du droit d\'auteur';
      case 'other':
        return 'Autre';
      default:
        return reason;
    }
  }
  static String getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'reviewed':
        return 'Vu';
      case 'resolved':
        return 'Résolu';
      case 'dismissed':
        return 'Ignoré';
      default:
        return status ?? 'Inconnu';
    }
  }
}
class PostHelpers {
  PostHelpers._();
  static Color getPostTypeColor(BuildContext context, String? type) {
    switch (type) {
      case 'article':
        return AppColors.blue;
      case 'video':
        return AppColors.red;
      case 'podcast':
        return AppColors.purple;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
  static IconData getPostTypeIcon(String? type) {
    switch (type) {
      case 'article':
        return Icons.article;
      case 'video':
        return Icons.videocam;
      case 'podcast':
        return Icons.mic;
      default:
        return Icons.post_add;
    }
  }
}
class UserRoleHelpers {
  UserRoleHelpers._();
  static Color getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.purple;
      case 'journalist':
        return AppColors.blue;
      case 'reader':
      default:
        return AppColors.neutralGrey;
    }
  }
  static String getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'journalist':
        return 'Journaliste';
      case 'reader':
      default:
        return 'Lecteur';
    }
  }
}
class DateHelpers {
  DateHelpers._();
  static String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  static String formatDateOnly(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  static String formatRelative(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 365) {
        return 'il y a ${(diff.inDays / 365).floor()} an${(diff.inDays / 365).floor() > 1 ? 's' : ''}';
      } else if (diff.inDays > 30) {
        return 'il y a ${(diff.inDays / 30).floor()} mois';
      } else if (diff.inDays > 0) {
        return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        return 'il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
      } else if (diff.inMinutes > 0) {
        return 'il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'à l\'instant';
      }
    } catch (e) {
      return dateStr;
    }
  }
}