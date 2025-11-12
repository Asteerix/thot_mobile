class ApiRoutes {
  ApiRoutes._();
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleAuth = '/api/auth/google';
  static const String logout = '/api/auth/logout';
  static const String changePassword = '/api/auth/change-password';
  static const String authProfile = '/api/auth/profile';
  static const String subscriptionPosts = '/api/subscriptions/posts';
  static const String subscriptionJournalists =
      '/api/subscriptions/journalists';
  static const String userSavedPosts = '/api/users/saved-posts';
  static const String userSavedShorts = '/api/users/saved-shorts';
  static const String posts = '/api/posts';
  static String getPost(String id) => '/api/posts/$id';
  static String updatePost(String id) => '/api/posts/$id';
  static String deletePost(String id) => '/api/posts/$id';
  static String likePost(String id) => '/api/posts/$id/like';
  static String dislikePost(String id) => '/api/posts/$id/dislike';
  static String savePost(String id) => '/api/posts/$id/save';
  static String unsavePost(String id) => '/api/posts/$id/unsave';
  static String createOpposition(String id) => '/api/posts/$id/oppositions';
  static String deleteOpposition(String id, String oppId) =>
      '/api/posts/$id/oppositions/$oppId';
  static String getPostOppositions(String id) => '/api/posts/$id/oppositions';
  static String oppositionVote(String id) => '/api/posts/$id/opposition-vote';
  static String politicalViewPost(String id) => '/api/posts/$id/political-view';
  static String getPoliticalVoters(String id) =>
      '/api/posts/$id/political-voters';
  static String getInteractionsByType(String id, String type) =>
      '/api/posts/$id/interactions/$type';
  static const String questions = '/api/questions';
  static String getQuestion(String id) => '/api/questions/$id';
  static String updateQuestion(String id) => '/api/questions/$id';
  static String deleteQuestion(String id) => '/api/questions/$id';
  static String voteQuestion(String id) => '/api/questions/$id/vote';
  static String hasVotedQuestion(String id) => '/api/questions/$id/has-voted';
  static String getQuestionResults(String id) => '/api/questions/$id/results';
  static String likeQuestion(String id) => '/api/questions/$id/like';
  static String dislikeQuestion(String id) => '/api/questions/$id/dislike';
  static String saveQuestion(String id) => '/api/questions/$id/save';
  static const String shorts = '/api/shorts';
  static String getShort(String id) => '/api/shorts/$id';
  static String updateShort(String id) => '/api/shorts/$id';
  static String deleteShort(String id) => '/api/shorts/$id';
  static String likeShort(String id) => '/api/shorts/$id/like';
  static String dislikeShort(String id) => '/api/shorts/$id/dislike';
  static String saveShort(String id) => '/api/shorts/$id/save';
  static String getShortComments(String id) => '/api/shorts/$id/comments';
  static String viewShort(String id) => '/api/shorts/$id/view';
  static String getShortAnalytics(String id) => '/api/shorts/$id/analytics';
  static String getPostComments(String postId) => '/api/comments/post/$postId';
  static String createComment(String postId) => '/api/comments/post/$postId';
  static String updateComment(String id) => '/api/comments/$id';
  static String deleteComment(String id) => '/api/comments/$id';
  static String likeComment(String id) => '/api/comments/$id/like';
  static String getCommentLikes(String id) => '/api/comments/$id/likes';
  static const String journalists = '/api/journalists';
  static String journalistFollowers(String id) =>
      '/api/journalists/$id/followers';
  static String journalistFollowing(String id) =>
      '/api/journalists/$id/following';
  static String removeJournalistFollower(String id, String followerId) =>
      '/api/journalists/$id/followers/$followerId';
  static String followStatus(String id) => '/api/journalists/$id/follow/status';
  static String answerJournalistQuestion(String id, String questionId) =>
      '/api/journalists/$id/questions/$questionId/answer';
  static String getUserProfile(String id) => '/api/users/$id';
  static String followUser(String journalistId) =>
      '/api/users/follow/$journalistId';
  static String unfollowUser(String journalistId) =>
      '/api/users/unfollow/$journalistId';
  static const String userStats = '/api/users/stats';
  static String removeFollower(String id, String followerId) =>
      '/api/users/$id/followers/$followerId';
  static const String createReport = '/api/reports';
  static const String getMyReports = '/api/reports/my';
  static String getReportStats(String type, String id) =>
      '/api/reports/stats/$type/$id';
  static const String createProblemReport = '/api/reports/problem';
  static const String trendingHashtags = '/api/trending/hashtags';
  static const String trendingTopics = '/api/trending/topics';
  static const String trendingPersonalized = '/api/trending/personalized';
  static const String trendingSearch = '/api/trending/search';
  static const String notifications = '/api/notifications';
  static String getNotification(String id) => '/api/notifications/$id';
  static String markNotificationAsRead(String id) =>
      '/api/notifications/$id/read';
  static const String markAllNotificationsAsRead =
      '/api/notifications/mark-all-read';
  static String deleteNotification(String id) => '/api/notifications/$id';
  static const String deleteReadNotifications =
      '/api/notifications/delete-read';
  static const String notificationPreferences =
      '/api/notifications/preferences';
  static const String notificationUnreadCount =
      '/api/notifications/unread-count';
  static const String adminStats = '/api/admin/stats';
  static const String adminJournalists = '/api/admin/journalists';
  static String approveJournalist(String id) =>
      '/api/admin/journalists/$id/approve';
  static String rejectJournalist(String id) =>
      '/api/admin/journalists/$id/reject';
  static const String adminUsers = '/api/admin/users';
  static const String adminPosts = '/api/admin/posts';
  static const String adminReports = '/api/admin/reports';
  static const String upload = '/api/upload';
  static const String uploadProfile = '/api/upload/profile';
  static const String uploadCover = '/api/upload/cover';
  static String buildPath(String path) => path;
  static const String refreshToken = '/api/auth/refresh-token';
  static const String authUpdateProfile = '/api/auth/profile';
  static const String deleteAccount = '/api/auth/delete-account';
  static const String addFormation = '/api/journalists/me/formations';
  static String updateFormation(String id) => '/api/journalists/me/formations/$id';
  static String deleteFormation(String id) => '/api/journalists/me/formations/$id';
  static const String addExperience = '/api/journalists/me/experience';
  static String updateExperience(String id) => '/api/journalists/me/experience/$id';
  static String deleteExperience(String id) => '/api/journalists/me/experience/$id';
  static const String journalistMe = '/api/journalists/me';
  static const String journalistMePosts = '/api/journalists/me/posts';
  static String journalistProfile(String id) => '/api/journalists/$id';
  static String journalistPosts(String id) => '/api/journalists/$id/posts';
  static String journalistFollow(String id) => '/api/journalists/$id/follow';
  static String journalistUnfollow(String id) => '/api/journalists/$id/unfollow';
  static String journalistQuestions(String id) => '/api/journalists/$id/questions';
  static String journalistStats(String id) => '/api/journalists/$id/stats';
  static String answerJournalistQuestionAlt(String id, String questionId) =>
      '/api/journalists/$id/questions/$questionId/answer';
  static const String getComments = '/api/comments/post';
  static const String createCommentAlt = '/api/comments/post';
  static const String updateCommentAlt = '/api/comments';
  static const String deleteCommentAlt = '/api/comments';
  static const String getCommentReplies = '/api/comments/replies';
  static const String getCommentLikesAlt = '/api/comments';
  static String commentLike(String id) => '/api/comments/$id/like';
  static String commentUnlike(String id) => '/api/comments/$id/unlike';
  static const String uploadImage = '/api/upload/image';
  static const String uploadVideo = '/api/upload/video';
  static const String adminJournalistStatsDetailed = '/api/admin/journalists/stats';
  static const String adminJournalistsVerified = '/api/admin/journalists/verified';
  static const String adminJournalistsPending = '/api/admin/journalists/pending';
  static const String adminJournalistsRejected = '/api/admin/journalists/rejected';
  static const String adminJournalistsPressCards = '/api/admin/journalists/press-cards';
  static const String adminLogs = '/api/admin/logs';
  static String adminUnverifyJournalist(String id) => '/api/admin/journalists/$id/unverify';
  static String adminToggleJournalistVerification(String id) =>
      '/api/admin/journalists/$id/toggle-verification';
  static String adminSuspendUser(String id) => '/api/admin/users/$id/suspend';
  static String adminUpdateUserRole(String id) => '/api/admin/users/$id/role';
  static String adminBanUser(String id) => '/api/admin/users/$id/ban';
  static String adminUnbanUser(String id) => '/api/admin/users/$id/unban';
  static String adminDeleteComment(String id) => '/api/admin/comments/$id';
  static String adminDeleteShort(String id) => '/api/admin/shorts/$id';
  static String adminReviewReport(String id) => '/api/admin/reports/$id/review';
  static String adminDeleteContent(String contentType, String contentId) =>
      '/api/admin/$contentType/$contentId';
}
