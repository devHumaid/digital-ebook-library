import 'package:flutter/material.dart';
import 'library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _bgImageUrl =
      'https://images.unsplash.com/photo-1507842217343-583bb7270b66?q=80&w=1200&auto=format&fit=crop';

  bool _isLoading = false;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;

    setState(() => _isFirstTime = !hasSeenSplash);

    if (hasSeenSplash && mounted) {
      // Not first time - show loading and navigate directly
      _navigateToHome();
    }
  }

  Future<void> _onGetStarted() async {
    setState(() => _isLoading = true);

    // Save that user has seen splash screen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_splash', true);

    // 3 second delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LibraryScreen()),
    );
  }

  Future<void> _navigateToHome() async {
    setState(() => _isLoading = true);

    // 3 second delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B1A0E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _bgImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF2B1A0E),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFF2B1A0E)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC2B1A0E),
                  Color(0x992B1A0E),
                  Color(0xF02B1A0E),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  // Show splash content only on first time
                  if (_isFirstTime) ...[
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(text: 'My '),
                            TextSpan(
                              text: 'Bookshelf',
                              style: TextStyle(color: Color(0xFFD9A05B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'Upload, organize, and read your ebooks — all in one place.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4226),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _onGetStarted,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // Show loading spinner for returning users
                    const Spacer(),
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD9A05B),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}