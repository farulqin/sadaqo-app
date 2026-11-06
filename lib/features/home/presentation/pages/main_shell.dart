import 'package:flutter/material.dart';
import '../../../../core/widgets/placeholder_page.dart';

/// Kerangka utama aplikasi: bottom navigation.
/// Setiap tab nanti diganti dengan halaman fitur aslinya.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // TODO: ganti satu per satu saat fitur selesai dibuat.
  static const List<Widget> _pages = [
    PlaceholderPage(title: 'Beranda', icon: Icons.home_outlined),
    PlaceholderPage(title: 'Kurban', icon: Icons.volunteer_activism_outlined),
    PlaceholderPage(title: 'Zakat', icon: Icons.calculate_outlined),
    PlaceholderPage(title: 'Riwayat', icon: Icons.receipt_long_outlined),
    PlaceholderPage(title: 'Profil', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), label: 'Kurban'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'Zakat'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
