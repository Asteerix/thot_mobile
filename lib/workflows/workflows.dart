/// ⚠️ MODULE CONTENANT DU CODE MORT
///
/// Export centralisé des workflows d'orchestration cross-feature
///
/// ❌ ÉTAT ACTUEL : Ces workflows ne sont JAMAIS utilisés dans la codebase
///
/// Les workflows ci-dessous étaient prévus pour orchestrer des opérations
/// multi-features, mais la logique est déjà gérée directement par les
/// repositories et services existants.
///
/// Workflows déclarés (CODE MORT) :
/// - ReportWorkflow : Jamais instancié → Utiliser AdminRepository directement
/// - SaveContentWorkflow : Jamais instancié → Utiliser MediaSaveService directement
///
/// Voir aussi : WorkflowLocator (core/infrastructure/services/workflow_locator.dart)
/// qui documente pourquoi ces workflows sont obsolètes.
///
/// ❌ RECOMMANDATION : Supprimer tout ce module /workflows/
///
/// Utiliser directement :
/// - AdminRepository : ServiceLocator.instance.adminRepository
/// - MediaSaveService : ServiceLocator.instance.mediaSaveService
library;

// Cross-feature workflows (CODE MORT - jamais instanciés)
export 'report_workflow.dart';
export 'save_content_workflow.dart';
