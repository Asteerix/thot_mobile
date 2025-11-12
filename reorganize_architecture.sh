#!/bin/bash

# =============================================================================
# THOT MOBILE - Architecture Reorganization Script
# =============================================================================
# This script reorganizes the Flutter project according to CLAUDE.md rules:
# 1. ONE FILE = ONE CLASS (split multi-class files)
# 2. NO data/domain/application folders (simple feature-based structure)
# 3. Clear, concise file names (no _screen, _widget suffixes)
# 4. Proper feature organization
# =============================================================================

set -e  # Exit on error

PROJECT_ROOT="/Users/amaury/Desktop/backup/thot/thot_mobile"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   THOT MOBILE - Architecture Reorganization${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# =============================================================================
# Step 1: Create backup
# =============================================================================
echo -e "${YELLOW}[1/7] Creating backup...${NC}"
BACKUP_DIR="$PROJECT_ROOT/backup_before_reorganization_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/"
echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}"
echo ""

# =============================================================================
# Step 2: Create new directory structure
# =============================================================================
echo -e "${YELLOW}[2/7] Creating new directory structure...${NC}"

create_feature_structure() {
    local feature=$1
    local base="lib/features/$feature"

    mkdir -p "$base/models"
    mkdir -p "$base/providers"
    mkdir -p "$base/screens"
    mkdir -p "$base/widgets"

    echo -e "${GREEN}  ✓ Created structure for: $feature${NC}"
}

# Create structure for all features
for feature in admin authentication comments media notifications posts profile search settings; do
    create_feature_structure "$feature"
done

# Create shared structure
mkdir -p lib/shared/models
mkdir -p lib/shared/providers
mkdir -p lib/shared/widgets
mkdir -p lib/shared/utils
mkdir -p lib/shared/extensions

# Core structure remains mostly the same
mkdir -p lib/core/config
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/router
mkdir -p lib/core/network
mkdir -p lib/core/storage
mkdir -p lib/core/utils

echo -e "${GREEN}✓ New directory structure created${NC}"
echo ""

# =============================================================================
# Step 3: Move and split POSTS feature (the biggest)
# =============================================================================
echo -e "${YELLOW}[3/7] Reorganizing POSTS feature...${NC}"

# MODELS - Split post.dart (11 classes!)
echo -e "${BLUE}  → Splitting post models...${NC}"
cat > lib/features/posts/models/post_type.dart << 'EOF'
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
EOF

cat > lib/features/posts/models/content_status.dart << 'EOF'
enum ContentStatus { draft, published, archived, hidden, deleted }
EOF

cat > lib/features/posts/models/political_orientation.dart << 'EOF'
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum PoliticalOrientation {
  extremelyConservative,
  conservative,
  neutral,
  progressive,
  extremelyProgressive
}
EOF

cat > lib/features/posts/models/post_domain.dart << 'EOF'
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
      case PostDomain.science:
        return 'science';
      case PostDomain.international:
        return 'international';
      case PostDomain.juridique:
        return 'juridique';
      case PostDomain.philosophie:
        return 'philosophie';
      case PostDomain.societe:
        return 'societe';
      case PostDomain.psychologie:
        return 'psychologie';
      case PostDomain.sport:
        return 'sport';
      case PostDomain.technologie:
        return 'technologie';
    }
  }

  String get displayName {
    switch (this) {
      case PostDomain.politique:
        return 'Politique';
      case PostDomain.economie:
        return 'Economie';
      case PostDomain.science:
        return 'Science';
      case PostDomain.international:
        return 'International';
      case PostDomain.juridique:
        return 'Juridique';
      case PostDomain.philosophie:
        return 'Philosophie';
      case PostDomain.societe:
        return 'Société';
      case PostDomain.psychologie:
        return 'Psychologie';
      case PostDomain.sport:
        return 'Sport';
      case PostDomain.technologie:
        return 'Technologie';
    }
  }
}
EOF

# Note: We'll need to manually split the actual Post class and related classes
# This script creates the structure; manual intervention needed for complex classes

echo -e "${BLUE}  → Moving post providers...${NC}"
if [ -f "lib/features/posts/application/providers/posts_provider.dart" ]; then
    cp lib/features/posts/application/providers/posts_provider.dart lib/features/posts/providers/
fi
if [ -f "lib/features/posts/application/providers/posts_state_provider.dart" ]; then
    cp lib/features/posts/application/providers/posts_state_provider.dart lib/features/posts/providers/
fi

echo -e "${BLUE}  → Moving post screens...${NC}"
if [ -d "lib/features/posts/presentation/mobile/screens" ]; then
    # Copy all screens, removing _screen suffix later
    for screen in lib/features/posts/presentation/mobile/screens/*.dart; do
        if [ -f "$screen" ]; then
            cp "$screen" lib/features/posts/screens/
        fi
    done
fi

echo -e "${BLUE}  → Moving post widgets...${NC}"
if [ -d "lib/features/posts/presentation/shared/widgets" ]; then
    for widget in lib/features/posts/presentation/shared/widgets/*.dart; do
        if [ -f "$widget" ]; then
            cp "$widget" lib/features/posts/widgets/
        fi
    done
fi

echo -e "${GREEN}  ✓ Posts feature reorganized${NC}"

# =============================================================================
# Step 4: Move and reorganize AUTHENTICATION feature
# =============================================================================
echo -e "${YELLOW}[4/7] Reorganizing AUTHENTICATION feature...${NC}"

# Models
if [ -f "lib/features/authentication/domain/entities/user.dart" ]; then
    cp lib/features/authentication/domain/entities/user.dart lib/features/authentication/models/
fi
if [ -f "lib/features/authentication/data/models/auth_dto.dart" ]; then
    cp lib/features/authentication/data/models/auth_dto.dart lib/features/authentication/models/
fi

# Providers
if [ -f "lib/features/authentication/application/providers/auth_provider.dart" ]; then
    cp lib/features/authentication/application/providers/auth_provider.dart lib/features/authentication/providers/
fi

# Screens
if [ -d "lib/features/authentication/presentation/mobile/screens" ]; then
    for screen in lib/features/authentication/presentation/mobile/screens/*.dart; do
        if [ -f "$screen" ]; then
            cp "$screen" lib/features/authentication/screens/
        fi
    done
fi

# Widgets
if [ -d "lib/features/authentication/presentation/shared/widgets" ]; then
    for widget in lib/features/authentication/presentation/shared/widgets/*.dart; do
        if [ -f "$widget" ]; then
            cp "$widget" lib/features/authentication/widgets/
        fi
    done
fi

echo -e "${GREEN}  ✓ Authentication feature reorganized${NC}"

# =============================================================================
# Step 5: Move and reorganize OTHER features
# =============================================================================
echo -e "${YELLOW}[5/7] Reorganizing remaining features...${NC}"

reorganize_feature() {
    local feature=$1
    echo -e "${BLUE}  → Processing $feature...${NC}"

    # Models (from domain/entities and data/models)
    if [ -d "lib/features/$feature/domain/entities" ]; then
        find "lib/features/$feature/domain/entities" -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" -exec cp {} "lib/features/$feature/models/" \;
    fi
    if [ -d "lib/features/$feature/data/models" ]; then
        find "lib/features/$feature/data/models" -name "*.dart" -exec cp {} "lib/features/$feature/models/" \;
    fi

    # Providers (from application/providers)
    if [ -d "lib/features/$feature/application/providers" ]; then
        find "lib/features/$feature/application/providers" -name "*.dart" -exec cp {} "lib/features/$feature/providers/" \;
    fi

    # Screens
    if [ -d "lib/features/$feature/presentation/mobile/screens" ]; then
        find "lib/features/$feature/presentation/mobile/screens" -name "*.dart" -exec cp {} "lib/features/$feature/screens/" \;
    fi

    # Widgets
    if [ -d "lib/features/$feature/presentation/shared/widgets" ]; then
        find "lib/features/$feature/presentation/shared/widgets" -name "*.dart" -exec cp {} "lib/features/$feature/widgets/" \;
    fi
}

for feature in comments media notifications profile search settings admin; do
    reorganize_feature "$feature"
done

echo -e "${GREEN}✓ All features reorganized${NC}"
echo ""

# =============================================================================
# Step 6: Update imports (basic regex-based replacement)
# =============================================================================
echo -e "${YELLOW}[6/7] Updating imports...${NC}"

echo -e "${BLUE}  → This step requires manual review${NC}"
echo -e "${BLUE}  → Key import changes needed:${NC}"
echo -e "${BLUE}    • domain/entities/* → models/*${NC}"
echo -e "${BLUE}    • application/providers/* → providers/*${NC}"
echo -e "${BLUE}    • presentation/mobile/screens/* → screens/*${NC}"
echo -e "${BLUE}    • presentation/shared/widgets/* → widgets/*${NC}"

# Create a helper script for import updates
cat > lib/update_imports_helper.sh << 'HELPER_EOF'
#!/bin/bash
# Helper to update imports - run this after manual file cleanup

find lib/features -name "*.dart" -type f -exec sed -i '' \
  -e 's|/domain/entities/|/models/|g' \
  -e 's|/data/models/|/models/|g' \
  -e 's|/application/providers/|/providers/|g' \
  -e 's|/presentation/mobile/screens/|/screens/|g' \
  -e 's|/presentation/shared/widgets/|/widgets/|g' \
  {} \;

echo "Import paths updated!"
HELPER_EOF

chmod +x lib/update_imports_helper.sh

echo -e "${GREEN}  ✓ Import update helper created: lib/update_imports_helper.sh${NC}"
echo ""

# =============================================================================
# Step 7: Create TODO file for manual steps
# =============================================================================
echo -e "${YELLOW}[7/7] Creating manual steps TODO...${NC}"

cat > REORGANIZATION_TODO.md << 'TODO_EOF'
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
TODO_EOF

echo -e "${GREEN}✓ Manual steps TODO created: REORGANIZATION_TODO.md${NC}"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SCRIPT COMPLETED SUCCESSFULLY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}SUMMARY:${NC}"
echo -e "  • Backup created at: ${BACKUP_DIR}"
echo -e "  • New structure created in: lib/features/"
echo -e "  • Files copied to new locations"
echo -e "  • Basic enum splits created"
echo ""
echo -e "${RED}⚠️  NEXT STEPS (MANUAL):${NC}"
echo -e "  1. Read ${YELLOW}REORGANIZATION_TODO.md${NC} carefully"
echo -e "  2. Split multi-class files (CRITICAL!)"
echo -e "  3. Rename files to remove suffixes"
echo -e "  4. Run ${YELLOW}lib/update_imports_helper.sh${NC}"
echo -e "  5. Fix remaining imports manually"
echo -e "  6. Delete old structure (domain/data/application folders)"
echo -e "  7. Run: ${YELLOW}dart run build_runner build --delete-conflicting-outputs${NC}"
echo -e "  8. Run: ${YELLOW}flutter analyze${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create a quick stats file
echo "Architecture Reorganization Statistics" > reorganization_stats.txt
echo "======================================" >> reorganization_stats.txt
echo "" >> reorganization_stats.txt
echo "Files with multiple classes found:" >> reorganization_stats.txt
find lib/features -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" -exec sh -c '
    count=$(grep -cE "^(class|abstract class|enum) " "$1" 2>/dev/null || echo 0)
    if [ "$count" -gt 1 ]; then
        echo "  $1: $count classes"
    fi
' _ {} \; >> reorganization_stats.txt 2>/dev/null

echo -e "${GREEN}✓ Statistics saved to: reorganization_stats.txt${NC}"
echo ""
