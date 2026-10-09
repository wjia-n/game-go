import 'package:flutter/material.dart';

import '../theme.dart';

/// Renameable player-name field. Owns its [TextEditingController] so
/// in-progress typing survives parent rebuilds; commits on submit or
/// tap-outside. Empty input keeps the previous name.
class NameField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onCommit;
  final VoidCallback onInteract;
  final Color? fill;

  const NameField({
    super.key,
    required this.label,
    required this.value,
    required this.onCommit,
    required this.onInteract,
    this.fill,
  });

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant NameField old) {
    super.didUpdateWidget(old);
    // Adopt external changes (e.g. loaded from disk) when not editing.
    if (old.value != widget.value &&
        !_focus.hasFocus &&
        _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final v = _ctrl.text.trim();
    widget.onInteract();
    widget.onCommit(v.isEmpty ? widget.value : v);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 128, child: Text(widget.label, style: GoTheme.label(12))),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: widget.fill ?? GoTheme.clamshell,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GoTheme.carved),
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: GoTheme.body(14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              maxLength: 16,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  const SizedBox.shrink(),
              onSubmitted: (_) => _commit(),
              onTapOutside: (_) {
                if (_ctrl.text.trim() != widget.value) _commit();
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
          ),
        ),
      ],
    );
  }
}
