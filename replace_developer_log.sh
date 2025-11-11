#!/bin/bash

# List of files to process
files=(
  "lib/core/navigation/app_router.dart"
  "lib/features/posts/presentation/mobile/screens/feed_screen.dart"
  "lib/features/posts/presentation/mobile/screens/post_detail_screen.dart"
  "lib/features/posts/presentation/mobile/screens/saved_content_screen.dart"
  "lib/features/posts/presentation/mobile/screens/video_detail_screen.dart"
  "lib/features/posts/presentation/shared/widgets/feed_item.dart"
  "lib/features/posts/presentation/shared/widgets/full_article_dialog.dart"
  "lib/features/posts/presentation/shared/widgets/opposition_dialog.dart"
  "lib/features/profile/data/repositories/profile_repository_impl.dart"
  "lib/features/authentication/data/repositories/auth_repository_impl.dart"
  "lib/features/settings/presentation/mobile/screens/subscriptions_screen.dart"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "Processing: $file"
    # Replace developer.log with print and convert error parameter to regular parameter
    perl -i -pe 's/developer\.log\(\s*$/print(/g' "$file"
    perl -i -pe 's/,\s*error:\s*/,/g' "$file"
    perl -i -pe "s/,\s*name:\s*'[^']*'//g" "$file"
    # Remove developer import if it's the only import from dart:developer
    perl -i -pe "s/^import 'dart:developer' as developer;\s*$//g" "$file"
  fi
done

echo "Done!"
