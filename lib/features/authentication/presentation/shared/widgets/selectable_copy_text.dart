import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class SelectableCopyText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final String? onCopiedTooltip;
  final String copyButtonTooltip;
  final IconData copyIcon;
  const SelectableCopyText({
    super.key,
    required this.text,
    this.textStyle,
    this.onCopiedTooltip,
    this.copyButtonTooltip = 'Copier',
    this.copyIcon = Icons.copy,
  });
  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(onCopiedTooltip ?? 'Copié'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText(
            text,
            style: textStyle,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: copyButtonTooltip,
          child: IconButton(
            icon: Icon(copyIcon, size: 18),
            onPressed: () => _copyToClipboard(context),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}