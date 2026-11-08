import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menyalin teks ke papan klip dan memberi tahu pengguna.
Future<void> copyToClipboard(BuildContext context, String label, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$label disalin: $value')));
}