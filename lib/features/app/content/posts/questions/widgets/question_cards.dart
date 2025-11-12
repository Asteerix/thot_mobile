import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/features/app/content/shared/models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final Function(String?, String)? onVote;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  const QuestionCard({
    super.key,
    required this.question,
    this.onVote,
    this.isExpanded = false,
    this.onToggleExpand,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              question.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontFamily: 'Tailwind',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.content,
                  style: TextStyle(
                    color: colorScheme.outline.withOpacity(0.6),
                    fontFamily: 'Tailwind',
                  ),
                ),
                const SizedBox(height: 16),
                ...question.options.map((option) {
                  final percentage = option.percentage ??
                      question.getOptionPercentage(option.text);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => onVote?.call(option.id, option.text),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colorScheme.outline.withOpacity(0.7)),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    option.text,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontFamily: 'Tailwind',
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color:
                                          colorScheme.outline.withOpacity(0.6),
                                      fontFamily: 'Tailwind',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  '${question.responseCount} votes',
                  style: TextStyle(
                    color: colorScheme.outline.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'Tailwind',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
