# Guide de Migration - Nouveaux Chemins /shared

**Date**: 2025-11-12

## 🔄 Rechercher/Remplacer Global

### Widgets - Common (disparu)

```bash
# Loading
shared/widgets/common/loading_indicator.dart → shared/widgets/loading/loading_indicator.dart
shared/widgets/common/shimmer_loading.dart → shared/widgets/loading/shimmer_loading.dart
shared/widgets/common/upload_progress_dialog.dart → shared/widgets/loading/upload_progress_dialog.dart

# Empty States
shared/widgets/common/empty_state.dart → shared/widgets/empty/empty_state.dart

# Errors
shared/widgets/common/error_view.dart → shared/widgets/errors/error_view.dart

# Connectivity
shared/widgets/common/connection_status_indicator.dart → shared/widgets/connectivity/connection_status_indicator.dart

# Images
shared/widgets/common/app_avatar.dart → shared/widgets/images/app_avatar.dart
shared/widgets/common/cached_network_image_widget.dart → shared/widgets/images/cached_network_image_widget.dart

# Headers & Layouts
shared/widgets/common/app_header.dart → shared/widgets/layouts/app_header.dart

# Delegates
shared/widgets/common/filters_header_delegate.dart → shared/widgets/delegates/filters_header_delegate.dart
```

### Widgets - Root Level (déplacés)

```bash
# Logos
shared/widgets/logo.dart → shared/widgets/branding/logo.dart
shared/widgets/logo_white.dart → shared/widgets/branding/logo_white.dart

# Connectivity
shared/widgets/connectivity_indicator.dart → shared/widgets/connectivity/connectivity_indicator.dart

# Images
shared/widgets/safe_network_image.dart → shared/widgets/images/safe_network_image.dart

# Layouts
shared/widgets/app_scaffold.dart → shared/widgets/layouts/app_scaffold.dart
shared/widgets/screens/creation_screen_layout.dart → shared/widgets/layouts/creation_screen_layout.dart

# Navigation
shared/widgets/bottom_nav_bar.dart → shared/widgets/navigation/bottom_nav_bar.dart
```

## 🛠️ Scripts de Migration Automatique

### Option 1: Rechercher/Remplacer dans IDE
Utilisez ces patterns dans VS Code / Android Studio (Regex activé):

```regex
# Pattern de recherche
shared/widgets/common/(loading_indicator|shimmer_loading|upload_progress_dialog)\.dart

# Remplacement
shared/widgets/loading/$1.dart
```

### Option 2: Script Shell

```bash
#!/bin/bash
# migration_imports.sh

cd lib

# Loading widgets
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/loading_indicator\.dart|shared/widgets/loading/loading_indicator.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/shimmer_loading\.dart|shared/widgets/loading/shimmer_loading.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/upload_progress_dialog\.dart|shared/widgets/loading/upload_progress_dialog.dart|g' {} +

# Empty
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/empty_state\.dart|shared/widgets/empty/empty_state.dart|g' {} +

# Errors
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/error_view\.dart|shared/widgets/errors/error_view.dart|g' {} +

# Connectivity
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/connection_status_indicator\.dart|shared/widgets/connectivity/connection_status_indicator.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/connectivity_indicator\.dart|shared/widgets/connectivity/connectivity_indicator.dart|g' {} +

# Images
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/app_avatar\.dart|shared/widgets/images/app_avatar.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/cached_network_image_widget\.dart|shared/widgets/images/cached_network_image_widget.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/safe_network_image\.dart|shared/widgets/images/safe_network_image.dart|g' {} +

# Branding
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/logo\.dart|shared/widgets/branding/logo.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/logo_white\.dart|shared/widgets/branding/logo_white.dart|g' {} +

# Layouts
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/app_header\.dart|shared/widgets/layouts/app_header.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/app_scaffold\.dart|shared/widgets/layouts/app_scaffold.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/screens/creation_screen_layout\.dart|shared/widgets/layouts/creation_screen_layout.dart|g' {} +

# Navigation
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/bottom_nav_bar\.dart|shared/widgets/navigation/bottom_nav_bar.dart|g' {} +

# Delegates
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/filters_header_delegate\.dart|shared/widgets/delegates/filters_header_delegate.dart|g' {} +

echo "✅ Migration terminée"
```

### Option 3: Migration Manuel par Fichier

Nombre approximatif d'imports à mettre à jour:
- `loading_indicator.dart`: ~5 fichiers
- `empty_state.dart`: ~14 fichiers
- `app_header.dart`: ~5 fichiers
- `connection_status_indicator.dart`: ~7 fichiers
- `safe_network_image.dart`: ~7 fichiers
- Etc.

**TOTAL estimé**: ~60-80 imports à corriger

## ✅ Vérification Post-Migration

```bash
# Vérifier qu'aucun ancien chemin ne reste
cd lib
grep -r "shared/widgets/common/" . --include="*.dart" | wc -l  # Devrait retourner 0
grep -r "shared/widgets/screens/" . --include="*.dart" | wc -l  # Devrait retourner 0
grep -r "shared/widgets/forms/" . --include="*.dart" | wc -l   # Devrait retourner 0

# Vérifier l'analyse statique
flutter analyze --no-pub

# Formater le code
dart format lib/
```

## 📋 Checklist

- [ ] Exécuter le script de migration OU remplacer manuellement
- [ ] Vérifier `flutter analyze` (0 erreurs de path)
- [ ] Tester l'app (compilation + lancement)
- [ ] Commit avec message clair: "refactor(shared): reorganize by function"
