import 'package:thot/features/app/content/shared/models/question.dart';

class ArticleMetadata {
  final int? wordCount;
  final List<String>? sources;
  final List<String>? citations;
  final List<String>? relatedArticles;
  const ArticleMetadata({
    this.wordCount,
    this.sources,
    this.citations,
    this.relatedArticles,
  });
  factory ArticleMetadata.fromJson(Map<String, dynamic> json) {
    return ArticleMetadata(
      wordCount: json['wordCount'] as int?,
      sources: (json['sources'] as List<dynamic>?)?.cast<String>(),
      citations: (json['citations'] as List<dynamic>?)?.cast<String>(),
      relatedArticles:
          (json['relatedArticles'] as List<dynamic>?)?.cast<String>(),
    );
  }
  Map<String, dynamic> toJson() => {
        'wordCount': wordCount,
        'sources': sources,
        'citations': citations,
        'relatedArticles': relatedArticles,
      };
}

class VideoMetadata {
  final int? duration;
  final String? quality;
  final String? transcript;
  final List<VideoChapter>? chapters;
  final String? hash;
  final int? size;
  final int? width;
  final int? height;
  final String? originalName;
  final String? originalExtension;
  const VideoMetadata({
    this.duration,
    this.quality,
    this.transcript,
    this.chapters,
    this.hash,
    this.size,
    this.width,
    this.height,
    this.originalName,
    this.originalExtension,
  });
  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      duration: json['duration'] as int?,
      quality: json['quality'] as String?,
      transcript: json['transcript'] as String?,
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((e) => VideoChapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      hash: json['hash'] as String?,
      size: json['size'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      originalName: json['original_name'] as String?,
      originalExtension: json['original_extension'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
        'duration': duration,
        'quality': quality,
        'transcript': transcript,
        'chapters': chapters?.map((e) => e.toJson()).toList(),
        'hash': hash,
        'size': size,
        'width': width,
        'height': height,
        'original_name': originalName,
        'original_extension': originalExtension,
      };
}

class VideoChapter {
  final String title;
  final int timestamp;
  const VideoChapter({
    required this.title,
    required this.timestamp,
  });
  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    return VideoChapter(
      title: json['title'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
  Map<String, dynamic> toJson() => {
        'title': title,
        'timestamp': timestamp,
      };
}

class ShortMetadata {
  final int? duration;
  final int views;
  final int likes;
  const ShortMetadata({
    this.duration,
    this.views = 0,
    this.likes = 0,
  });
  factory ShortMetadata.fromJson(Map<String, dynamic> json) {
    return ShortMetadata(
      duration: json['duration'] as int?,
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() => {
        'duration': duration,
        'views': views,
        'likes': likes,
      };
}

class PodcastMetadata {
  final int? duration;
  final String? transcript;
  final List<String>? guests;
  final List<PodcastSegment>? segments;
  final String? audioUrl;
  const PodcastMetadata({
    this.duration,
    this.transcript,
    this.guests,
    this.segments,
    this.audioUrl,
  });
  factory PodcastMetadata.fromJson(Map<String, dynamic> json) {
    return PodcastMetadata(
      duration: json['duration'] as int?,
      audioUrl: json['audioUrl'] as String?,
      transcript: json['transcript'] as String?,
      guests: (json['guests'] as List<dynamic>?)?.cast<String>(),
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => PodcastSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
        'duration': duration,
        'audioUrl': audioUrl,
        'transcript': transcript,
        'guests': guests,
        'segments': segments?.map((e) => e.toJson()).toList(),
      };
}

class PodcastSegment {
  final String title;
  final int timestamp;
  final String? description;
  const PodcastSegment({
    required this.title,
    required this.timestamp,
    this.description,
  });
  factory PodcastSegment.fromJson(Map<String, dynamic> json) {
    return PodcastSegment(
      title: json['title'] as String,
      timestamp: json['timestamp'] as int,
      description: json['description'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
        'title': title,
        'timestamp': timestamp,
        'description': description,
      };
}

class LiveMetadata {
  final DateTime? scheduledStart;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int? participants;
  final bool chatEnabled;
  final bool replayAvailable;
  const LiveMetadata({
    this.scheduledStart,
    this.actualStart,
    this.actualEnd,
    this.participants,
    this.chatEnabled = true,
    this.replayAvailable = false,
  });
  factory LiveMetadata.fromJson(Map<String, dynamic> json) {
    return LiveMetadata(
      scheduledStart: json['scheduledStart'] != null
          ? DateTime.parse(json['scheduledStart'] as String)
          : null,
      actualStart: json['actualStart'] != null
          ? DateTime.parse(json['actualStart'] as String)
          : null,
      actualEnd: json['actualEnd'] != null
          ? DateTime.parse(json['actualEnd'] as String)
          : null,
      participants: json['participants'] as int?,
      chatEnabled: json['chatEnabled'] as bool? ?? true,
      replayAvailable: json['replayAvailable'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
        'scheduledStart': scheduledStart?.toIso8601String(),
        'actualStart': actualStart?.toIso8601String(),
        'actualEnd': actualEnd?.toIso8601String(),
        'participants': participants,
        'chatEnabled': chatEnabled,
        'replayAvailable': replayAvailable,
      };
}

class PollMetadata {
  final List<PollOption> options;
  final int totalVotes;
  final DateTime? endDate;
  final bool allowComments;
  const PollMetadata({
    required this.options,
    required this.totalVotes,
    this.endDate,
    this.allowComments = true,
  });
  factory PollMetadata.fromJson(Map<String, dynamic> json) {
    return PollMetadata(
      options: (json['options'] as List<dynamic>)
          .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVotes: json['totalVotes'] as int,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      allowComments: json['allowComments'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toJson() => {
        'options': options.map((e) => e.toJson()).toList(),
        'totalVotes': totalVotes,
        'endDate': endDate?.toIso8601String(),
        'allowComments': allowComments,
      };
}

class QuestionMetadata {
  final String? questionType;
  final String? type;
  final List<QuestionOption>? options;
  final int? totalVotes;
  final DateTime? endDate;
  final bool? multipleChoice;
  final bool? allowComments;
  const QuestionMetadata({
    this.questionType,
    this.type,
    this.options,
    this.totalVotes,
    this.endDate,
    this.multipleChoice,
    this.allowComments,
  });
  factory QuestionMetadata.fromJson(Map<String, dynamic> json) {
    return QuestionMetadata(
      questionType: json['questionType'] as String?,
      type: json['type'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVotes: json['totalVotes'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      multipleChoice: json['multipleChoice'] as bool?,
      allowComments: json['allowComments'] as bool?,
    );
  }
  Map<String, dynamic> toJson() => {
        'questionType': questionType,
        'type': type,
        'options': options?.map((e) => e.toJson()).toList(),
        'totalVotes': totalVotes,
        'endDate': endDate?.toIso8601String(),
        'multipleChoice': multipleChoice,
        'allowComments': allowComments,
      };
}

class PollOption {
  final String text;
  final int votes;
  const PollOption({
    required this.text,
    required this.votes,
  });
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] as String,
      votes: json['votes'] as int,
    );
  }
  Map<String, dynamic> toJson() => {
        'text': text,
        'votes': votes,
      };
}

class TestimonyMetadata {
  final String verificationStatus;
  final String? verificationDetails;
  final String? location;
  final DateTime? date;
  final List<String>? supportingDocs;
  const TestimonyMetadata({
    required this.verificationStatus,
    this.verificationDetails,
    this.location,
    this.date,
    this.supportingDocs,
  });
  factory TestimonyMetadata.fromJson(Map<String, dynamic> json) {
    return TestimonyMetadata(
      verificationStatus: json['verificationStatus'] as String,
      verificationDetails: json['verificationDetails'] as String?,
      location: json['location'] as String?,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      supportingDocs:
          (json['supportingDocs'] as List<dynamic>?)?.cast<String>(),
    );
  }
  Map<String, dynamic> toJson() => {
        'verificationStatus': verificationStatus,
        'verificationDetails': verificationDetails,
        'location': location,
        'date': date?.toIso8601String(),
        'supportingDocs': supportingDocs,
      };
}

class DocumentationMetadata {
  final List<DocumentationSection>? sections;
  final List<String>? references;
  final List<String>? contributors;
  final DateTime? lastUpdated;
  const DocumentationMetadata({
    this.sections,
    this.references,
    this.contributors,
    this.lastUpdated,
  });
  factory DocumentationMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentationMetadata(
      sections: (json['sections'] as List<dynamic>?)
          ?.map((e) => DocumentationSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      references: (json['references'] as List<dynamic>?)?.cast<String>(),
      contributors: (json['contributors'] as List<dynamic>?)?.cast<String>(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
        'sections': sections?.map((e) => e.toJson()).toList(),
        'references': references,
        'contributors': contributors,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };
}

class DocumentationSection {
  final String title;
  final String content;
  const DocumentationSection({
    required this.title,
    required this.content,
  });
  factory DocumentationSection.fromJson(Map<String, dynamic> json) {
    return DocumentationSection(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };
}

class OpinionMetadata {
  final List<String>? mainArguments;
  final List<String>? counterArguments;
  final List<String>? sources;
  final List<ExpertOpinion>? expertOpinions;
  const OpinionMetadata({
    this.mainArguments,
    this.counterArguments,
    this.sources,
    this.expertOpinions,
  });
  factory OpinionMetadata.fromJson(Map<String, dynamic> json) {
    return OpinionMetadata(
      mainArguments: (json['mainArguments'] as List<dynamic>?)?.cast<String>(),
      counterArguments:
          (json['counterArguments'] as List<dynamic>?)?.cast<String>(),
      sources: (json['sources'] as List<dynamic>?)?.cast<String>(),
      expertOpinions: (json['expertOpinions'] as List<dynamic>?)
          ?.map((e) => ExpertOpinion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
        'mainArguments': mainArguments,
        'counterArguments': counterArguments,
        'sources': sources,
        'expertOpinions': expertOpinions?.map((e) => e.toJson()).toList(),
      };
}

class ExpertOpinion {
  final String expert;
  final String opinion;
  final String credentials;
  const ExpertOpinion({
    required this.expert,
    required this.opinion,
    required this.credentials,
  });
  factory ExpertOpinion.fromJson(Map<String, dynamic> json) {
    return ExpertOpinion(
      expert: json['expert'] as String,
      opinion: json['opinion'] as String,
      credentials: json['credentials'] as String,
    );
  }
  Map<String, dynamic> toJson() => {
        'expert': expert,
        'opinion': opinion,
        'credentials': credentials,
      };
}

class PostMetadata {
  final ArticleMetadata? article;
  final VideoMetadata? video;
  final ShortMetadata? short;
  final PodcastMetadata? podcast;
  final LiveMetadata? live;
  final PollMetadata? poll;
  final QuestionMetadata? question;
  final TestimonyMetadata? testimony;
  final DocumentationMetadata? documentation;
  final OpinionMetadata? opinion;
  const PostMetadata({
    this.article,
    this.video,
    this.short,
    this.podcast,
    this.live,
    this.poll,
    this.question,
    this.testimony,
    this.documentation,
    this.opinion,
  });
  factory PostMetadata.fromJson(Map<String, dynamic> json) {
    return PostMetadata(
      article: json['article'] != null
          ? ArticleMetadata.fromJson(json['article'] as Map<String, dynamic>)
          : null,
      video: json['video'] != null
          ? VideoMetadata.fromJson(json['video'] as Map<String, dynamic>)
          : null,
      short: json['short'] != null
          ? ShortMetadata.fromJson(json['short'] as Map<String, dynamic>)
          : null,
      podcast: json['podcast'] != null
          ? PodcastMetadata.fromJson(json['podcast'] as Map<String, dynamic>)
          : null,
      live: json['live'] != null
          ? LiveMetadata.fromJson(json['live'] as Map<String, dynamic>)
          : null,
      poll: json['poll'] != null
          ? PollMetadata.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
      question: json['question'] != null
          ? QuestionMetadata.fromJson(json['question'] as Map<String, dynamic>)
          : null,
      testimony: json['testimony'] != null
          ? TestimonyMetadata.fromJson(
              json['testimony'] as Map<String, dynamic>)
          : null,
      documentation: json['documentation'] != null
          ? DocumentationMetadata.fromJson(
              json['documentation'] as Map<String, dynamic>)
          : null,
      opinion: json['opinion'] != null
          ? OpinionMetadata.fromJson(json['opinion'] as Map<String, dynamic>)
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
        'article': article?.toJson(),
        'video': video?.toJson(),
        'short': short?.toJson(),
        'podcast': podcast?.toJson(),
        'live': live?.toJson(),
        'poll': poll?.toJson(),
        'question': question?.toJson(),
        'testimony': testimony?.toJson(),
        'documentation': documentation?.toJson(),
        'opinion': opinion?.toJson(),
      };
}
