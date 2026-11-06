import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';

/// Empat pintasan kategori di beranda.
class CategoryShortcuts extends StatelessWidget {
  const CategoryShortcuts({super.key, required this.onSelected});

  final ValueChanged<ProgramCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final c in ProgramCategory.values)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(c),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.sandBeige,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(c.icon, color: AppColors.forestGreen),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
