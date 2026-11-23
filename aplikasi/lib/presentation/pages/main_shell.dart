import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/watchlist_provider.dart';
import 'mascot_page.dart';
import 'watchlist_page.dart';
import '../widgets/glass_nav_bar.dart';

/// Kerangka aplikasi: 2 tab di bawah (Maskot, Watchlist).
///
/// Pakai IndexedStack supaya state tiap tab (posisi scroll, isi watchlist,
/// progres ngobrol sama maskot) nggak hilang saat user pindah-pindah tab.
/// Nav bar sengaja melayang (extendBody) supaya konten lewat di bawahnya dan
/// panel kacanya tembus pandang, sesuai referensi UI 3.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const MascotPage(),
    WatchlistPage(
      onFindFilms: () {
        if (mounted) setState(() => _currentIndex = 0);
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        watchlistCount: watchlist.count,
      ),
    );
  }
}
