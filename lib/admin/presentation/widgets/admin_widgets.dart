import 'package:flutter/material.dart';
import 'package:sadaqo/admin/data/asset_library.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/network/api_config.dart';

/// Warna khusus dashboard admin (mengikuti palet SADAQO + nuansa krem desain admin).
class AdminColors {
  AdminColors._();

  static const Color sidebarTop = Color(0xFF173A26);
  static const Color sidebarBottom = Color(0xFF1F3D2B);
  static const Color page = Color(0xFFF6F0E1);
  static const Color card = Color(0xFFFFFCF6);
  static const Color border = Color(0xFFEADFC8);
  static const Color green = AppColors.forestGreen;
  static const Color lime = AppColors.limeGreen;
  static const Color limeSoft = Color(0xFFE3F0C8);
  static const Color gold = Color(0xFFD9B84A);
  static const Color goldSoft = Color(0xFFF3E8C6);
  static const Color danger = AppColors.error;
  static const Color dangerSoft = Color(0xFFF8DEDB);
  static const Color warn = Color(0xFFC27B12);
  static const Color warnSoft = Color(0xFFFBEBCB);
  static const Color muted = AppColors.textMuted;
}

/// Warna tetap tiap kategori program di grafik admin.
Color categoryColor(ProgramCategory c) {
  switch (c) {
    case ProgramCategory.masjid:
      return const Color(0xFF1F3D2B);
    case ProgramCategory.sosial:
      return const Color(0xFF7FB03A);
    case ProgramCategory.zakat:
      return const Color(0xFFD9B84A);
    case ProgramCategory.duafa:
      return const Color(0xFFA3D65C);
    case ProgramCategory.qurban:
      return const Color(0xFF8A6D4B);
  }
}

/// Lebar layar: >= [AdminBreak.wide] memakai sidebar tetap, di bawahnya memakai laci.
class AdminBreak {
  AdminBreak._();

  static const double wide = 1000;
  static const double medium = 700;
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AdminColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: box,
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final titleBox = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AdminColors.green,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(color: AdminColors.muted)),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: LayoutBuilder(
        builder: (context, c) {
          if (actions.isEmpty) return titleBox;
          if (c.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBox,
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBox),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          );
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AdminColors.green),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AdminColors.green,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Lencana kecil berwarna (status, kategori, dll).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = AdminColors.green, this.bg, this.icon});

  final String label;
  final Color color;
  final Color? bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AdminColors.border),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: AdminColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Dialog konfirmasi. Mengembalikan true jika admin menekan tombol utama.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger ? AdminColors.danger : AdminColors.green,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void adminToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

/// Tombol aksi utama dashboard (hijau tua).
class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AdminColors.danger : AdminColors.green;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Text(label),
      ],
    );
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(0, 44),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child,
    );
  }
}

/// Gambar dari aset dengan cadangan jika file tidak ada.
class AssetThumb extends StatelessWidget {
  const AssetThumb(this.path, {super.key, this.width, this.height, this.radius = 10, this.fit = BoxFit.cover});

  final String? path;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AdminColors.limeSoft,
      child: const Icon(Icons.image_outlined, color: AdminColors.green),
    );
    final p = path;
    Widget child;
    if (p == null || p.isEmpty) {
      child = fallback;
    } else if (p.startsWith('http://') || p.startsWith('https://')) {
      child = Image.network(
        ApiConfig.resolveMediaUrl(p),
        width: width,
        height: height,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (context, error, stack) => fallback,
      );
    } else {
      child = Image.asset(
        p,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: (width != null && width!.isFinite) ? (width! * 2).round() : 640,
        errorBuilder: (context, error, stack) => fallback,
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}

/// Pemilih gambar dari pustaka aset aplikasi. Mengembalikan path aset, atau null.
Future<String?> showAssetPicker(
  BuildContext context, {
  String title = 'Pilih gambar',
  List<String>? groups,
  String? initialGroup,
  String? selected,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _AssetPickerDialog(
      title: title,
      groups: groups,
      initialGroup: initialGroup,
      selected: selected,
    ),
  );
}

class _AssetPickerDialog extends StatefulWidget {
  const _AssetPickerDialog({
    required this.title,
    this.groups,
    this.initialGroup,
    this.selected,
  });

  final String title;
  final List<String>? groups;
  final String? initialGroup;
  final String? selected;

  @override
  State<_AssetPickerDialog> createState() => _AssetPickerDialogState();
}

class _AssetPickerDialogState extends State<_AssetPickerDialog> {
  Map<String, List<String>>? _data;
  String? _group;

  @override
  void initState() {
    super.initState();
    AssetLibrary.load().then((d) {
      if (!mounted) return;
      final keys = (widget.groups ?? AssetLibrary.groups.keys.toList())
          .where((k) => (d[k] ?? const <String>[]).isNotEmpty)
          .toList();
      setState(() {
        _data = d;
        _group = keys.contains(widget.initialGroup)
            ? widget.initialGroup
            : (keys.isEmpty ? null : keys.first);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: AdminColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760, maxHeight: size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: data == null
              ? const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(color: AdminColors.green)),
                )
              : _content(data),
        ),
      ),
    );
  }

  Widget _content(Map<String, List<String>> data) {
    final keys = (widget.groups ?? AssetLibrary.groups.keys.toList())
        .where((k) => (data[k] ?? const <String>[]).isNotEmpty)
        .toList();
    final files = _group == null ? const <String>[] : (data[_group] ?? const <String>[]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (keys.isEmpty)
          const EmptyState(icon: Icons.image_not_supported_outlined, text: 'Belum ada gambar')
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final k in keys)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(AssetLibrary.groups[k] ?? k),
                      selected: _group == k,
                      showCheckmark: false,
                      selectedColor: AdminColors.green,
                      labelStyle: TextStyle(
                        color: _group == k ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _group = k),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: files.length,
              itemBuilder: (context, i) {
                final path = files[i];
                final isSel = path == widget.selected;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, path),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AdminColors.green : AdminColors.border,
                        width: isSel ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: _group == 'icons'
                                ? Container(
                                    color: AdminColors.limeSoft,
                                    padding: const EdgeInsets.all(14),
                                    child: Image.asset(path, fit: BoxFit.contain),
                                  )
                                : AssetThumb(path, radius: 8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AssetLibrary.fileName(path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Baris batang horizontal: label, nilai, dan panjang batang sebanding.
class BarRow extends StatelessWidget {
  const BarRow({
    super.key,
    required this.label,
    required this.valueText,
    required this.fraction,
    this.color = AdminColors.green,
    this.leading,
  });

  final String label;
  final String valueText;
  final double fraction;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Text(valueText, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AdminColors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
