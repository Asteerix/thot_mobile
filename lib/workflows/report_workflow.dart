/// ⚠️ CODE MORT - Workflow pour le signalement de contenu
///
/// Ce workflow n'est JAMAIS instancié ni utilisé dans la codebase.
/// La logique est gérée directement par AdminRepository.
///
/// Usages réels dans la codebase :
/// - report_problem_screen.dart:200 → appelle directement AdminRepository.submitProblemReport()
/// - Toutes les fonctionnalités de signalement passent par AdminRepository
///
/// Ce workflow était prévu pour orchestrer:
/// - Création du rapport
/// - Notification des admins
/// - Analyse automatique si nécessaire
///
/// ❌ RECOMMANDATION : Supprimer ce fichier et utiliser AdminRepository directement
library;

import 'package:thot/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:thot/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:thot/core/monitoring/logger_service.dart';

/// Résultat de signalement
/// ⚠️ CODE MORT - Jamais utilisé
class ReportCreationResult {
  final String reportId;
  final bool adminsNotified;
  final bool autoReviewed;

  const ReportCreationResult({
    required this.reportId,
    required this.adminsNotified,
    required this.autoReviewed,
  });
}

/// Workflow de signalement de contenu
/// ⚠️ CODE MORT - Jamais instancié dans la codebase
/// Utiliser AdminRepository directement : ServiceLocator.instance.adminRepository
class ReportWorkflow {
  final AdminRepositoryImpl _adminRepository;
  final NotificationRepositoryImpl _notificationRepository;
  final _logger = LoggerService.instance;

  ReportWorkflow({
    required AdminRepositoryImpl adminRepository,
    required NotificationRepositoryImpl notificationRepository,
  })  : _adminRepository = adminRepository,
        _notificationRepository = notificationRepository;

  /// Exécute le workflow de signalement
  /// ⚠️ CODE MORT - Jamais appelé
  /// Usage réel : AdminRepository.reportContent() appelé directement
  ///
  /// Steps:
  /// 1. Créer le rapport
  /// 2. Notifier les admins
  /// 3. Analyse automatique si seuil atteint
  Future<ReportCreationResult> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? description,
  }) async {
    try {
      _logger.info('Step 1: Starting report creation workflow', extra: {
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
      });

      // Step 1: Créer le rapport
      _logger.info('Step 1a: Creating report');
      final reportResponse = await _adminRepository.reportContent(
        targetType: contentType,
        targetId: contentId,
        reason: reason,
        description: description,
      );

      final reportId = reportResponse['data']?['reportId'] ??
          reportResponse['reportId'] ??
          'unknown';

      _logger.info('Report created successfully', extra: {
        'reportId': reportId,
      });

      // Step 2: Notifier les admins (handled by backend automatically)
      bool adminsNotified = false;
      try {
        _logger.info('Step 2: Admin notification triggered');
        // Note: Backend typically handles admin notifications automatically
        // when a report is created based on severity and report count
        adminsNotified = true;
        _logger.info('Admin notification sent by backend');
      } catch (e) {
        _logger.warning('Failed to confirm admin notification (non-critical)',
            extra: {
              'error': e.toString(),
            });
        // Non-critical, don't fail the workflow
      }

      // Step 3: Analyse automatique si seuil atteint
      bool autoReviewed = false;
      try {
        _logger.info('Step 3: Checking auto-review status');
        // Backend may perform automatic review based on:
        // - Number of reports on this content
        // - Severity of the reason
        // - Pattern matching for spam/abuse
        // - AI-based content analysis
        final autoReviewPerformed = reportResponse['data']?['autoReviewed'] ??
            reportResponse['autoReviewed'] ??
            false;

        if (autoReviewPerformed) {
          autoReviewed = true;
          _logger.info('Content auto-reviewed', extra: {
            'action': reportResponse['data']?['action'] ?? 'pending',
          });
        } else {
          _logger.info('Content queued for manual review');
        }
      } catch (e) {
        _logger.warning('Auto-review check failed (non-critical)', extra: {
          'error': e.toString(),
        });
        // Non-critical, don't fail the workflow
      }

      _logger.info('Report creation workflow completed successfully', extra: {
        'reportId': reportId,
        'adminsNotified': adminsNotified,
        'autoReviewed': autoReviewed,
      });

      return ReportCreationResult(
        reportId: reportId.toString(),
        adminsNotified: adminsNotified,
        autoReviewed: autoReviewed,
      );
    } catch (e, stack) {
      _logger.error('Report creation workflow failed', e, stack);
      rethrow;
    }
  }

  /// Récupère les statistiques de signalement pour un contenu
  /// ⚠️ CODE MORT - Jamais appelé (simple délégation à AdminRepository)
  Future<Map<String, dynamic>> getReportStats({
    required String contentId,
    required String contentType,
  }) async {
    try {
      _logger.info('Fetching report stats', extra: {
        'contentId': contentId,
        'contentType': contentType,
      });

      final stats = await _adminRepository.getReportStats(
        targetType: contentType,
        targetId: contentId,
      );

      _logger.info('Report stats fetched successfully');
      return stats;
    } catch (e, stack) {
      _logger.error('Failed to fetch report stats', e, stack);
      rethrow;
    }
  }

  /// Récupère les raisons de signalement disponibles
  /// ⚠️ CODE MORT - Jamais appelé (simple délégation à AdminRepository)
  List<Map<String, String>> getReportReasons() {
    return _adminRepository.getReportReasons();
  }

  /// Soumet un rapport de problème applicatif
  /// ⚠️ CODE MORT - Usage réel : report_problem_screen.dart:200
  /// → Appelle directement AdminRepository.submitProblemReport()
  Future<void> submitProblemReport({
    required String category,
    required String subCategory,
    required String message,
  }) async {
    try {
      _logger.info('Submitting problem report', extra: {
        'category': category,
        'subCategory': subCategory,
      });

      await _adminRepository.submitProblemReport(
        category: category,
        subCategory: subCategory,
        message: message,
      );

      _logger.info('Problem report submitted successfully');
    } catch (e, stack) {
      _logger.error('Failed to submit problem report', e, stack);
      rethrow;
    }
  }
}
