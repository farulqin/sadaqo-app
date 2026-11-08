import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';

/// Layar pembuka dengan animasi logo:
/// 1) logo muncul dengan efek membesar + fade + naik pelan,
/// 2) tagline muncul menyusul,
/// 3) bar loading berjalan, lalu pindah ke halaman login dengan transisi fade.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  // Logo: 0% - 60% dari durasi
  late final Animation<double> _logoScale = Tween<double>(begin: 0.4, end: 1.0)
      .animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  ));
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<Offset> _logoSlide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  ));

  // Tagline: 55% - 85%
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 400), _goNext);
    });
  }

  void _goNext() {
    if (!mounted) return;
    // Catatan (tahap token): langsung ke MainShell jika sudah login.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.background, AppColors.sandBeige],
          ),
        ),
        child: Stack(
          children: [
            // Hiasan lingkaran lembut
            Positioned(
              top: -60,
              right: -50,
              child: _Circle(size: 200, color: AppColors.limeGreen.withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: -70,
              left: -60,
              child: _Circle(size: 220, color: AppColors.forestGreen.withValues(alpha: 0.08)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(AppAssets.logo, width: 280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: const Text(
                      'Berbagi Kebaikan, Menebar Manfaat',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: Center(
                child: SizedBox(
                  width: 120,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 4,
                        backgroundColor: AppColors.sandBeige,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
