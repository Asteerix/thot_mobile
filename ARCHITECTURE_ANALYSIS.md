# Thot Mobile - Architecture Analysis & Reorganization Plan

**Date:** 2025-11-12
**Project:** /Users/amaury/Desktop/backup/thot/thot_mobile

---

## 📊 Current Architecture Analysis

### ❌ Major Violations of CLAUDE.md Rules

#### 1. **CRITICAL: Multiple Classes Per File**

The project has **extensive violations** of the "1 file = 1 class" rule:

| File | Classes | Severity |
|------|---------|----------|
| `posts/domain/entities/post_metadata.dart` | **16** | 🔴 CRITICAL |
| `posts/domain/entities/post.dart` | **11** | 🔴 CRITICAL |
| `posts/presentation/shared/widgets/feed_filters.dart` | **10** | 🔴 CRITICAL |
| `settings/presentation/mobile/screens/about_screen.dart` | **8** | 🔴 HIGH |
| `settings/presentation/mobile/screens/change_password_screen.dart` | **8** | 🔴 HIGH |
| `posts/data/repositories/post_repository_impl.dart` | **8** | 🔴 HIGH |
| `settings/domain/failures/settings_failure.dart` | **6** | 🟡 MEDIUM |
| `comments/domain/failures/comment_failure.dart` | **6** | 🟡 MEDIUM |
| `posts/domain/failures/post_failure.dart` | **6** | 🟡 MEDIUM |
| `settings/presentation/mobile/screens/settings_screen.dart` | **6** | 🟡 MEDIUM |
| `posts/widgets/interaction_buttons.dart` | **5** | 🟡 MEDIUM |

**Total files with violations:** 50+

#### 2. **CRITICAL: Wrong Architecture Pattern**

Current structure uses **Clean Architecture** (data/domain/application layers), which violates CLAUDE.md rules:

```
❌ CURRENT (Wrong):
features/
  posts/
    ├── data/              ← REMOVE
    │   ├── models/
    │   └── repositories/
    ├── domain/            ← REMOVE
    │   ├── entities/
    │   ├── failures/
    │   └── repositories/
    ├── application/       ← REMOVE
    │   └── providers/
    └── presentation/      ← REMOVE
        ├── mobile/
        └── shared/

✅ TARGET (Correct):
features/
  posts/
    ├── models/           # Freezed models only
    ├── providers/        # Riverpod providers
    ├── screens/          # Screen widgets
    └── widgets/          # Feature widgets
```

#### 3. **File Naming Issues**

Many files use incorrect suffixes:

```
❌ WRONG:
- feed_screen.dart
- login_screen.dart
- user_card_widget.dart
- post_model.dart

✅ CORRECT:
- feed.dart
- login.dart
- user_card.dart
- post.dart
```

---

## 🎯 Reorganization Strategy

### Phase 1: Automated (Script)
✅ **Completed by `reorganize_architecture.sh`**

1. Create backup
2. Create new directory structure
3. Copy files to new locations
4. Split basic enums (post_type, content_status, etc.)
5. Create import update helper
6. Generate TODO for manual steps

### Phase 2: Manual (Required)
⚠️ **Human intervention needed**

#### Priority 1: Split Multi-Class Files

**Posts Feature** (most complex):

1. **post_metadata.dart** (16 classes → 16 files)
   ```
   ├── article_metadata.dart
   ├── video_metadata.dart
   ├── video_chapter.dart
   ├── short_metadata.dart
   ├── podcast_metadata.dart
   ├── podcast_segment.dart
   ├── live_metadata.dart
   ├── poll_metadata.dart
   ├── poll_option.dart
   ├── question_metadata.dart
   ├── testimony_metadata.dart
   ├── documentation_metadata.dart
   ├── documentation_section.dart
   ├── opinion_metadata.dart
   ├── expert_opinion.dart
   └── post_metadata.dart
   ```

2. **post.dart** (11 classes → 8 files)
   ```
   Enums (already split by script):
   ✓ post_type.dart
   ✓ content_status.dart
   ✓ political_orientation.dart
   ✓ post_domain.dart

   Still need:
   ├── political_voter.dart
   ├── political_orientation_data.dart
   ├── post_stats.dart
   ├── user_interactions.dart
   ├── journalist_profile.dart
   ├── opposition_post.dart
   └── post.dart (main)
   ```

3. **question.dart** (3 classes → 3 files)
   ```
   ├── question.dart
   ├── question_vote.dart
   └── question_option.dart
   ```

4. **Widgets** (multiple classes in widget files)
   - `feed_filters.dart` (10 classes)
   - `interaction_buttons.dart` (5 classes)
   - Each needs to be split into separate widget files

**Settings Feature**:
- `about_screen.dart` (8 classes) → Split widgets
- `change_password_screen.dart` (8 classes) → Split widgets
- `settings_screen.dart` (6 classes) → Split widgets

**Other Features**:
- Comment, notification, profile, etc. failures (6 classes each)
  - Review if sealed class pattern justifies keeping together
  - Otherwise split

#### Priority 2: Rename Files

Remove suffixes from all files:

```bash
# Screens (in /screens/ folders)
mv feed_screen.dart feed.dart
mv login_screen.dart login.dart
mv profile_screen.dart profile.dart
# ... repeat for all screens

# Widgets (if any have _widget suffix)
mv user_card_widget.dart user_card.dart
```

#### Priority 3: Update Imports

```bash
# Run the helper script
cd lib
./update_imports_helper.sh

# Then manually fix remaining imports
flutter analyze  # Find broken imports
```

Key import changes:
```dart
// OLD
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/application/providers/posts_provider.dart';
import 'package:thot/features/posts/presentation/mobile/screens/feed_screen.dart';

// NEW
import 'package:thot/features/posts/models/post.dart';
import 'package:thot/features/posts/providers/posts_provider.dart';
import 'package:thot/features/posts/screens/feed.dart';
```

#### Priority 4: Clean Up

```bash
# Delete old structure (ONLY AFTER imports are fixed!)
rm -rf lib/features/*/domain
rm -rf lib/features/*/data
rm -rf lib/features/*/application
rm -rf lib/features/*/presentation

# Regenerate freezed/json files
dart run build_runner build --delete-conflicting-outputs

# Verify
flutter analyze
flutter test
```

---

## 📁 Final Directory Structure

```
lib/
├── features/
│   ├── admin/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── authentication/
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── user.freezed.dart
│   │   │   ├── user.g.dart
│   │   │   └── auth_dto.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   ├── screens/
│   │   │   ├── welcome.dart
│   │   │   ├── login.dart
│   │   │   ├── registration_stepper.dart
│   │   │   └── mode_selection.dart
│   │   └── widgets/
│   │       ├── auth_text_field.dart
│   │       ├── welcome_logo.dart
│   │       └── auth_loading_button.dart
│   ├── comments/
│   │   ├── models/
│   │   │   └── comment.dart
│   │   ├── providers/
│   │   │   └── comments_provider.dart
│   │   ├── screens/
│   │   └── widgets/
│   │       ├── comments_section.dart
│   │       ├── comment_list.dart
│   │       └── comment_list_item.dart
│   ├── media/
│   │   ├── models/
│   │   │   └── media_file.dart
│   │   ├── providers/
│   │   │   └── media_provider.dart
│   │   ├── screens/
│   │   │   └── image_crop.dart
│   │   └── widgets/
│   │       ├── media_picker.dart
│   │       ├── video_player_preview.dart
│   │       └── audio_player_preview.dart
│   ├── notifications/
│   │   ├── models/
│   │   │   └── notification.dart
│   │   ├── providers/
│   │   │   └── notifications_provider.dart
│   │   ├── screens/
│   │   │   ├── notifications.dart
│   │   │   └── post_detail.dart
│   │   └── widgets/
│   │       ├── notification_card.dart
│   │       ├── notification_empty_state.dart
│   │       └── notification_filter.dart
│   ├── posts/
│   │   ├── models/
│   │   │   # Enums
│   │   │   ├── post_type.dart
│   │   │   ├── content_status.dart
│   │   │   ├── political_orientation.dart
│   │   │   ├── post_domain.dart
│   │   │   ├── political_view.dart
│   │   │   # Main entities
│   │   │   ├── post.dart
│   │   │   ├── post_stats.dart
│   │   │   ├── user_interactions.dart
│   │   │   ├── journalist_profile.dart
│   │   │   ├── political_voter.dart
│   │   │   ├── political_orientation_data.dart
│   │   │   ├── opposition_post.dart
│   │   │   ├── short.dart
│   │   │   ├── saved_short.dart
│   │   │   # Questions
│   │   │   ├── question.dart
│   │   │   ├── question_vote.dart
│   │   │   ├── question_option.dart
│   │   │   # Metadata (split from post_metadata.dart)
│   │   │   ├── article_metadata.dart
│   │   │   ├── video_metadata.dart
│   │   │   ├── video_chapter.dart
│   │   │   ├── short_metadata.dart
│   │   │   ├── podcast_metadata.dart
│   │   │   ├── podcast_segment.dart
│   │   │   ├── live_metadata.dart
│   │   │   ├── poll_metadata.dart
│   │   │   ├── poll_option.dart
│   │   │   ├── question_metadata.dart
│   │   │   ├── testimony_metadata.dart
│   │   │   ├── documentation_metadata.dart
│   │   │   ├── documentation_section.dart
│   │   │   ├── opinion_metadata.dart
│   │   │   ├── expert_opinion.dart
│   │   │   └── post_metadata.dart
│   │   ├── providers/
│   │   │   ├── posts_provider.dart
│   │   │   └── posts_state_provider.dart
│   │   ├── screens/
│   │   │   ├── feed.dart
│   │   │   ├── main.dart
│   │   │   ├── post_detail.dart
│   │   │   ├── article_detail.dart
│   │   │   ├── video_detail.dart
│   │   │   ├── podcast_detail.dart
│   │   │   ├── poll_detail.dart
│   │   │   ├── question_detail.dart
│   │   │   ├── shorts.dart
│   │   │   ├── shorts_feed.dart
│   │   │   ├── saved_content.dart
│   │   │   ├── new_article.dart
│   │   │   ├── new_video.dart
│   │   │   ├── new_podcast.dart
│   │   │   ├── new_live.dart
│   │   │   ├── new_short.dart
│   │   │   ├── new_publication.dart
│   │   │   ├── new_question.dart
│   │   │   ├── question.dart
│   │   │   └── question_type_selection.dart
│   │   └── widgets/
│   │       ├── post_card.dart
│   │       ├── post_header.dart
│   │       ├── post_content.dart
│   │       ├── post_actions.dart
│   │       ├── interaction_buttons/
│   │       │   # Split from interaction_buttons.dart
│   │       │   ├── like_button.dart
│   │       │   ├── comment_button.dart
│   │       │   ├── share_button.dart
│   │       │   └── save_button.dart
│   │       ├── feed_filters/
│   │       │   # Split from feed_filters.dart
│   │       │   ├── filter_chip.dart
│   │       │   ├── domain_filter.dart
│   │       │   └── orientation_filter.dart
│   │       ├── question_card_with_voting.dart
│   │       ├── voting_dialog.dart
│   │       ├── opposition_dialog.dart
│   │       ├── feed_app_header.dart
│   │       ├── article_post.dart
│   │       ├── video_post.dart
│   │       ├── podcast_post.dart
│   │       ├── short_video_player.dart
│   │       └── feed_item.dart
│   ├── profile/
│   │   ├── models/
│   │   │   ├── user_profile.dart
│   │   │   └── question.dart
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── profile.dart
│   │   │   ├── user_profile.dart
│   │   │   ├── edit_profile.dart
│   │   │   ├── edit_journalist_card.dart
│   │   │   └── following.dart
│   │   └── widgets/
│   │       ├── profile_header.dart
│   │       ├── profile_avatar.dart
│   │       ├── profile_cover.dart
│   │       ├── profile_tabs.dart
│   │       ├── profile_grid.dart
│   │       ├── profile_grid_item.dart
│   │       ├── follow_button.dart
│   │       └── profile_speed_dial.dart
│   ├── search/
│   │   ├── models/
│   │   │   └── search_result.dart
│   │   ├── providers/
│   │   │   └── search_provider.dart
│   │   ├── screens/
│   │   │   ├── search.dart
│   │   │   └── explore.dart
│   │   └── widgets/
│   │       ├── search_bar_widget.dart
│   │       ├── search_filter_chip.dart
│   │       ├── journalist_card.dart
│   │       ├── journalist_list_item.dart
│   │       └── user_search.dart
│   └── settings/
│       ├── models/
│       │   └── app_settings.dart
│       ├── providers/
│       │   └── settings_provider.dart
│       ├── screens/
│       │   ├── settings.dart
│       │   ├── about.dart
│       │   ├── change_password.dart
│       │   ├── notification_preferences.dart
│       │   ├── subscriptions.dart
│       │   ├── report_problem.dart
│       │   ├── privacy_policy.dart
│       │   └── terms.dart
│       └── widgets/
│           ├── setting_tile.dart
│           ├── link_tile.dart
│           ├── section_header.dart
│           ├── section_card.dart
│           ├── danger_zone_card.dart
│           └── version_chip.dart
├── shared/
│   ├── models/
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── app_header.dart
│   │   │   ├── app_avatar.dart
│   │   │   ├── app_network_image.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── empty_state.dart
│   │   │   ├── error_view.dart
│   │   │   ├── shimmer_loading.dart
│   │   │   └── keyboard_dismissible.dart
│   │   ├── forms/
│   │   │   └── custom_text_field.dart
│   │   ├── screens/
│   │   │   └── creation_screen_layout.dart
│   │   ├── logo.dart
│   │   ├── logo_black.dart
│   │   ├── logo_white.dart
│   │   └── bottom_nav_bar.dart
│   ├── utils/
│   │   ├── color_utils.dart
│   │   ├── dialog_utils.dart
│   │   └── responsive_utils.dart
│   └── extensions/
│       └── context_extensions.dart
├── core/
│   ├── config/
│   │   └── env.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── app_config.dart
│   │   ├── api_routes.dart
│   │   ├── spacing_constants.dart
│   │   └── asset_paths.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── mobile_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   └── ui_tokens.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_config.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── retry_interceptor.dart
│   ├── storage/
│   │   ├── token_service.dart
│   │   ├── search_history_service.dart
│   │   └── offline_cache_service.dart
│   └── utils/
│       ├── either.dart
│       ├── date_formatter.dart
│       ├── time_formatter.dart
│       ├── number_formatter.dart
│       ├── debouncer.dart
│       └── keyboard_service.dart
└── main.dart
```

---

## 🔄 Migration Impact

### Affected Files: ~300+ Dart files

### Import Updates Required:
- **Posts feature:** ~150 import statements
- **Authentication:** ~50 import statements
- **Other features:** ~100 import statements

### Risk Level: 🟡 MEDIUM
- Automated script handles structure creation
- Manual file splitting is time-consuming but low-risk
- Import updates can be semi-automated
- Comprehensive testing required after migration

---

## ✅ Benefits of Reorganization

### 1. **Code Clarity**
- One file = one class (no mental overhead)
- Clear feature boundaries
- Easier to navigate

### 2. **Maintainability**
- Simpler architecture (no data/domain/application layers)
- Easier to add new features
- Less boilerplate

### 3. **Developer Experience**
- Follows CLAUDE.md standards
- Better IDE support (faster indexing)
- Clearer import paths

### 4. **Performance**
- Faster builds (smaller files = better caching)
- Better tree-shaking

---

## 📝 Checklist

### Pre-Execution
- [ ] Read this document completely
- [ ] Review CLAUDE.md Flutter rules
- [ ] Ensure git is clean (`git status`)
- [ ] Create a new branch: `git checkout -b feat/architecture-reorganization`

### Execution
- [ ] Run `./reorganize_architecture.sh`
- [ ] Review backup location
- [ ] Read `REORGANIZATION_TODO.md`
- [ ] Split multi-class files (manual)
- [ ] Rename files to remove suffixes
- [ ] Run `lib/update_imports_helper.sh`
- [ ] Fix remaining imports manually
- [ ] Delete old structure folders
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`

### Verification
- [ ] `flutter analyze` → 0 errors
- [ ] `dart format .` → formatted
- [ ] `flutter test` → all pass
- [ ] App runs on iOS
- [ ] App runs on Android
- [ ] All navigation works
- [ ] No duplicate classes
- [ ] All imports correct

### Finalization
- [ ] Commit changes with clear message
- [ ] Push to remote
- [ ] Create PR with this analysis as description
- [ ] Request code review
- [ ] Merge when approved

---

## 🆘 Troubleshooting

### "Duplicate class definition"
**Cause:** Class exists in both old and new locations
**Fix:** Delete old structure only AFTER imports are fixed

### "Cannot find import"
**Cause:** Import path not updated
**Fix:** Run `flutter analyze`, manually update paths

### "Part directive error"
**Cause:** Freezed files looking for old locations
**Fix:** Run `dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs`

### "Circular dependency"
**Cause:** Files referencing each other after split
**Fix:** Create a common base file or restructure references

---

## 📚 References

- **CLAUDE.md:** Flutter rules (especially sections on architecture)
- **Reorganization Script:** `./reorganize_architecture.sh`
- **Manual Steps:** `REORGANIZATION_TODO.md`
- **Import Helper:** `lib/update_imports_helper.sh`

---

**Status:** Ready to execute
**Estimated Time:** 4-6 hours (including manual steps)
**Difficulty:** Medium (requires attention to detail)

---

*Generated by Claude Code - Architecture Analysis Tool*
