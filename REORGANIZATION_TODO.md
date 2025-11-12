# Architecture Reorganization - Manual Steps

## ✅ COMPLETED (by script)
- [x] Backup created
- [x] New directory structure created
- [x] Files copied to new locations
- [x] Basic enum splits created for posts

## 🔴 CRITICAL - Manual Steps Required

### 1. Split Multi-Class Files (HIGH PRIORITY)

#### Posts Feature
- [ ] **lib/features/posts/models/post_metadata.dart** (16 classes!)
  - Split into separate files:
    - `article_metadata.dart`
    - `video_metadata.dart`
    - `video_chapter.dart`
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
    - `post_metadata.dart` (main class)

- [ ] **lib/features/posts/models/post.dart** (11 classes)
  - Already started splitting enums (✓)
  - Still need to split:
    - `political_voter.dart`
    - `political_orientation_data.dart`
    - `post_stats.dart`
    - `user_interactions.dart`
    - `journalist_profile.dart`
    - `opposition_post.dart`
    - `post.dart` (main class)

- [ ] **lib/features/posts/models/question.dart** (3 classes)
  - Split into:
    - `question.dart`
    - `question_vote.dart`
    - `question_option.dart`

- [ ] **lib/features/posts/widgets/feed_filters.dart** (10 classes!)
  - Split into separate widget files

- [ ] **lib/features/posts/widgets/interaction_buttons.dart** (5 classes)
  - Split into separate widget files

- [ ] **lib/features/posts/providers/post_repository_impl.dart** (8 classes)
  - Review and split if needed

#### Settings Feature
- [ ] **lib/features/settings/screens/settings_screen.dart** (6 classes)
  - Split into separate widgets
- [ ] **lib/features/settings/screens/about_screen.dart** (8 classes)
  - Split into separate widgets
- [ ] **lib/features/settings/screens/change_password_screen.dart** (8 classes)
  - Split into separate widgets

#### Other Features
- [ ] All files with "_failure.dart" suffix (6 classes each)
  - These are typically sealed classes with subtypes
  - Review if they should be split or kept together

### 2. Rename Files (Remove Suffixes)

#### Screens (remove _screen suffix)
```bash
# Example renames needed in /screens/ folders:
feed_screen.dart → feed.dart
login_screen.dart → login.dart
profile_screen.dart → profile.dart
settings_screen.dart → settings.dart
# ... etc for all screens
```

#### Widgets (remove _widget suffix if any)
- [ ] Review all widgets for unnecessary suffixes

### 3. Update Imports

After file splits and renames:
```bash
cd lib
./update_imports_helper.sh
```

Then manually fix any remaining import errors:
- [ ] Run `flutter analyze` to find broken imports
- [ ] Update all import paths to match new structure
- [ ] Remove references to old data/domain/application folders

### 4. Delete Old Structure

⚠️ **ONLY AFTER ALL IMPORTS ARE FIXED**

```bash
# Delete old architecture folders
rm -rf lib/features/*/domain
rm -rf lib/features/*/data
rm -rf lib/features/*/application
rm -rf lib/features/*/presentation
```

### 5. Generate Code

```bash
# Regenerate freezed and json_serializable files
dart run build_runner build --delete-conflicting-outputs
```

### 6. Verify

- [ ] `flutter analyze` shows 0 errors
- [ ] `dart format .` applied
- [ ] `flutter test` passes (if you have tests)
- [ ] App runs without errors
- [ ] All navigation works
- [ ] No duplicate class definitions

## 📋 File Naming Conventions

### ✅ CORRECT
```
user.dart            (model)
auth_provider.dart   (provider)
login.dart          (screen)
user_card.dart      (widget)
```

### ❌ INCORRECT
```
user_model.dart
auth_state_provider.dart
login_screen.dart
user_card_widget.dart
```

## 🗂️ Final Structure

```
lib/
├── features/
│   ├── posts/
│   │   ├── models/           # All freezed models
│   │   ├── providers/        # Riverpod providers
│   │   ├── screens/          # Screen widgets
│   │   └── widgets/          # Feature widgets
│   ├── authentication/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   └── [other features]/
├── shared/
│   ├── models/
│   ├── widgets/
│   ├── utils/
│   └── extensions/
├── core/
│   ├── config/
│   ├── constants/
│   ├── theme/
│   ├── router/
│   ├── network/
│   └── utils/
└── main.dart
```

## 🚨 Common Pitfalls

1. **Don't forget to update part directives** in freezed files
2. **Export files** - Create barrel exports where needed
3. **Circular dependencies** - Watch out when splitting files
4. **Generated files** - Don't forget to regenerate after moving

## 📞 Questions?

Review CLAUDE.md for complete Flutter architecture rules.

---
**Created:** $(date)
**Backup Location:** See console output for backup path
