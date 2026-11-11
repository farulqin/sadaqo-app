import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';

Color programStatusFg(ProgramDocStatus s) {
  switch (s) {
    case ProgramDocStatus.active:
      return AppColors.success;
    case ProgramDocStatus.awaitingDocs:
      return const Color(0xFF8A6D1F);
    case ProgramDocStatus.underReview:
      return const Color(0xFF5B6B7A);
    case ProgramDocStatus.needsRevision:
      return AppColors.error;
  }
}

Color programStatusBg(ProgramDocStatus s) {
  switch (s) {
    case ProgramDocStatus.active:
      return AppColors.successSoft;
    case ProgramDocStatus.awaitingDocs:
      return const Color(0xFFF8E3A3);
    case ProgramDocStatus.underReview:
      return const Color(0xFFE3E9EE);
    case ProgramDocStatus.needsRevision:
      return const Color(0xFFF8DEDB);
  }
}

class ProgramStatusChip extends StatelessWidget {
  const ProgramStatusChip(this.status, {super.key});

  final ProgramDocStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: programStatusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: programStatusFg(status),
        ),
      ),
    );
  }
}

/// Kartu putih lembut yang dipakai di semua halaman pengelola.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}