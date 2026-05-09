import 'package:flutter/material.dart';

class FormActionBar extends StatelessWidget {
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final String primaryLoadingLabel;
  final IconData primaryIcon;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final bool loading;

  const FormActionBar({
    super.key,
    required this.onPrimary,
    required this.onSecondary,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.secondaryLabel,
    required this.secondaryIcon,
    this.primaryLoadingLabel = 'Loading…',
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : onPrimary,
          icon: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Icon(primaryIcon, size: 18),
          label: Text(loading ? primaryLoadingLabel : primaryLabel),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
        ),
        OutlinedButton.icon(
          onPressed: loading ? null : onSecondary,
          icon: Icon(secondaryIcon, size: 18),
          label: Text(secondaryLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
