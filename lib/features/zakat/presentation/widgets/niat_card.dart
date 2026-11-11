import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/zakat/domain/entities/zakat_niat.dart';

/// Kartu niat zakat: tulisan Arab, bacaan Latin, arti, dan konfirmasi niat.
class NiatCard extends StatelessWidget {
  const NiatCard({
    super.key,
    required this.title,
    required this.niat,
    required this.confirmLabel,
    required this.confirmed,
    required this.onConfirmed,
    this.selector,
  });

  final String title;
  final ZakatNiat niat;

  /// Pilihan niat (misal untuk siapa zakat fitrah ditunaikan). Boleh kosong.
  final Widget? selector;

  final String confirmLabel;
  final bool confirmed;
  final ValueChanged<bool> onConfirmed;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: niat.copyText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Niat disalin')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_outlined, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Salin niat',
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 20),
                color: AppColors.forestGreen,
              ),
            ],
          ),
          if (selector != null) ...[
            selector!,
            const SizedBox(height: 10),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.sandBeige.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                niat.arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  height: 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            niat.latin,
            style: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Artinya: ${niat.meaning}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 6),
          const Text(
            'Niat sejatinya ada di dalam hati. Lafaz di atas membantu menguatkan.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const Divider(height: 18),
          CheckboxListTile(
            value: confirmed,
            onChanged: (v) => onConfirmed(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppColors.forestGreen,
            title: Text(
              confirmLabel,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}