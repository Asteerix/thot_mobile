# Architecture Reorganization - Quick Reference Card

## 🚀 Getting Started

### 1. Execute Script
```bash
cd /Users/amaury/Desktop/backup/thot/thot_mobile
./reorganize_architecture.sh
```

### 2. Read Generated Docs
- `REORGANIZATION_TODO.md` - Step-by-step manual tasks
- `ARCHITECTURE_ANALYSIS.md` - Complete analysis
- `FILE_SPLIT_EXAMPLES.md` - Code examples
- `reorganization_stats.txt` - Statistics

---

## 📋 Critical Multi-Class Files to Split

### PRIORITY 1 (Must split immediately)
```
lib/features/posts/domain/entities/post_metadata.dart       [16 classes] 🔴
lib/features/posts/domain/entities/post.dart                [11 classes] 🔴
lib/features/posts/presentation/shared/widgets/feed_filters.dart [10 classes] 🔴
```

### PRIORITY 2 (Split next)
```
lib/features/settings/presentation/mobile/screens/about_screen.dart              [8 classes]
lib/features/settings/presentation/mobile/screens/change_password_screen.dart    [8 classes]
lib/features/posts/data/repositories/post_repository_impl.dart                   [8 classes]
lib/features/settings/presentation/mobile/screens/settings_screen.dart           [6 classes]
lib/features/posts/presentation/shared/widgets/interaction_buttons.dart          [5 classes]
```

### PRIORITY 3 (Review if needed)
All `*_failure.dart` files with 6 classes (sealed class pattern - may keep together)

---

## 🎯 Directory Structure Cheat Sheet

### ❌ OLD (Delete after migration)
```
features/[feature]/
  ├── data/              ← DELETE
  ├── domain/            ← DELETE
  ├── application/       ← DELETE
  └── presentation/      ← DELETE
```

### ✅ NEW (Target structure)
```
features/[feature]/
  ├── models/           # Freezed models, enums
  ├── providers/        # Riverpod providers
  ├── screens/          # Screen widgets (no _screen suffix)
  └── widgets/          # Feature widgets (no _widget suffix)
```

---

## 🔧 Common Commands

### Update imports (after file moves)
```bash
cd lib
./update_imports_helper.sh
```

### Regenerate freezed/json files
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Check for errors
```bash
flutter analyze
```

### Format code
```bash
dart format .
```

### Find multi-class files
```bash
find lib/features -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" \
  -exec sh -c 'count=$(grep -cE "^(class|abstract class|enum) " "$1"); \
  if [ "$count" -gt 1 ]; then echo "$1: $count"; fi' _ {} \;
```

---

## 📝 File Naming Rules

### ✅ CORRECT
| Type | File Name | Class Name |
|------|-----------|------------|
| Model | `post.dart` | `class Post` |
| Enum | `post_type.dart` | `enum PostType` |
| Screen | `feed.dart` | `class FeedScreen` |
| Widget | `user_card.dart` | `class UserCard` |
| Provider | `auth_provider.dart` | `final authProvider` |

### ❌ WRONG
| ❌ Don't Use | ✅ Use Instead |
|-------------|---------------|
| `post_model.dart` | `post.dart` |
| `feed_screen.dart` | `feed.dart` |
| `user_card_widget.dart` | `user_card.dart` |
| `post_type_enum.dart` | `post_type.dart` |

---

## 🔄 Import Path Changes

### Before → After

```dart
// OLD domain/entities
import 'package:thot/features/posts/domain/entities/post.dart';
// NEW models
import 'package:thot/features/posts/models/post.dart';

// OLD application/providers
import 'package:thot/features/posts/application/providers/posts_provider.dart';
// NEW providers
import 'package:thot/features/posts/providers/posts_provider.dart';

// OLD presentation/mobile/screens
import 'package:thot/features/posts/presentation/mobile/screens/feed_screen.dart';
// NEW screens
import 'package:thot/features/posts/screens/feed.dart';

// OLD presentation/shared/widgets
import 'package:thot/features/posts/presentation/shared/widgets/post_card.dart';
// NEW widgets
import 'package:thot/features/posts/widgets/post_card.dart';
```

---

## ✂️ File Splitting Quick Guide

### 1. Identify classes in file
```bash
grep -E "^(class|abstract class|enum)" file.dart
```

### 2. Create new files
One file per class, named after the class (snake_case)

### 3. Move class + dependencies
- Include necessary imports
- Keep class and its methods together

### 4. Update original file
- Add imports to new files
- Remove moved classes

### 5. Update all imports
```bash
cd lib && ./update_imports_helper.sh
```

---

## 🐛 Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| Duplicate class | Class in old & new location | Delete old structure AFTER imports fixed |
| Cannot find import | Path not updated | Run `flutter analyze`, update manually |
| Part directive error | Freezed looking in wrong place | Run `build_runner clean` then `build_runner build` |
| Circular dependency | Files reference each other | Create common base file or restructure |

---

## ✅ Verification Checklist

After reorganization:

```bash
# 1. No errors
flutter analyze
# Expected: 0 errors

# 2. Code formatted
dart format .
# Expected: All files formatted

# 3. Tests pass (if you have tests)
flutter test
# Expected: All tests pass

# 4. App runs
flutter run
# Expected: App launches without errors

# 5. No duplicate classes
grep -r "^class Post " lib/
# Expected: Only ONE match per class

# 6. Old structure deleted
ls lib/features/posts/
# Expected: Only models/, providers/, screens/, widgets/
# NOT: data/, domain/, application/, presentation/
```

---

## 📊 Progress Tracking

Track your progress splitting files:

```
Posts Feature:
  [ ] post_metadata.dart split (16 → 16 files)
  [ ] post.dart split (11 → 11 files)
  [ ] question.dart split (3 → 3 files)
  [ ] feed_filters.dart split (10 → 10 files)
  [ ] interaction_buttons.dart split (5 → 5 files)
  [ ] All screen files renamed (remove _screen)
  [ ] Imports updated
  [ ] build_runner executed
  [ ] Tests pass

Settings Feature:
  [ ] about_screen.dart split
  [ ] change_password_screen.dart split
  [ ] settings_screen.dart split
  [ ] All screen files renamed
  [ ] Imports updated

... repeat for other features ...

Final Steps:
  [ ] Delete old structure (data/, domain/, application/, presentation/)
  [ ] Run flutter analyze (0 errors)
  [ ] Run dart format .
  [ ] Commit changes
  [ ] Create PR
```

---

## 💡 Tips

1. **Start small**: Split one file, test, commit, repeat
2. **Use IDE refactoring**: Right-click → Refactor → Move to file
3. **Test frequently**: Run `flutter analyze` after each major change
4. **Keep backup**: The script creates a backup automatically
5. **Read examples**: Check `FILE_SPLIT_EXAMPLES.md` for patterns
6. **One feature at a time**: Complete posts, then auth, then others
7. **Commit often**: Small commits are easier to review/revert

---

## 📞 Help

- Full analysis: `ARCHITECTURE_ANALYSIS.md`
- Code examples: `FILE_SPLIT_EXAMPLES.md`
- Manual steps: `REORGANIZATION_TODO.md`
- Stats: `reorganization_stats.txt`
- CLAUDE.md rules: See project root

---

## 🎯 Success Criteria

**Definition of Done:**
- ✅ All files have ≤ 1 public class (except sealed classes)
- ✅ No data/domain/application/presentation folders
- ✅ All files follow naming convention (no _screen, _widget suffixes)
- ✅ `flutter analyze` shows 0 errors
- ✅ All imports use new structure
- ✅ App runs on iOS and Android
- ✅ Code is formatted (`dart format .`)

---

**Estimated Time:** 4-6 hours
**Difficulty:** Medium
**Risk:** Low (backup created, incremental approach)

---

*Quick reference for architecture reorganization*
*Keep this open while working through the migration*
