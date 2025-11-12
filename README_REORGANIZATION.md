# 🏗️ Architecture Reorganization Guide

> **IMPORTANT:** This project needs architecture reorganization to comply with CLAUDE.md Flutter rules.

---

## 🚀 Quick Start

```bash
# Run this script to begin:
./reorganize_architecture.sh
```

**Time Required:** 4-6 hours
**Difficulty:** Medium
**Risk:** Low (automatic backup created)

---

## 📚 Documentation

All documentation has been generated and is ready to use:

### 🎯 Start Here
| Document | Purpose | When to Read |
|----------|---------|-------------|
| **[REORGANIZATION_SUMMARY.md](./REORGANIZATION_SUMMARY.md)** | Executive overview | Read FIRST |
| **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** | Commands & cheat sheet | Keep open while working |

### 📖 Detailed Guides
| Document | Purpose | When to Read |
|----------|---------|-------------|
| **[ARCHITECTURE_ANALYSIS.md](./ARCHITECTURE_ANALYSIS.md)** | Complete analysis | For deep understanding |
| **[FILE_SPLIT_EXAMPLES.md](./FILE_SPLIT_EXAMPLES.md)** | Code examples | When splitting files |

### ✅ Generated During Script
| Document | Purpose | When Created |
|----------|---------|-------------|
| **REORGANIZATION_TODO.md** | Step-by-step checklist | After running script |
| **reorganization_stats.txt** | Statistics | After running script |

---

## 🎯 What's Wrong Now?

### Critical Issues

1. **Multiple Classes Per File** 🔴
   - Worst case: `post_metadata.dart` has **16 classes**
   - Total violations: **50+ files**
   - Violates: CLAUDE.md Rule #41

2. **Wrong Architecture Pattern** 🔴
   ```
   ❌ Current: data/domain/application/presentation
   ✅ Target: models/providers/screens/widgets
   ```

3. **Incorrect File Naming** 🟡
   ```
   ❌ feed_screen.dart
   ✅ feed.dart
   ```

---

## ✨ What Will Be Fixed?

### After Reorganization

✅ **One file = One class** (except sealed classes)
✅ **Simple feature structure** (no data/domain/application layers)
✅ **Clean file names** (no _screen, _widget suffixes)
✅ **100% CLAUDE.md compliant**

### Architecture Transformation

```
BEFORE (Wrong ❌)                  AFTER (Correct ✅)
features/                          features/
  posts/                             posts/
    ├── data/                          ├── models/      (Freezed models)
    ├── domain/                        ├── providers/   (Riverpod)
    ├── application/                   ├── screens/     (no suffix)
    └── presentation/                  └── widgets/     (no suffix)
```

---

## 📋 Process Overview

### Automated (Script Does This)
✅ Creates backup
✅ Creates new directory structure
✅ Copies files to new locations
✅ Splits basic enums
✅ Generates TODO checklist

### Manual (You Do This)
⚠️ Split multi-class files (most important!)
⚠️ Rename files (remove suffixes)
⚠️ Update imports
⚠️ Delete old structure
⚠️ Verify everything works

---

## 🎓 Key Rules to Follow

### From CLAUDE.md

1. **ONE FILE = ONE CLASS** ⭐⭐⭐
   ```dart
   // ❌ WRONG: multiple classes in one file
   // post.dart
   enum PostType { ... }
   class PostStats { ... }
   class Post { ... }

   // ✅ CORRECT: separate files
   // post_type.dart
   enum PostType { ... }

   // post_stats.dart
   class PostStats { ... }

   // post.dart
   class Post { ... }
   ```

2. **No data/domain/application folders**
   ```
   ❌ features/posts/domain/entities/
   ✅ features/posts/models/
   ```

3. **No suffixes in file names**
   ```
   ❌ feed_screen.dart
   ✅ feed.dart
   ```

---

## 🔧 Tools Provided

### Main Script
```bash
./reorganize_architecture.sh
```
- Automated restructuring
- Creates backup
- Generates checklists

### Import Updater
```bash
cd lib
./update_imports_helper.sh
```
- Semi-automates import updates
- Run after file moves

### Analysis Commands
```bash
# Find multi-class files
find lib/features -name "*.dart" -not -name "*.g.dart" \
  -not -name "*.freezed.dart" -exec sh -c \
  'grep -cE "^(class|enum) " "$1" || echo 0' _ {} \;

# Check for errors
flutter analyze

# Format code
dart format .
```

---

## 📊 Impact

### Files Affected
- **~300 Dart files** will be reorganized
- **~50 files** need splitting
- **~300 imports** need updating

### Estimated Time
- **Script execution:** 5 minutes
- **Manual work:** 4-6 hours
- **Testing:** 30 minutes

### Risk Assessment
🟢 **Low Risk**
- Automatic backup created
- No data loss
- Incremental approach possible
- Comprehensive documentation

---

## ✅ Success Checklist

After reorganization, verify:

```bash
# 1. No errors
flutter analyze
# Expected: 0 errors

# 2. Formatted
dart format .

# 3. App runs
flutter run

# 4. One class per file
# Check manually or use grep

# 5. Old structure deleted
ls lib/features/posts/
# Should NOT contain: data/, domain/, application/, presentation/
```

---

## 🎯 Next Steps

### 1. Read Documentation (10 min)
- [ ] Read **[REORGANIZATION_SUMMARY.md](./REORGANIZATION_SUMMARY.md)**
- [ ] Skim **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)**
- [ ] Have **[FILE_SPLIT_EXAMPLES.md](./FILE_SPLIT_EXAMPLES.md)** ready

### 2. Execute Script (5 min)
```bash
./reorganize_architecture.sh
```

### 3. Follow Manual Steps (4-6 hours)
- [ ] Read generated **REORGANIZATION_TODO.md**
- [ ] Split multi-class files (see examples)
- [ ] Rename files (remove suffixes)
- [ ] Update imports (semi-automatic)
- [ ] Clean up old structure
- [ ] Verify with `flutter analyze`

### 4. Commit & Review
```bash
git add .
git commit -m "feat: Reorganize architecture to comply with CLAUDE.md rules

- Split 50+ multi-class files into single-class files
- Simplified architecture: removed data/domain/application layers
- Renamed files: removed _screen and _widget suffixes
- Updated all imports to new structure
- 100% CLAUDE.md compliant

See REORGANIZATION_SUMMARY.md for details"
```

---

## 🆘 Need Help?

### Documentation
- **Summary:** [REORGANIZATION_SUMMARY.md](./REORGANIZATION_SUMMARY.md)
- **Quick Reference:** [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- **Analysis:** [ARCHITECTURE_ANALYSIS.md](./ARCHITECTURE_ANALYSIS.md)
- **Examples:** [FILE_SPLIT_EXAMPLES.md](./FILE_SPLIT_EXAMPLES.md)

### Common Issues
See **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** → Troubleshooting section

### CLAUDE.md Rules
Check your project root for `CLAUDE.md` → Flutter section

---

## 📈 Benefits

### After Completion

✅ **Cleaner Codebase**
- One file = one class (no mental overhead)
- Clear feature boundaries
- Easier navigation

✅ **Better Maintainability**
- Simpler architecture
- Less boilerplate
- Easier to add features

✅ **Improved Performance**
- Faster builds (better caching)
- Better tree-shaking
- Faster IDE indexing

✅ **Team Benefits**
- Easier code reviews
- Better collaboration
- Consistent patterns

---

## 🎉 Ready?

### Before You Start
- [ ] Git status is clean
- [ ] You have 4-6 hours available
- [ ] You've read the summary document
- [ ] Scripts are executable

### Execute
```bash
./reorganize_architecture.sh
```

### Then
Follow the generated **REORGANIZATION_TODO.md** step by step.

---

## 📝 Notes

- **Backup Location:** Automatically created with timestamp
- **Reversible:** Keep backup until verified
- **Safe:** No files deleted by script
- **Comprehensive:** All tools and docs provided

---

**Status:** ✅ Ready to Execute
**Last Updated:** 2025-11-12
**Version:** 1.0

---

*Transform your codebase to be cleaner, simpler, and 100% compliant with best practices! 🚀*
