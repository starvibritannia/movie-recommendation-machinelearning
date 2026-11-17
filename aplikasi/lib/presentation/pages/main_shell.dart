import 'package:flutter/material.dart';

import 'discover_page.dart';
import 'trending_page.dart';
import 'watchlist_page.dart';
import '../widgets/glass_nav_bar.dart';

/// Kerangka aplikasi: 3 tab di bawah (Trending, Discover, Watchlist).
///
/// Pakai IndexedStack supaya state tiap tab (posisi scroll, isi watchlist,
/// isi form filter) nggak hilang saat user pindah-pindah tab.
/// Nav bar sengaja melayang (extendBody) supaya konten lewat di bawahnya dan
/// panel kacanya tembus pandang, sesuai referensi UI 3.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    TrendingPage(),
    DiscoverPage(),
    WatchlistPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
