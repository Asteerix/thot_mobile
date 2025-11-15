import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/features/public/auth/login/screens/welcome_screen.dart';
import 'package:thot/features/public/auth/login/screens/login_screen.dart';
import 'package:thot/features/public/auth/register/screens/mode_selection_screen.dart';
import 'package:thot/features/public/auth/register/screens/registration_form.dart';
import 'package:thot/features/public/auth/register/screens/registration_stepper.dart';
import 'package:thot/features/public/auth/register/screens/verification_pending_screen.dart';
import 'package:thot/features/public/auth/shared/screens/banned_account_screen.dart';
import 'package:thot/features/app/feed/shared/main_screen.dart';
import 'package:thot/features/app/feed/home/screens/feed_screen.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/screens/post_detail_wrapper.dart';
import 'package:thot/features/app/content/shared/screens/content_viewer.dart';
import 'package:thot/features/app/content/posts/articles/screens/article_detail_screen.dart';
import 'package:thot/features/app/content/posts/videos/screens/video_detail_screen.dart';
import 'package:thot/features/app/content/posts/podcasts/screens/podcast_detail_screen.dart';
import 'package:thot/features/app/content/posts/questions/screens/question_detail_screen.dart';
import 'package:thot/features/app/content/posts/questions/details/question_screen.dart' as old_question;
import 'package:thot/features/app/content/shorts/details/shorts_screen.dart';
import 'package:thot/features/app/content/shorts/feed/shorts_feed_screen.dart';
import 'package:thot/features/app/content/posts/articles/creation/new_article_screen.dart';
import 'package:thot/features/app/content/posts/videos/creation/new_video_screen.dart';
import 'package:thot/features/app/content/posts/podcasts/creation/new_podcast_screen.dart';
// import 'package:thot/features/app/content/shared/widgets/new_live_screen.dart';
import 'package:thot/features/app/content/shorts/creation/new_short_screen.dart';
import 'package:thot/features/app/content/shared/widgets/new_publication_screen.dart';
import 'package:thot/features/app/content/posts/questions/creation/new_question_screen.dart';
import 'package:thot/features/app/content/posts/questions/types/question_type_selection_screen.dart';
import 'package:thot/features/app/content/posts/questions/details/question_screen.dart';
import 'package:thot/features/app/content/posts/questions/creation/journalist_question.dart';
import 'package:thot/features/app/feed/shared/saved_content_screen.dart';
import 'package:thot/features/app/profile/screens/profile_screen.dart';
import 'package:thot/features/app/profile/screens/user_profile_screen.dart';
import 'package:thot/features/app/profile/screens/edit_profile_screen.dart';
import 'package:thot/features/app/profile/screens/followers_screen.dart';
import 'package:thot/features/app/profile/screens/following_screen.dart';
import 'package:thot/features/app/search/screens/search_screen.dart';
import 'package:thot/features/app/search/screens/explore_screen.dart';
import 'package:thot/features/app/settings/screens/settings_screen.dart';
import 'package:thot/features/app/settings/screens/subscriptions_screen.dart';
import 'package:thot/features/app/settings/screens/change_password_screen.dart';
import 'package:thot/features/app/settings/screens/notification_preferences_screen.dart';
import 'package:thot/features/app/settings/screens/report_problem_screen.dart';
import 'package:thot/features/public/legal/screens/about_screen.dart';
import 'package:thot/features/public/legal/screens/privacy_policy_screen.dart';
import 'package:thot/features/public/legal/screens/terms_screen.dart';
import 'package:thot/features/admin/screens/admin_main_screen.dart';
import 'package:thot/features/admin/screens/admin_dashboard_screen.dart';
import 'package:thot/features/admin/screens/admin_users_screen.dart';
import 'package:thot/features/admin/screens/admin_reports_screen.dart';
import 'package:thot/features/admin/screens/report_details_screen.dart';
import 'package:thot/features/admin/screens/admin_journalists_screen.dart';
import 'package:thot/features/app/notifications/screens/notifications_screen.dart';
import 'package:thot/shared/media/screens/image_crop_screen.dart';
import 'package:thot/features/app/analytics/presentation/mobile/screens/stats_screen.dart';

class AppRouter {
  static void replaceAllTo(BuildContext context, String route) {
    context.go(route);
  }

  static void navigateTo(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    if (arguments != null) {
      context.pushNamed(route, extra: arguments);
    } else {
      context.push(route);
    }
  }

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RouteNames.home,
      redirect: (context, state) => _handleRedirect(
        authProvider: authProvider,
        location: state.matchedLocation,
      ),
      routes: _buildRoutes(),
    );
  }

  static String? _handleRedirect({
    required AuthProvider authProvider,
    required String location,
  }) {
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoading = authProvider.isLoading;
    if (isLoading) return null;
    const authPages = {
      RouteNames.welcome,
      RouteNames.login,
      RouteNames.register,
      RouteNames.modeSelection,
      RouteNames.registrationForm,
      RouteNames.registrationStepper,
      RouteNames.verificationPending,
      RouteNames.bannedAccount,
      RouteNames.terms,
      RouteNames.termsOfService,
      RouteNames.privacyPolicy,
    };
    const adminPages = {
      RouteNames.admin,
      RouteNames.adminDashboard,
      RouteNames.adminUsers,
      RouteNames.adminReports,
      RouteNames.adminReportDetails,
      RouteNames.adminJournalists,
    };
    if (!isLoggedIn && !authPages.contains(location)) {
      LoggerService.instance.info(
          'Redirecting to /welcome - user not authenticated (location: $location)');
      return RouteNames.welcome;
    }
    if (isLoggedIn && authPages.contains(location)) {
      return RouteNames.feed;
    }
    if (adminPages.contains(location)) {
      if (!isLoggedIn) return RouteNames.welcome;
      if (!authProvider.isAdmin) return RouteNames.feed;
    }
    return null;
  }

  static List<RouteBase> _buildRoutes() {
    return [
      ..._authenticationRoutes(),
      _mainShellRoute(),
      ..._postDetailRoutes(),
      ..._contentCreationRoutes(),
      ..._profileRoutes(),
      ..._settingsRoutes(),
      ..._analyticsRoutes(),
      ..._infoPageRoutes(),
      ..._adminRoutes(),
      ..._mediaRoutes(),
    ];
  }

  static List<GoRoute> _authenticationRoutes() {
    return [
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) =>
            const RegistrationForm(isJournalist: false),
      ),
      GoRoute(
        path: RouteNames.modeSelection,
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.registrationForm,
        builder: (context, state) =>
            const RegistrationForm(isJournalist: false),
      ),
      GoRoute(
        path: RouteNames.registrationStepper,
        builder: (context, state) {
          final isJournalist =
              state.uri.queryParameters['isJournalist'] == 'true';
          return RegistrationStepper(isJournalist: isJournalist);
        },
      ),
      GoRoute(
        path: RouteNames.verificationPending,
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      GoRoute(
        path: RouteNames.bannedAccount,
        builder: (context, state) => const BannedAccountScreen(),
      ),
    ];
  }

  static ShellRoute _mainShellRoute() {
    return ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: RouteNames.home,
          redirect: (context, state) => RouteNames.feed,
        ),
        GoRoute(
          path: RouteNames.feed,
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: RouteNames.subscriptions,
          builder: (context, state) => const SubscriptionsScreen(),
        ),
        GoRoute(
          path: RouteNames.explore,
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: RouteNames.search,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: RouteNames.short,
          builder: (context, state) => const ShortsScreen(),
        ),
        GoRoute(
          path: RouteNames.shortsFeed,
          builder: (context, state) => const ShortsFeedScreen(),
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] as String?;
            final isCurrentUser = userId == null
                ? true
                : (extra?['isCurrentUser'] as bool? ?? false);
            final forceReload = extra?['forceReload'] as bool? ?? false;
            return ProfileScreen(
              userId: userId,
              isCurrentUser: isCurrentUser,
              forceReload: forceReload,
            );
          },
        ),
        GoRoute(
          path: RouteNames.questions,
          builder: (context, state) => old_question.QuestionScreen(
            questionId: '',
            journalistId: '',
          ),
        ),
        GoRoute(
          path: RouteNames.journalistQuestion,
          builder: (context, state) => const JournalistQuestion(),
        ),
        GoRoute(
          path: RouteNames.savedContent,
          builder: (context, state) => const SavedContentScreen(),
        ),
        GoRoute(
          path: RouteNames.notifications,
          name: RouteNames.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }

  static List<GoRoute> _postDetailRoutes() {
    return [
      GoRoute(
        path: RouteNames.postDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final pathId = state.pathParameters['id'] ?? '';
          final extraId = extra?['postId'] as String? ?? '';
          final id = pathId.isNotEmpty ? pathId : extraId;
          debugPrint(
              '🛣️ APP_ROUTER - Post Detail Route | pathId: $pathId | extraId: $extraId | finalId: $id');
          return PostDetailWrapper(initialPostId: id);
        },
      ),
      GoRoute(
        path: RouteNames.articleDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          final userId = extra?['userId'] as String?;
          final isFromProfile = extra?['isFromProfile'] as bool? ?? false;
          return ContentViewer(
            initialPostId: id,
            filterType: PostType.article,
            userId: userId,
            isFromProfile: isFromProfile,
          );
        },
      ),
      GoRoute(
        path: RouteNames.videoDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          final userId = extra?['userId'] as String?;
          final isFromProfile = extra?['isFromProfile'] as bool? ?? false;
          debugPrint('🛣️ APP_ROUTER - Video Detail Route | postId: $id');
          return ContentViewer(
            initialPostId: id,
            filterType: PostType.video,
            userId: userId,
            isFromProfile: isFromProfile,
          );
        },
      ),
      GoRoute(
        path: RouteNames.podcastDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          final userId = extra?['userId'] as String?;
          final isFromProfile = extra?['isFromProfile'] as bool? ?? false;
          return ContentViewer(
            initialPostId: id,
            filterType: PostType.podcast,
            userId: userId,
            isFromProfile: isFromProfile,
          );
        },
      ),
      GoRoute(
        path: RouteNames.questionDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['questionId'] as String? ?? '';
          final userId = extra?['userId'] as String?;
          final isFromProfile = extra?['isFromProfile'] as bool? ?? false;
          return ContentViewer(
            initialPostId: id,
            filterType: PostType.question,
            userId: userId,
            isFromProfile: isFromProfile,
          );
        },
      ),
    ];
  }

  static List<GoRoute> _contentCreationRoutes() {
    return [
      GoRoute(
        path: '/new-content/:formatId/:domain/:journalistId',
        builder: (context, state) {
          final formatId = state.pathParameters['formatId'] ?? '';
          final domain = state.pathParameters['domain'] ?? 'default';
          final journalistId = state.pathParameters['journalistId'] ?? '';

          switch (formatId) {
            case 'article':
              return NewArticleScreen(
                domain: domain,
                journalistId: journalistId,
              );
            case 'video':
              return NewVideoScreen(
                domain: domain,
                journalistId: journalistId,
              );
            case 'podcast':
              return NewPodcastScreen(
                domain: domain,
                journalistId: journalistId,
              );
            case 'short':
              return NewShortScreen(
                journalistId: journalistId,
                domain: domain,
              );
            case 'question':
              return NewQuestionScreen(
                journalistId: journalistId,
                domain: domain,
              );
            default:
              return NewArticleScreen(
                domain: domain,
                journalistId: journalistId,
              );
          }
        },
      ),
      GoRoute(
        path: RouteNames.createPost,
        builder: (context, state) => const NewArticleScreen(
          domain: 'default',
          journalistId: '',
        ),
      ),
      GoRoute(
        path: RouteNames.newArticle,
        builder: (context, state) => const NewArticleScreen(
          domain: 'default',
          journalistId: '',
        ),
      ),
      GoRoute(
        path: RouteNames.newVideo,
        builder: (context, state) => const NewVideoScreen(
          domain: 'default',
          journalistId: '',
        ),
      ),
      GoRoute(
        path: RouteNames.newPodcast,
        builder: (context, state) => const NewPodcastScreen(
          domain: 'default',
          journalistId: '',
        ),
      ),
      // GoRoute(
      //   path: RouteNames.newLive,
      //   builder: (context, state) => const NewLiveScreen(
      //     journalistId: '',
      //   ),
      // ),
      GoRoute(
        path: RouteNames.newShort,
        builder: (context, state) => const NewShortScreen(
          journalistId: '',
        ),
      ),
      // GoRoute(
      //   path: RouteNames.newPublication,
      //   builder: (context, state) => const NewPublicationScreen(
      //     journalistId: '',
      //   ),
      // ),
      GoRoute(
        path: RouteNames.newQuestion,
        builder: (context, state) => const NewQuestionScreen(
          journalistId: '',
          domain: 'societe',
        ),
      ),
      GoRoute(
        path: RouteNames.questionTypeSelection,
        builder: (context, state) => const QuestionTypeSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.editPost,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return NewArticleScreen(
            domain: 'default',
            journalistId: '',
            postId: id,
            isEditing: true,
          );
        },
      ),
    ];
  }

  static List<GoRoute> _profileRoutes() {
    return [
      GoRoute(
        path: RouteNames.userProfile,
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return const Scaffold(
            body: Center(
              child: Text('User Profile Screen - TODO: Implement user loading'),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) {
          final userProfile = state.extra as UserProfile?;
          if (userProfile == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: User profile not provided'),
              ),
            );
          }
          return EditProfileScreen(userProfile: userProfile);
        },
      ),
      GoRoute(
        path: RouteNames.followers,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FollowersScreen(userId: userId);
        },
      ),
      GoRoute(
        path: RouteNames.following,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return FollowingScreen(userId: userId);
        },
      ),
    ];
  }

  static List<GoRoute> _settingsRoutes() {
    return [
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.notificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: RouteNames.reportProblem,
        builder: (context, state) => const ReportProblemScreen(),
      ),
    ];
  }

  static List<GoRoute> _analyticsRoutes() {
    return [
      GoRoute(
        path: RouteNames.stats,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final journalistId = extra?['journalistId'] as String? ?? '';
          return StatsScreen(
            journalistId: journalistId,
            isCurrentUser: true,
          );
        },
      ),
    ];
  }

  static List<GoRoute> _infoPageRoutes() {
    return [
      GoRoute(
        path: RouteNames.about,
        builder: (context, state) => AboutScreen(),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: RouteNames.termsOfService,
        name: 'terms-of-service',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: RouteNames.terms,
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
    ];
  }

  static List<GoRoute> _adminRoutes() {
    return [
      GoRoute(
        path: RouteNames.admin,
        builder: (context, state) => const AdminMainScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: RouteNames.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminReportDetails,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportDetailsScreen(
            targetType: 'report',
            targetId: id,
          );
        },
      ),
      GoRoute(
        path: RouteNames.adminJournalists,
        builder: (context, state) => const AdminJournalistsScreen(),
      ),
    ];
  }

  static List<GoRoute> _mediaRoutes() {
    return [
      GoRoute(
        path: RouteNames.imageCrop,
        builder: (context, state) => ImageCropScreen(
          imageBytes: state.extra as Uint8List? ?? Uint8List(0),
          type: MediaType.article,
        ),
      ),
    ];
  }
}
