// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/skeleton.dart';

export 'package:sadaqo/core/widgets/skeleton.dart' show LoadingVariant;

/// Tampilan saat memuat: kerangka berkilau (shimmer) yang bentuknya mengikuti
/// [variant]. Dapat dipakai di area dengan tinggi terbatas maupun tidak.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.variant = LoadingVariant.list});

  final LoadingVariant variant;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat',
      child: Shimmer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = SkeletonLayouts.of(variant);
            if (constraints.hasBoundedHeight) {
              // Potong kerangka yang melebihi tinggi area.
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: content,
                ),
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }
}