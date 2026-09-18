import 'package:flutter/material.dart';

import 'brand_theme.dart';
import 'services/document_store.dart';

String kartaDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class DocumentValidityCopy {
  const DocumentValidityCopy({
    required this.label,
    required this.message,
    required this.icon,
  });

  final String label;
  final String message;
  final IconData icon;

  factory DocumentValidityCopy.forDocument(
    VaultDocument document, {
    DateTime? now,
  }) {
    final state = document.expiryState(now: now);
    final days = document.daysUntilExpiry(now: now);
    switch (state) {
      case DocumentExpiryState.expired:
        return DocumentValidityCopy(
          label: 'Expirado',
          message: document.expiresAt == null
              ? 'A validade terminou.'
              : 'Expirou em ${kartaDate(document.expiresAt!)}.',
          icon: Icons.error_outline_rounded,
        );
      case DocumentExpiryState.expiringSoon:
        final safeDays = days ?? 0;
        return DocumentValidityCopy(
          label: 'A expirar',
          message: safeDays == 0
              ? 'Expira hoje.'
              : safeDays == 1
                  ? 'Expira amanhã.'
                  : 'Expira em $safeDays dias.',
          icon: Icons.schedule_rounded,
        );
      case DocumentExpiryState.valid:
        return DocumentValidityCopy(
          label: 'Válido',
          message: document.expiresAt == null
              ? 'Sem data de validade registada.'
              : 'Válido até ${kartaDate(document.expiresAt!)}.',
          icon: Icons.verified_outlined,
        );
      case DocumentExpiryState.unknown:
        return const DocumentValidityCopy(
          label: 'Validade não registada',
          message: 'Adicione a data de validade para receber avisos.',
          icon: Icons.event_note_outlined,
        );
    }
  }
}

class DocumentValidityBadge extends StatelessWidget {
  const DocumentValidityBadge({
    super.key,
    required this.document,
    this.now,
    this.compact = false,
  });

  final VaultDocument document;
  final DateTime? now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = document.expiryState(now: now);
    final copy = DocumentValidityCopy.forDocument(document, now: now);
    final scheme = Theme.of(context).colorScheme;
    final Color foreground;
    final Color background;
    switch (state) {
      case DocumentExpiryState.expired:
        foreground = scheme.error;
        background = scheme.errorContainer;
        break;
      case DocumentExpiryState.expiringSoon:
        foreground = scheme.onTertiaryContainer;
        background = scheme.tertiaryContainer;
        break;
      case DocumentExpiryState.valid:
        foreground = scheme.onPrimaryContainer;
        background = scheme.primaryContainer;
        break;
      case DocumentExpiryState.unknown:
        foreground = HmatiasBrand.muted;
        background = scheme.surfaceContainerHighest;
        break;
    }

    return Semantics(
      label: '${copy.label}. ${copy.message}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 9,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(copy.icon, size: compact ? 16 : 18, color: foreground),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                compact ? copy.label : '${copy.label} · ${copy.message}',
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentDateField extends StatelessWidget {
  const DocumentDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.helperText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? helperText;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 100);
    final last = lastDate ?? DateTime(now.year + 50);
    var initial = value ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        suffixIcon: value == null
            ? const Icon(Icons.calendar_month_outlined)
            : IconButton(
                tooltip: 'Limpar $label',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
      child: InkWell(
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.event_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value == null ? 'Não indicada' : kartaDate(value!),
                  style: TextStyle(
                    color: value == null ? HmatiasBrand.muted : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}