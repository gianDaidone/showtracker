import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Un solo salvataggio in volo; la chiave non compare in errori o suggerimenti.
class SecretKeyDialog extends StatefulWidget {
  const SecretKeyDialog(
      {super.key,
      required this.title,
      required this.onSave,
      this.description,
      this.help});
  final String title;
  final Future<void> Function(String) onSave;
  final String? description;
  final Widget? help;
  @override
  State<SecretKeyDialog> createState() => _SecretKeyDialogState();
}

class _SecretKeyDialogState extends State<SecretKeyDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _controller.text.trim().isEmpty) return;
    final key = _controller.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(key);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Salvataggio non riuscito. Riprova.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: Text(widget.title),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (widget.description != null) Text(widget.description!),
            TextField(
                controller: _controller,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 512,
                enabled: !_saving,
                decoration:
                    InputDecoration(labelText: 'API Key', errorText: _error)),
            if (widget.help != null) widget.help!,
          ])),
          actions: [
            TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Annulla')),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent))
                    : const Text('Salva')),
          ],
        ),
      );
}
