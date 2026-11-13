import 'package:flutter/material.dart';

/// Dialog result payload returned by [TextInputDialog].
class TextInputDialogResult {
  const TextInputDialogResult({
    required this.action,
    required this.text,
  });

  final String action;
  final String text;
}

/// Reusable single-line text input dialog whose [TextEditingController] is
/// owned and disposed safely inside `State.dispose` after exit animations.
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    this.initialValue = '',
    this.labelText,
    this.hintText,
    this.confirmLabel = 'Simpan',
    this.secondaryActionLabel,
    this.secondaryActionKey,
    this.keyboardType = TextInputType.text,
  });

  final String title;
  final String initialValue;
  final String? labelText;
  final String? hintText;
  final String confirmLabel;
  final String? secondaryActionLabel;
  final String? secondaryActionKey;
  final TextInputType keyboardType;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        if (widget.secondaryActionLabel != null &&
            widget.secondaryActionKey != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              TextInputDialogResult(
                action: widget.secondaryActionKey!,
                text: _controller.text,
              ),
            ),
            child: Text(widget.secondaryActionLabel!),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            TextInputDialogResult(
              action: 'save',
              text: _controller.text,
            ),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

