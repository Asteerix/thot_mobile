import 'package:flutter/material.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/admin/presentation/shared/utils/admin_snackbar_utils.dart';
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String targetTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => ReportSheet(
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
    ),
  );
}
Future<void> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String targetTitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => ReportDialog(
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
    ),
  );
}
class ReportDialog extends StatelessWidget {
  final String targetType;
  final String targetId;
  final String targetTitle;
  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
  });
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ReportForm(
          targetType: targetType,
          targetId: targetId,
          targetTitle: targetTitle,
        ),
      ),
    );
  }
}
class ReportSheet extends StatelessWidget {
  final String targetType;
  final String targetId;
  final String targetTitle;
  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
  });
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ReportForm(
          targetType: targetType,
          targetId: targetId,
          targetTitle: targetTitle,
        ),
      ),
    );
  }
}
class ReportForm extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String targetTitle;
  const ReportForm({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetTitle,
  });
  @override
  State<ReportForm> createState() => _ReportFormState();
}
class _Reason {
  final String code;
  final String label;
  final IconData icon;
  const _Reason(this.code, this.label, this.icon);
}
class _ReportFormState extends State<ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _selected;
  static const List<_Reason> _reasons = [
    _Reason('spam', 'Spam ou contenu indésirable', Icons.flag),
    _Reason('harassment', 'Harcèlement ou intimidation', Icons.block),
    _Reason('hate_speech', 'Discours haineux', Icons.gavel),
    _Reason('violence', 'Violence ou contenu choquant', Icons.shield),
    _Reason('false_information', 'Désinformation', Icons.error_outline),
    _Reason(
        'inappropriate_content', 'Contenu inapproprié', Icons.visibility_off),
    _Reason('copyright', 'Violation des droits d\'auteur', Icons.copyright),
    _Reason('other', 'Autre', Icons.more_horiz),
  ];
  bool get _descRequired => _selected == 'other';
  bool get _isValid =>
      _selected != null && (!_descRequired || _descCtrl.text.trim().isNotEmpty);
  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    final isFormOk = _formKey.currentState?.validate() ?? false;
    if (!_isValid || !isFormOk) {
      if (_selected == null) {
        AdminSnackbarUtils.showWarning(context, 'Veuillez sélectionner une raison');
      }
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final api = ServiceLocator.instance.apiService;
      await api.post(
        '/api/reports',
        data: {
          'targetType': widget.targetType,
          'targetId': widget.targetId,
          'reason': _selected,
          'description': _descCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      SafeNavigation.pop(context);
      AdminSnackbarUtils.showInfo(context, 'Signalement envoyé. Merci.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AdminSnackbarUtils.showError(context, 'Erreur lors du signalement : ${e.toString()}');
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signaler ce contenu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => SafeNavigation.pop(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.targetTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            'Pourquoi signalez-vous ce contenu ?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._reasons.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(r.icon),
              title: Text(r.label),
              trailing: _selected == r.code
                  ? Icon(Icons.radio_button_unchecked)
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () {
                setState(() => _selected = r.code);
              },
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _descRequired
                  ? 'Décrivez la raison (obligatoire)...'
                  : 'Informations supplémentaires (facultatif)...',
              border: const OutlineInputBorder(),
            ),
            validator: (_) {
              if (_descRequired && _descCtrl.text.trim().isEmpty) {
                return 'Description requise pour "Autre"';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => SafeNavigation.pop(context),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: (!_isValid || _isSubmitting) ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Signaler'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}