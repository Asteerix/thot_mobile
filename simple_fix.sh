#!/bin/bash

# Fix all remaining print issues by replacing with simple debugPrint calls

# Feed screen
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/features/posts/presentation/mobile/screens/feed_screen.dart
sed -i.bak "s/print('[^']*' + {[^}]*},$/debugPrint('FEED_SCREEN');/g" lib/features/posts/presentation/mobile/screens/feed_screen.dart

# Post detail screen  
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/features/posts/presentation/mobile/screens/post_detail_screen.dart

# App router
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/core/navigation/app_router.dart

# Profile repo
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/features/profile/data/repositories/profile_repository_impl.dart

# Saved content
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/features/posts/presentation/mobile/screens/saved_content_screen.dart

# Feed item
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/features/posts/presentation/shared/widgets/feed_item.dart

# Opposition dialog
sed -i.bak 's/print(\[/debugPrint(\[/g' lib/features/posts/presentation/shared/widgets/opposition_dialog.dart

echo "Done basic replacement"

# Remove .bak files
find lib -name "*.bak" -delete
