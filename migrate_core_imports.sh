#!/bin/bash
cd "$(dirname "$0")/lib"

echo "🔄 Migration des imports /core en cours..."

# Config
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/api_routes\.dart|core/config/api_routes.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/app_config\.dart|core/config/app_config.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/app_constants\.dart|core/config/app_config.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/asset_paths\.dart|core/config/asset_paths.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/spacing_constants\.dart|core/config/spacing_constants.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/timeago_config\.dart|core/config/timeago_config.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/constants/validation_constants\.dart|core/config/validation_constants.dart|g' {} +

# Routing
find . -type f -name "*.dart" -exec sed -i '' 's|core/navigation/app_router\.dart|core/routing/app_router.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/navigation/route_names\.dart|core/routing/route_names.dart|g' {} +

# Services - Network
find . -type f -name "*.dart" -exec sed -i '' 's|core/network/api_client\.dart|core/services/network/api_client.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/network/api_config\.dart|core/services/network/api_config.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/network/interceptors/auth_interceptor\.dart|core/services/network/auth_interceptor.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/network/interceptors/retry_interceptor\.dart|core/services/network/retry_interceptor.dart|g' {} +

# Services - Connectivity
find . -type f -name "*.dart" -exec sed -i '' 's|core/connectivity/connectivity_service\.dart|core/services/connectivity/connectivity_service.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/connectivity/connectivity_service_factory\.dart|core/services/connectivity/connectivity_service_factory.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/connectivity/connectivity_service_base\.dart|core/services/connectivity/connectivity_service_base.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/connectivity/connectivity_service_io\.dart|core/services/connectivity/connectivity_service_io.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/connectivity/connectivity_service_web\.dart|core/services/connectivity/connectivity_service_web.dart|g' {} +

# Services - Storage
find . -type f -name "*.dart" -exec sed -i '' 's|core/storage/token_service\.dart|core/services/storage/token_service.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/storage/offline_cache_service\.dart|core/services/storage/offline_cache_service.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/storage/search_history_service\.dart|core/services/storage/search_history_service.dart|g' {} +

# Services - Logging & Realtime
find . -type f -name "*.dart" -exec sed -i '' 's|core/monitoring/logger_service\.dart|core/services/logging/logger_service.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/realtime/event_bus\.dart|core/services/realtime/event_bus.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/realtime/socket_service\.dart|core/services/realtime/socket_service.dart|g' {} +

# DI
find . -type f -name "*.dart" -exec sed -i '' 's|core/infrastructure/services/service_locator\.dart|core/di/service_locator.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/infrastructure/exceptions/api_exception\.dart|core/di/api_exception.dart|g' {} +

# Presentation
find . -type f -name "*.dart" -exec sed -i '' 's|core/themes/app_colors\.dart|core/presentation/theme/app_colors.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/themes/app_spacing\.dart|core/presentation/theme/app_spacing.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/themes/app_theme\.dart|core/presentation/theme/app_theme.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/themes/ui_tokens\.dart|core/presentation/theme/ui_tokens.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/themes/web_theme\.dart|core/presentation/theme/web_theme.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/providers/theme_provider\.dart|core/presentation/theme/theme_provider.dart|g' {} +
find . -type f -name "*.dart" -exec sed -i '' 's|core/extensions/context_extensions\.dart|core/presentation/extensions/context_extensions.dart|g' {} +

echo "✅ Migration terminée!"
