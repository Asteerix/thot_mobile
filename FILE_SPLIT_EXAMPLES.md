# File Splitting Examples

This document provides concrete examples of how to split multi-class files according to CLAUDE.md rules.

---

## Example 1: Splitting post_metadata.dart (16 classes)

### ❌ BEFORE (post_metadata.dart - ONE FILE)

```dart
// lib/features/posts/domain/entities/post_metadata.dart

class ArticleMetadata {
  final int? wordCount;
  final List<String>? sources;
  // ... more fields
}

class VideoMetadata {
  final int? duration;
  final String? quality;
  // ... more fields
}

class VideoChapter {
  final String title;
  final int timestamp;
  // ... more fields
}

// ... 13 more classes
```

### ✅ AFTER (Split into 16 files)

#### 1. lib/features/posts/models/article_metadata.dart
```dart
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
      relatedArticles: (json['relatedArticles'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'wordCount': wordCount,
    'sources': sources,
    'citations': citations,
    'relatedArticles': relatedArticles,
  };
}
```

#### 2. lib/features/posts/models/video_metadata.dart
```dart
import 'package:thot/features/posts/models/video_chapter.dart';

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

  // fromJson and toJson methods
}
```

#### 3. lib/features/posts/models/video_chapter.dart
```dart
class VideoChapter {
  final String title;
  final int timestamp;
  final String? description;

  const VideoChapter({
    required this.title,
    required this.timestamp,
    this.description,
  });

  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    return VideoChapter(
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
```

#### 4-16. Repeat for remaining classes...
- `short_metadata.dart`
- `podcast_metadata.dart`
- `podcast_segment.dart`
- `live_metadata.dart`
- `poll_metadata.dart`
- `poll_option.dart`
- `question_metadata.dart`
- `testimony_metadata.dart`
- `documentation_metadata.dart`
- `documentation_section.dart`
- `opinion_metadata.dart`
- `expert_opinion.dart`

#### 17. lib/features/posts/models/post_metadata.dart (Main union class)
```dart
import 'package:thot/features/posts/models/article_metadata.dart';
import 'package:thot/features/posts/models/video_metadata.dart';
import 'package:thot/features/posts/models/podcast_metadata.dart';
// ... import all other metadata types

class PostMetadata {
  final ArticleMetadata? article;
  final VideoMetadata? video;
  final PodcastMetadata? podcast;
  final ShortMetadata? short;
  final LiveMetadata? live;
  final PollMetadata? poll;
  final QuestionMetadata? question;
  final TestimonyMetadata? testimony;
  final DocumentationMetadata? documentation;
  final OpinionMetadata? opinion;

  const PostMetadata({
    this.article,
    this.video,
    this.podcast,
    this.short,
    this.live,
    this.poll,
    this.question,
    this.testimony,
    this.documentation,
    this.opinion,
  });

  // Factory methods and JSON serialization
}
```

---

## Example 2: Splitting post.dart (11 classes)

### ❌ BEFORE (post.dart - ONE FILE)

```dart
// lib/features/posts/domain/entities/post.dart

enum PostType { article, video, podcast, /* ... */ }
enum ContentStatus { draft, published, /* ... */ }
enum PoliticalOrientation { extremelyConservative, /* ... */ }
enum PostDomain { politique, economie, /* ... */ }

class PoliticalVoter { /* ... */ }
class PoliticalOrientationData { /* ... */ }
class PostStats { /* ... */ }
class UserInteractions { /* ... */ }
class JournalistProfile { /* ... */ }
class OppositionPost { /* ... */ }
class Post { /* ... */ }
```

### ✅ AFTER (Split into 11 files)

#### 1. lib/features/posts/models/post_type.dart
```dart
enum PostType {
  article,
  video,
  podcast,
  short,
  question,
  live,
  poll,
  testimony,
  documentation,
  opinion
}
```

#### 2. lib/features/posts/models/content_status.dart
```dart
enum ContentStatus {
  draft,
  published,
  archived,
  hidden,
  deleted
}
```

#### 3. lib/features/posts/models/political_orientation.dart
```dart
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum PoliticalOrientation {
  extremelyConservative,
  conservative,
  neutral,
  progressive,
  extremelyProgressive
}
```

#### 4. lib/features/posts/models/post_domain.dart
```dart
enum PostDomain {
  politique,
  economie,
  science,
  international,
  juridique,
  philosophie,
  societe,
  psychologie,
  sport,
  technologie
}

extension PostDomainExtension on PostDomain {
  String get name {
    switch (this) {
      case PostDomain.politique:
        return 'politique';
      case PostDomain.economie:
        return 'economie';
      // ... rest of cases
    }
  }

  String get displayName {
    switch (this) {
      case PostDomain.politique:
        return 'Politique';
      case PostDomain.economie:
        return 'Economie';
      // ... rest of cases
    }
  }
}
```

#### 5. lib/features/posts/models/political_voter.dart
```dart
import 'package:thot/features/posts/models/political_orientation.dart';

class PoliticalVoter {
  final String userId;
  final String username;
  final String? profilePic;
  final PoliticalOrientation orientation;

  const PoliticalVoter({
    required this.userId,
    required this.username,
    this.profilePic,
    required this.orientation,
  });

  factory PoliticalVoter.fromJson(Map<String, dynamic> json) {
    return PoliticalVoter(
      userId: json['userId'] as String,
      username: json['username'] as String,
      profilePic: json['profilePic'] as String?,
      orientation: PoliticalOrientation.values.firstWhere(
        (e) => e.name == json['orientation'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'profilePic': profilePic,
    'orientation': orientation.name,
  };
}
```

#### 6. lib/features/posts/models/post_stats.dart
```dart
class PostStats {
  final int likes;
  final int dislikes;
  final int comments;
  final int shares;
  final int views;
  final int saves;

  const PostStats({
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.shares,
    required this.views,
    required this.saves,
  });

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      likes: json['likes'] as int? ?? 0,
      dislikes: json['dislikes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'likes': likes,
    'dislikes': dislikes,
    'comments': comments,
    'shares': shares,
    'views': views,
    'saves': saves,
  };
}
```

#### 7-10. Continue for remaining classes...
- `user_interactions.dart`
- `journalist_profile.dart`
- `political_orientation_data.dart`
- `opposition_post.dart`

#### 11. lib/features/posts/models/post.dart (Main class)
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:thot/features/posts/models/post_type.dart';
import 'package:thot/features/posts/models/content_status.dart';
import 'package:thot/features/posts/models/political_orientation.dart';
import 'package:thot/features/posts/models/post_domain.dart';
import 'package:thot/features/posts/models/post_stats.dart';
import 'package:thot/features/posts/models/user_interactions.dart';
import 'package:thot/features/posts/models/journalist_profile.dart';
import 'package:thot/features/posts/models/political_orientation_data.dart';
import 'package:thot/features/posts/models/opposition_post.dart';
import 'package:thot/features/posts/models/post_metadata.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final String id;
  final PostType type;
  final ContentStatus status;
  final String title;
  final String? content;
  final PostMetadata? metadata;
  final PostStats stats;
  final UserInteractions interactions;
  final JournalistProfile? journalist;
  final PoliticalOrientation? politicalOrientation;
  final PoliticalOrientationData? politicalData;
  final List<OppositionPost>? oppositions;
  final PostDomain domain;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Post({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.content,
    this.metadata,
    required this.stats,
    required this.interactions,
    this.journalist,
    this.politicalOrientation,
    this.politicalData,
    this.oppositions,
    required this.domain,
    required this.createdAt,
    this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
```

---

## Example 3: Splitting Widget Files (feed_filters.dart - 10 classes)

### ❌ BEFORE (ONE FILE)

```dart
// lib/features/posts/presentation/shared/widgets/feed_filters.dart

class FeedFilters extends HookConsumerWidget { /* ... */ }
class FilterChip extends StatelessWidget { /* ... */ }
class DomainFilter extends HookWidget { /* ... */ }
class OrientationFilter extends HookWidget { /* ... */ }
class ContentTypeFilter extends StatelessWidget { /* ... */ }
// ... 5 more widget classes
```

### ✅ AFTER (Split into subdirectory)

#### Create: lib/features/posts/widgets/feed_filters/

#### 1. feed_filters.dart (Main widget)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thot/features/posts/widgets/feed_filters/domain_filter.dart';
import 'package:thot/features/posts/widgets/feed_filters/orientation_filter.dart';
import 'package:thot/features/posts/widgets/feed_filters/content_type_filter.dart';

class FeedFilters extends HookConsumerWidget {
  const FeedFilters({
    super.key,
    required this.onFilterChanged,
  });

  final void Function(Map<String, dynamic>) onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DomainFilter(onChanged: (domain) => _handleDomainChange(domain)),
        const Gap(8),
        OrientationFilter(onChanged: (orientation) => _handleOrientationChange(orientation)),
        const Gap(8),
        ContentTypeFilter(onChanged: (type) => _handleTypeChange(type)),
      ],
    );
  }

  void _handleDomainChange(String? domain) {
    // Implementation
  }

  void _handleOrientationChange(String? orientation) {
    // Implementation
  }

  void _handleTypeChange(String? type) {
    // Implementation
  }
}
```

#### 2. filter_chip.dart (Reusable base widget)
```dart
import 'package:flutter/material.dart';

class FilterChip extends StatelessWidget {
  const FilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

#### 3. domain_filter.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:thot/features/posts/models/post_domain.dart';
import 'package:thot/features/posts/widgets/feed_filters/filter_chip.dart';

class DomainFilter extends HookWidget {
  const DomainFilter({
    super.key,
    required this.onChanged,
  });

  final void Function(PostDomain?) onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedDomain = useState<PostDomain?>(null);
    final domains = PostDomain.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Domain',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: domains.map((domain) {
            return FilterChip(
              label: domain.displayName,
              isSelected: selectedDomain.value == domain,
              onTap: () => _handleDomainTap(domain, selectedDomain),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handleDomainTap(
    PostDomain domain,
    ValueNotifier<PostDomain?> selectedDomain,
  ) {
    final newValue = selectedDomain.value == domain ? null : domain;
    selectedDomain.value = newValue;
    onChanged(newValue);
  }
}
```

#### 4-10. Continue for remaining widgets...
- `orientation_filter.dart`
- `content_type_filter.dart`
- `date_range_filter.dart`
- `author_filter.dart`
- etc.

---

## Example 4: Renaming Screens (Remove _screen suffix)

### Before
```
lib/features/posts/presentation/mobile/screens/
├── feed_screen.dart
├── post_detail_screen.dart
├── new_article_screen.dart
├── shorts_screen.dart
└── saved_content_screen.dart
```

### After
```
lib/features/posts/screens/
├── feed.dart
├── post_detail.dart
├── new_article.dart
├── shorts.dart
└── saved_content.dart
```

### Import Updates

#### Before:
```dart
import 'package:thot/features/posts/presentation/mobile/screens/feed_screen.dart';
```

#### After:
```dart
import 'package:thot/features/posts/screens/feed.dart';
```

---

## Example 5: Failure Classes (Special Case)

Failure classes often use sealed classes with subtypes. Consider if they should be split:

### Option A: Keep Together (Acceptable for sealed classes)

```dart
// lib/features/posts/models/post_failure.dart

sealed class PostFailure {
  const PostFailure();
}

class PostNotFoundFailure extends PostFailure {
  const PostNotFoundFailure();
}

class PostNetworkFailure extends PostFailure {
  const PostNetworkFailure(this.message);
  final String message;
}

// ... more subtypes (4-6 total is acceptable for sealed classes)
```

### Option B: Split (If more than 6 classes)

If the failure file has 6+ classes, consider splitting into:

```
models/failures/
├── post_failure.dart        # Base sealed class
├── post_not_found.dart      # Subtype
├── post_network_failure.dart # Subtype
├── post_auth_failure.dart    # Subtype
└── post_validation_failure.dart # Subtype
```

**Recommendation:** Keep failures together if using sealed class pattern (Dart 3.0+) and < 8 subtypes.

---

## Summary of Rules

1. **One file = One public class**
   - Enums count as classes
   - Private helper classes in same file are OK
   - Sealed class + its subtypes can be together IF < 8 total

2. **Clear file names**
   - Match the class name: `class Post` → `post.dart`
   - No suffixes: NOT `post_model.dart`, just `post.dart`
   - No prefixes: NOT `app_post.dart`, just `post.dart`

3. **Proper imports**
   - Update all imports after splitting
   - Use absolute paths: `package:thot/features/...`
   - Group related imports

4. **Directory organization**
   - Create subdirectories when > 5 related files
   - Example: `widgets/feed_filters/` for feed filter widgets

---

## Tools & Scripts

### Find multi-class files:
```bash
find lib/features -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" \
  -exec sh -c 'count=$(grep -cE "^(class|abstract class|enum) " "$1" 2>/dev/null || echo 0); \
  if [ "$count" -gt 1 ]; then echo "$1: $count classes"; fi' _ {} \;
```

### Update imports after splitting:
```bash
cd lib
./update_imports_helper.sh
```

### Verify no duplicates:
```bash
flutter analyze | grep "duplicate"
```

---

*This guide provides the blueprint for splitting all multi-class files in the project. Follow these patterns for consistent, clean architecture.*
