import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';
import 'package:sadaqo/features/news/presentation/pages/news_detail_page.dart';

/// Carousel berita yang bergeser otomatis seperti banner iklan.
/// - Geser otomatis tiap [interval]; kembali ke berita pertama setelah yang terakhir.
/// - Berhenti saat pengguna menyentuh/menggeser, lanjut lagi setelah dilepas.
class NewsCarousel extends StatefulWidget {
  const NewsCarousel({
    super.key,
    required this.articles,
    this.interval = const Duration(seconds: 4),
  });

  final List<NewsArticle> articles;
  final Duration interval;

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  late final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    if (widget.articles.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) => _next());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _next() {
    if (!mounted || !_controller.hasClients) return;
    final target = (_page + 1) % widget.articles.length;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Hanya tanggapi geseran oleh jari (bukan animasi otomatis).
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _stopTimer();
              } else if (notification is ScrollEndNotification) {
                if (_timer == null) _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.articles.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _NewsCard(article: widget.articles[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.articles.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: i == _page ? 20 : 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.forestGreen : AppColors.sandBeige,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: AppColors.forestGreen,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailPage(article: article)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProgramImage(
              category: article.category,
              imageAsset: article.imageAsset,
            ),
            // Lapisan gelap agar teks putih tetap terbaca di atas gambar apa pun.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                  stops: [0.25, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.category.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatter.date(article.publishedAt)}  •  ${article.readMinutes} menit baca',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
