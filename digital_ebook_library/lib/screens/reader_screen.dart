import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/ebook.dart';
import '../services/api_service.dart';
import 'package:pdfx/pdfx.dart';

const _bgDark = Color(0xFF2B1A0E);
const _bgDarkLight = Color(0xFF4A2F18);
const _brown = Color(0xFF6B4226);
const _gold = Color(0xFFD9A05B);

class ReaderScreen extends StatefulWidget {
  final Ebook ebook;
  const ReaderScreen({super.key, required this.ebook});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ApiService _api = ApiService();
  String? _localPath;
  bool _loading = true;
  String? _error;

  PdfDocument? _document;
  int _totalPages = 0;

  // PageController drives the pager directly — jumping/animating to an
  // index is O(1) and doesn't depend on estimated item heights, unlike
  // the old scrollable_positioned_list approach. This is what makes page
  // jumps (arrows + slider) instant and smooth instead of "buffering".
  late final PageController _pageController;

  int _currentPage = 1;

  // While the user is dragging the slider we only update this local value
  // (cheap, instant label feedback) and DON'T move the actual PageView.
  // The PageView only jumps once, on release. This is the fix for the
  // slider feeling like it's buffering / not moving smoothly.
  int? _draggingPage;

  // Tap the page to hide the floating chrome, like most modern readers.
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _prepareFile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _document?.close();
    super.dispose();
  }

  Future<void> _prepareFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Reuse the local copy if it was already downloaded, otherwise fetch it.
      final existing = await _api.localFileIfExists(widget.ebook);
      final path = await existing.exists()
          ? existing.path
          : await _api.downloadEbook(widget.ebook);

      if (widget.ebook.isPdf) {
        final document = await PdfDocument.openFile(path);
        _document?.close();
        _document = document;
        _totalPages = document.pagesCount;
      }

      setState(() {
        _localPath = path;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _pageController.animateToPage(
      page - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  @override
  Widget build(BuildContext context) {
    final isReadablePdf = !_loading && _error == null && widget.ebook.isPdf;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1108),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-bleed content — tapping it toggles the floating chrome.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleChrome,
              child: _buildBody(),
            ),
          ),
          _buildFloatingHeader(),
          if (isReadablePdf) _buildFloatingPageBar(),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      top: _chromeVisible ? 0 : -80,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _chromeVisible ? 1 : 0,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              color: Colors.black.withOpacity(0.28),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.ebook.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Empty spacer matching the back button's footprint,
                      // so the title stays visually centered.
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      // White background here too, so the transition into the (white)
      // PDF pages doesn't have a jarring dark-to-light flash.
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: _brown),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                'Could not open this ebook',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _prepareFile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (!widget.ebook.isPdf) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'EPUB in-app reading isn\'t supported yet. '
            'Use the download button to read it in another app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return _PdfPager(
      document: _document!,
      pageController: _pageController,
      onPageChanged: (page) {
        if (page != _currentPage) {
          setState(() => _currentPage = page);
        }
      },
    );
  }

  Widget _buildFloatingPageBar() {
    // Show whichever page number the user is currently dragging to, if
    // dragging; otherwise fall back to the real current page.
    final displayPage = _draggingPage ?? _currentPage;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: _chromeVisible ? 0 : -100,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _chromeVisible ? 1 : 0,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withOpacity(0.28),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _currentPage > 1,
                      onTap: () => _goToPage(_currentPage - 1),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Page $displayPage of $_totalPages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12),
                              activeTrackColor: _gold,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: _gold,
                            ),
                            child: Slider(
                              min: 1,
                              max: _totalPages
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              value: displayPage
                                  .toDouble()
                                  .clamp(1, _totalPages.toDouble()),
                              // Only update the local "preview" label while
                              // dragging — do NOT move the PageView here.
                              // Moving the real page on every tick is what
                              // caused the buffering/jank feeling.
                              onChanged: (v) {
                                setState(() => _draggingPage = v.round());
                              },
                              // Commit the jump exactly once, when the user
                              // lets go. jumpToPage/animateToPage on a
                              // PageController is a direct O(1) hop, so
                              // this lands smoothly even for long jumps.
                              onChangeEnd: (v) {
                                final target = v.round();
                                setState(() {
                                  _draggingPage = null;
                                  _currentPage = target;
                                });
                                _pageController.animateToPage(
                                  target - 1,
                                  duration:
                                      const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _currentPage < _totalPages,
                      onTap: () => _goToPage(_currentPage + 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders each PDF page as an image and shows one page at a time in a
/// vertical, page-snapping pager. Compared to the old continuous list:
///  - each page is centered (both axes) instead of pinned to the top
///  - each page supports pinch/double-tap zoom via InteractiveViewer
///  - neighboring pages are pre-rendered in the background so flipping
///    forward/back doesn't hit a cold render + spinner every time
class _PdfPager extends StatefulWidget {
  final PdfDocument document;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _PdfPager({
    required this.document,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  State<_PdfPager> createState() => _PdfPagerState();
}

class _PdfPagerState extends State<_PdfPager> {
  final Map<int, Uint8List> _cache = {};
  final Map<int, double> _aspectRatios = {};
  final Map<int, Future<Uint8List?>> _inFlight = {};

  @override
  void initState() {
    super.initState();
    // Pre-render the first couple of pages immediately so the reader
    // doesn't open on a blank spinner longer than necessary.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAround(1);
    });
  }

  double get _renderWidth {
    final width = MediaQuery.of(context).size.width;
    return width;
  }

  Future<Uint8List?> _renderPage(int pageNumber) {
    final cached = _cache[pageNumber];
    if (cached != null) return Future.value(cached);

    final existing = _inFlight[pageNumber];
    if (existing != null) return existing;

    final future = _doRenderPage(pageNumber);
    _inFlight[pageNumber] = future;
    return future;
  }

  Future<Uint8List?> _doRenderPage(int pageNumber) async {
    try {
      if (pageNumber < 1 || pageNumber > widget.document.pagesCount) {
        return null;
      }
      final page = await widget.document.getPage(pageNumber);
      final targetWidth = _renderWidth;
      final renderWidth = targetWidth * 2; // 2x for sharpness on high-dpi screens
      final renderHeight = renderWidth * (page.height / page.width);

      final image = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: PdfPageImageFormat.png,
        // Force an opaque white page background — without this, pages with
        // transparent backgrounds pick up whatever is behind them (in this
        // app, a dark brown backdrop), which makes dark PDF text unreadable.
        backgroundColor: '#FFFFFF',
      );
      _aspectRatios[pageNumber] = page.width / page.height;
      await page.close();

      if (image == null) return null;
      _cache[pageNumber] = image.bytes;
      return image.bytes;
    } finally {
      _inFlight.remove(pageNumber);
    }
  }

  /// Fire-and-forget render of the page before/after [pageNumber] so
  /// swiping forward or back usually finds an already-cached image
  /// instead of waiting on a fresh render.
  void _precacheAround(int pageNumber) {
    for (final p in [pageNumber, pageNumber + 1, pageNumber - 1]) {
      if (p >= 1 && p <= widget.document.pagesCount && !_cache.containsKey(p)) {
        _renderPage(p);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.document.pagesCount,
      onPageChanged: (index) {
        final pageNumber = index + 1;
        widget.onPageChanged(pageNumber);
        _precacheAround(pageNumber);
      },
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        return _PdfPageView(
          pageNumber: pageNumber,
          renderPage: () => _renderPage(pageNumber),
          knownAspectRatio: _aspectRatios[pageNumber],
        );
      },
    );
  }
}

/// A single page slot: fills the screen, and centers its content (both
/// while loading and once rendered) so the page never looks pinned to
/// the top. Wrapped in InteractiveViewer for pinch/double-tap zoom.
class _PdfPageView extends StatelessWidget {
  final int pageNumber;
  final Future<Uint8List?> Function() renderPage;
  final double? knownAspectRatio;

  const _PdfPageView({
    required this.pageNumber,
    required this.renderPage,
    required this.knownAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: FutureBuilder<Uint8List?>(
        future: renderPage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _brown),
            );
          }
          final bytes = snapshot.data!;
          // InteractiveViewer gives pinch-to-zoom and double-tap zoom.
          // A fresh InteractiveViewer (and its default TransformationController)
          // is created per page instance, so flipping to a new page resets
          // zoom/pan instead of carrying it over from the previous page.
          return Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A small frosted circular button used in the floating header and page bar.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.white.withOpacity(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white24,
            size: 22,
          ),
        ),
      ),
    );
  }
}