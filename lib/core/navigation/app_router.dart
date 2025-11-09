import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/media/domain/config/media_config.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/welcome_screen.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/login_screen.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/mode_selection_screen.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/registration_form.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/registration_stepper.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/verification_pending_screen.dart';
import 'package:thot/features/authentication/presentation/mobile/screens/banned_account_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/main_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/feed_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/post_detail_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/article_detail_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/video_detail_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/podcast_detail_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/poll_detail_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/question_detail_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/shorts_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/shorts_feed_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_article_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_video_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_podcast_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_live_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_short_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_publication_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_question_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/question_type_selection_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/question_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/journalist_question.dart';
import 'package:thot/features/posts/presentation/mobile/screens/saved_content_screen.dart';
import 'package:thot/features/profile/presentation/mobile/screens/profile_screen.dart';
import 'package:thot/features/profile/presentation/mobile/screens/user_profile_screen.dart';
import 'package:thot/features/profile/presentation/mobile/screens/edit_profile_screen.dart';
import 'package:thot/features/profile/presentation/mobile/screens/followers_screen.dart';
import 'package:thot/features/profile/presentation/mobile/screens/following_screen.dart';
import 'package:thot/features/search/presentation/mobile/screens/search_screen.dart';
import 'package:thot/features/search/presentation/mobile/screens/explore_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/settings_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/subscriptions_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/change_password_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/notification_preferences_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/report_problem_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/about_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/privacy_policy_screen.dart';
import 'package:thot/features/settings/presentation/mobile/screens/terms_screen.dart';
import 'package:thot/features/admin/presentation/mobile/screens/admin_main_screen.dart';
import 'package:thot/features/admin/presentation/mobile/screens/admin_dashboard_screen.dart';
import 'package:thot/features/admin/presentation/mobile/screens/admin_users_screen.dart';
import 'package:thot/features/admin/presentation/mobile/screens/admin_reports_screen.dart';
import 'package:thot/features/admin/presentation/mobile/screens/report_details_screen.dart';
import 'package:thot/features/admin/presentation/mobile/screens/admin_journalists_screen.dart';
import 'package:thot/features/notifications/presentation/mobile/screens/notifications_screen.dart';
import 'package:thot/features/messaging/presentation/mobile/screens/messages_screen.dart';
import 'package:thot/features/analytics/presentation/mobile/screens/analytics_screen.dart';
import 'package:thot/features/analytics/presentation/mobile/screens/stats_screen.dart';
import 'package:thot/features/media/presentation/mobile/screens/image_crop_screen.dart';
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
        'Redirecting to /welcome - user not authenticated (location: $location)'
      );
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
      ..._infoPageRoutes(),
      ..._adminRoutes(),
      ..._analyticsRoutes(),
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
        builder: (context, state) => const RegistrationForm(isJournalist: false),
      ),
      GoRoute(
        path: RouteNames.modeSelection,
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.registrationForm,
        builder: (context, state) => const RegistrationForm(isJournalist: false),
      ),
      GoRoute(
        path: RouteNames.registrationStepper,
        builder: (context, state) {
          final isJournalist = state.uri.queryParameters['isJournalist'] == 'true';
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
          builder: (context, state) => QuestionScreen(
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
        GoRoute(
          path: RouteNames.messages,
          builder: (context, state) {
            final recipient = state.extra as UserProfile?;
            return MessagesScreen(
              recipient: recipient ??
                  const UserProfile(
                    id: '',
                    username: '',
                    email: '',
                    type: UserType.regular,
                    isVerified: false,
                    postsCount: 0,
                    followersCount: 0,
                    followingCount: 0,
                    highlightedStories: [],
                    isPrivate: false,
                    isFollowing: false,
                    isBlocked: false,
                    notificationCount: 0,
                  ),
            );
          },
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
          final id = extra?['postId'] as String? ?? '';
          return PostDetailScreen(initialPostId: id);
        },
      ),
      GoRoute(
        path: RouteNames.articleDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          return ArticleDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: RouteNames.videoDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          return VideoDetailScreen(initialPostId: id);
        },
      ),
      GoRoute(
        path: RouteNames.podcastDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          return PodcastDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: RouteNames.pollDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['postId'] as String? ?? '';
          return PollDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: RouteNames.questionDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final id = extra?['questionId'] as String? ?? '';
          return QuestionDetailScreen(questionId: id);
        },
      ),
    ];
  }
  static List<GoRoute> _contentCreationRoutes() {
    return [
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
      GoRoute(
        path: RouteNames.newLive,
        builder: (context, state) => const NewLiveScreen(
          journalistId: '',
        ),
      ),
      GoRoute(
        path: RouteNames.newShort,
        builder: (context, state) => const NewShortScreen(
          journalistId: '',
        ),
      ),
      GoRoute(
        path: RouteNames.newPublication,
        builder: (context, state) => const NewPublicationScreen(
          journalistId: '',
        ),
      ),
      GoRoute(
        path: RouteNames.newQuestion,
        builder: (context, state) => const NewQuestionScreen(
          journalistId: '',
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
  static List<GoRoute> _analyticsRoutes() {
    return [
      GoRoute(
        path: RouteNames.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.stats,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final journalistId = extra?['journalistId'] as String? ?? '';
          return StatsScreen(
            journalistId: journalistId,
          );
        },
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