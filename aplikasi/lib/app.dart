import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/pages/splash_page.dart';

/// Root widget aplikasi: atur tema, judul, dan halaman pertama.
class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FilmMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashPage(),
    );
  }
}
