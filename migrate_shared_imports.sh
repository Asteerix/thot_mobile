#!/bin/bash
# Migration automatique des imports /shared
# Date: 2025-11-12

cd "$(dirname "$0")/lib"

echo "🔄 Migration des imports /shared en cours..."
echo ""

# Loading widgets
echo "📦 Loading widgets..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/loading_indicator\.dart|shared/widgets/loading/loading_indicator.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/shimmer_loading\.dart|shared/widgets/loading/shimmer_loading.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/upload_progress_dialog\.dart|shared/widgets/loading/upload_progress_dialog.dart|g' {} +

# Empty states
echo "📭 Empty states..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/empty_state\.dart|shared/widgets/empty/empty_state.dart|g' {} +

# Errors
echo "❌ Error views..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/error_view\.dart|shared/widgets/errors/error_view.dart|g' {} +

# Connectivity
echo "🌐 Connectivity..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/connection_status_indicator\.dart|shared/widgets/connectivity/connection_status_indicator.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/connectivity_indicator\.dart|shared/widgets/connectivity/connectivity_indicator.dart|g' {} +

# Images
echo "🖼️ Images..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/app_avatar\.dart|shared/widgets/images/app_avatar.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/cached_network_image_widget\.dart|shared/widgets/images/cached_network_image_widget.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/safe_network_image\.dart|shared/widgets/images/safe_network_image.dart|g' {} +

# Branding
echo "🎨 Branding..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/logo\.dart|shared/widgets/branding/logo.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/logo_white\.dart|shared/widgets/branding/logo_white.dart|g' {} +

# Layouts
echo "📐 Layouts..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/app_header\.dart|shared/widgets/layouts/app_header.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/app_scaffold\.dart|shared/widgets/layouts/app_scaffold.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/screens/creation_screen_layout\.dart|shared/widgets/layouts/creation_screen_layout.dart|g' {} +

# Navigation
echo "🧭 Navigation..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/bottom_nav_bar\.dart|shared/widgets/navigation/bottom_nav_bar.dart|g' {} +

# Delegates
echo "📜 Delegates..."
find . -type f -name "*.dart" -exec sed -i '' \
  's|shared/widgets/common/filters_header_delegate\.dart|shared/widgets/delegates/filters_header_delegate.dart|g' {} +

echo ""
echo "✅ Migration terminée!"
echo ""
echo "Prochaines étapes:"
echo "1. flutter analyze --no-pub"
echo "2. dart format lib/"
echo "3. Tester l'app"
