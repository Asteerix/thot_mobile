import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AddShortButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AddShortButton({
    super.key,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.blue,
      icon: Icon(Icons.add),
      label: const Text(
        'Ajouter un short',
        style: TextStyle(
          fontFamily: 'Tailwind',
        ),
      ),
    );
  }
}

class AddQuestionButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AddQuestionButton({
    super.key,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.green,
      icon: Icon(Icons.help_outline),
      label: const Text(
        'Question citoyenne',
        style: TextStyle(
          fontFamily: 'Tailwind',
        ),
      ),
    );
  }
}

class QuickActionButtons extends StatelessWidget {
  final VoidCallback onAddShort;
  final VoidCallback onAddQuestion;
  const QuickActionButtons({
    super.key,
    required this.onAddShort,
    required this.onAddQuestion,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddShort,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(Icons.add, size: 20),
              label: const Text(
                'Short',
                style: TextStyle(
                  fontFamily: 'Tailwind',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAddQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: Icon(Icons.help_outline, size: 20),
              label: const Text(
                'Question',
                style: TextStyle(
                  fontFamily: 'Tailwind',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionSpeedDial extends StatelessWidget {
  final VoidCallback onAddShort;
  final VoidCallback onAddQuestion;
  final VoidCallback onAddArticle;
  const ActionSpeedDial({
    super.key,
    required this.onAddShort,
    required this.onAddQuestion,
    required this.onAddArticle,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: onAddArticle,
          backgroundColor: AppColors.error,
          child: Icon(Icons.article),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onAddShort,
          backgroundColor: Colors.blue,
          child: Icon(Icons.videocamPlus),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: onAddQuestion,
          backgroundColor: Colors.green,
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
