import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_publication_screen.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_question_screen.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/profile/application/providers/profile_provider.dart';
import 'package:thot/features/posts/presentation/mobile/screens/new_short_screen.dart';
class AddContentGrid extends ConsumerWidget {
  final String journalistId;
  const AddContentGrid({
    super.key,
    required this.journalistId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter du contenu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildAddContentTile(
                  context,
                  'Publication',
                  Icons.article_outlined,
                  Colors.blue,
                  () async {
                    final result = await SafeNavigation.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewPublicationScreen(
                          journalistId: journalistId,
                        ),
                      ),
                    );
                    if (result == true) {
                      if (context.mounted) {
                        SafeNavigation.pop(context, true);
                      }
                      if (context.mounted) {
                        ref.read(selectedTabIndexProvider.notifier).state = 0;
                        await ref
                            .read(profileControllerProvider.notifier)
                            .refreshCurrentTab(0);
                      }
                    }
                  },
                ),
                _buildAddContentTile(
                  context,
                  'Short',
                  Icons.short_text,
                  Colors.red,
                  () async {
                    final result = await SafeNavigation.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewShortScreen(
                          journalistId: journalistId,
                        ),
                      ),
                    );
                    if (result == true) {
                      if (context.mounted) {
                        SafeNavigation.pop(context, true);
                      }
                      if (context.mounted) {
                        ref.read(selectedTabIndexProvider.notifier).state = 1;
                        await ref
                            .read(profileControllerProvider.notifier)
                            .refreshCurrentTab(1);
                      }
                    }
                  },
                ),
                _buildAddContentTile(
                  context,
                  'Question',
                  Icons.question_answer_outlined,
                  Colors.orange,
                  () async {
                    final result = await SafeNavigation.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewQuestionScreen(
                          journalistId: journalistId,
                        ),
                      ),
                    );
                    if (result == true) {
                      if (context.mounted) {
                        SafeNavigation.pop(context);
                      }
                      if (context.mounted) {
                        ref.read(selectedTabIndexProvider.notifier).state = 2;
                        await ref
                            .read(profileControllerProvider.notifier)
                            .refreshCurrentTab(2);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAddContentTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Function() onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}