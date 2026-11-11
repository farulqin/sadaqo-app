import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/app_info.dart';
import 'package:sadaqo/core/utils/clipboard_helper.dart';
import 'package:sadaqo/core/widgets/batik_widgets.dart';
import 'package:sadaqo/features/profile/presentation/pages/legal_page.dart';

/// Tentang SADAQO: tempat membangun rasa percaya sebelum berdonasi.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang SADAQO')),
      body: const AboutContent(),
    );
  }
}

/// Isi halaman "Tentang SADAQO" tanpa Scaffold. [embedded] = true dipakai di
/// dashboard admin (latar batik sudah disediakan kerangka admin).
class AboutContent extends StatelessWidget {
  const AboutContent({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1) Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                color: AppColors.sandBeige,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Image.asset(AppAssets.logo, height: 150),
                  const SizedBox(height: 12),
                  const Text(
                    'Menghubungkan Niat Baikmu dengan Mereka yang Membutuhkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestGreen,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2) Cerita, visi, misi
                  const _Title('Cerita SADAQO'),
                  const Text(
                    'SADAQO lahir dari sebuah keyakinan bahwa kebaikan sekecil apa pun berhak '
                    'mendapat tempat untuk tumbuh. Kami hadir sebagai jembatan digital yang '
                    'memudahkan kamu untuk berbagi, mulai dari dukungan pembangunan masjid, '
                    'zakat, hingga bantuan sosial untuk komunitas di sekitarmu. Dengan SADAQO, '
                    'niat baik kini hanya sejauh satu sentuhan jari.',
                    style: TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  const _MiniCard(
                    icon: Icons.flag_outlined,
                    title: 'Visi',
                    text: 'Menjadi jembatan digital kebaikan yang dipercaya masyarakat.',
                  ),
                  const SizedBox(height: 10),
                  const _MiniCard(
                    icon: Icons.checklist_rtl,
                    title: 'Misi',
                    text: '• Memudahkan siapa saja berdonasi dengan nominal terjangkau.\n'
                        '• Menjaga transparansi dari donasi hingga penyaluran.\n'
                        '• Mendukung masjid, mushola, dan sesama yang membutuhkan.',
                  ),
                  const BatikDivider(),

                  // 3) Nilai inti
                  const _Title('Nilai-Nilai Kami'),
                  const _ValueRow(
                    icon: Icons.spa_outlined,
                    title: 'Tumbuh Bersama',
                    text: 'Memberdayakan komunitas lokal dan tempat ibadah.',
                  ),
                  const _ValueRow(
                    icon: Icons.visibility_outlined,
                    title: 'Transparan 100%',
                    text: 'Jejak kebaikanmu dapat dipantau. Kamu tahu persis ke mana sedekahmu berlabuh.',
                  ),
                  const _ValueRow(
                    icon: Icons.bolt_outlined,
                    title: 'Cepat & Mudah',
                    text: 'Beramal tanpa ribet, kapan saja dan di mana saja.',
                  ),
                  const BatikDivider(),

                  // 4) Komitmen keamanan dan kepercayaan
                  const _Title('Komitmen Keamanan & Kepercayaan'),
                  const Text(
                    'Amanahmu adalah prioritas kami. SADAQO dirancang untuk bekerja sama dengan '
                    'lembaga tepercaya, memakai sistem pembayaran yang aman, dan mencatat setiap '
                    'donasi agar dapat ditelusuri dan tepat sasaran.',
                    style: TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sandBeige),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppColors.forestGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan: versi ini adalah aplikasi demo untuk tugas kuliah. '
                            'Transaksi bersifat simulasi dan belum terhubung dengan lembaga '
                            'atau penyedia pembayaran sungguhan.',
                            style: TextStyle(fontSize: 12, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const BatikDivider(),

                  // 5) Hubungi kami
                  const _Title('Hubungi Kami'),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.mail_outline, color: AppColors.forestGreen),
                          title: const Text('Email CS'),
                          subtitle: const Text(AppInfo.email),
                          onTap: () => copyToClipboard(context, 'Email', AppInfo.email),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.chat_outlined, color: AppColors.forestGreen),
                          title: const Text('WhatsApp CS'),
                          subtitle: const Text(AppInfo.whatsapp),
                          onTap: () =>
                              copyToClipboard(context, 'Nomor WhatsApp', AppInfo.whatsapp),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SocialChip(tag: 'IG', label: 'Instagram', handle: AppInfo.instagram),
                      _SocialChip(tag: 'TT', label: 'TikTok', handle: AppInfo.tiktok),
                      _SocialChip(tag: 'Th', label: 'Threads', handle: AppInfo.threads),
                      _SocialChip(tag: 'X', label: 'X', handle: AppInfo.x),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kontak dan akun di atas adalah contoh untuk versi demo. Ketuk untuk menyalin.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const BatikDivider(),

                  // 6) Informasi teknis
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.verified_outlined, color: AppColors.forestGreen),
                          title: Text('Versi Aplikasi'),
                          trailing: Text('Version ${AppInfo.version}'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined,
                              color: AppColors.forestGreen),
                          title: const Text('Syarat & Ketentuan'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LegalPage.terms()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined,
                              color: AppColors.forestGreen),
                          title: const Text('Kebijakan Privasi'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LegalPage.privacy()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '${AppInfo.name} • ${AppInfo.tagline}',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return embedded ? content : BatikBackground(child: content);
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.forestGreen,
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.forestGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.forestGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.tag, required this.label, required this.handle});

  final String tag;
  final String label;
  final String handle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => copyToClipboard(context, label, handle),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.sandBeige),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.forestGreen,
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(handle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}