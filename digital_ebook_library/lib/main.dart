import 'package:digital_ebook_library/provider/ebook_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const EbookLibraryApp());
}

class EbookLibraryApp extends StatelessWidget {
  const EbookLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EbookProvider(),
      child: MaterialApp(
        title: 'Ebook Library',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF6B4226),
          scaffoldBackgroundColor: const Color(0xFFF5EFE6),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF6B4226),
            foregroundColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}