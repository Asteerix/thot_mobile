import 'package:thot/features/app/content/shared/models/political_view.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/shared/media/utils/url_helper.dart';

class Question {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final UserProfile author;
  final int likes;
  final int dislikes;
  final int comments;
  final List<QuestionVote> votes;
  final List<QuestionOption> options;
  final PoliticalView politicalView;
  final DateTime createdAt;
  final bool isLiked;
  final bool isDisliked;
  const Question({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.author,
    this.likes = 0,
    this.dislikes = 0,
    this.comments = 0,
    this.votes = const [],
    required this.options,
    required this.politicalView,
    required this.createdAt,
    this.isLiked = false,
    this.isDisliked = false,
  });
  int get totalVotes => votes.length;
  int get responseCount => totalVotes;
  UserProfile get journalist => author;
  String get content => description;
  double getOptionPercentage(String optionText) {
    if (totalVotes == 0) return 0;
    final option = options.firstWhere(
      (opt) => opt.text == optionText,
      orElse: () => QuestionOption(text: optionText, votes: 0),
    );
    return (option.votes / totalVotes) * 100;
  }

  bool hasVotedFor(String optionId) {
    return votes.any((vote) => vote.optionId == optionId);
  }

  List<String> getUserVotedOptions() {
    return votes.map((vote) => vote.optionId).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'author': author.toJson(),
      'likes': likes,
      'dislikes': dislikes,
      'comments': comments,
      'votes': votes.map((v) => v.toJson()).toList(),
      'options': options.map((opt) => opt.toJson()).toList(),
      'politicalView': politicalView.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isLiked': isLiked,
      'isDisliked': isDisliked,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    PoliticalView parsePoliticalView(String? value) {
      if (value == null) return PoliticalView.neutral;
      switch (value) {
        case 'extremelyConservative':
        case 'extremely_conservative':
          return PoliticalView.extremelyConservative;
        case 'conservative':
          return PoliticalView.conservative;
        case 'neutral':
          return PoliticalView.neutral;
        case 'progressive':
          return PoliticalView.progressive;
        case 'extremelyProgressive':
        case 'extremely_progressive':
          return PoliticalView.extremelyProgressive;
        default:
          return PoliticalView.neutral;
      }
    }

    final authorData = json['author'] ?? json['journalist'];
    if (authorData == null) {
      throw FormatException(
          'Missing author/journalist data for question ${json['_id']}');
    }
    return Question(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description:
          json['description'] as String? ?? json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] != null
          ? (UrlHelper.buildMediaUrl(json['imageUrl'].toString()) ?? '')
          : '',
      author: UserProfile.fromJson(authorData as Map<String, dynamic>),
      likes: (json['likes'] is List)
          ? (json['likes'] as List).length
          : (json['likes'] as int? ?? 0),
      dislikes: (json['dislikes'] is List)
          ? (json['dislikes'] as List).length
          : (json['dislikes'] as int? ?? 0),
      comments: (json['comments'] is List)
          ? (json['comments'] as List).length
          : (json['comments'] as int? ?? 0),
      votes: (json['votes'] is List)
          ? (json['votes'] as List)
              .map((e) => QuestionVote.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      options: (json['options'] is List)
          ? (json['options'] as List)
              .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      politicalView: parsePoliticalView(json['politicalView'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isLiked: json['isLiked'] == true,
      isDisliked: json['isDisliked'] == true,
    );
  }
}

class QuestionVote {
  final String userId;
  final String optionId;
  const QuestionVote({
    required this.userId,
    required this.optionId,
  });
  factory QuestionVote.fromJson(Map<String, dynamic> json) {
    return QuestionVote(
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      optionId:
          json['option']?.toString() ?? json['optionId']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'option': optionId,
    };
  }
}

class QuestionOption {
  final String? id;
  final String text;
  final int votes;
  final double? percentage;
  const QuestionOption({
    this.id,
    required this.text,
    required this.votes,
    this.percentage,
  });
  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      text: json['text']?.toString() ?? '',
      votes: json['votes'] as int? ?? 0,
      percentage: json['percentage']?.toDouble(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'text': text,
      'votes': votes,
      if (percentage != null) 'percentage': percentage,
    };
  }
}
