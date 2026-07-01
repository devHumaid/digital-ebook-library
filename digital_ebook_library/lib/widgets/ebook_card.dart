import 'package:flutter/material.dart';
import '../models/ebook.dart';
import '../services/api_service.dart';

class EbookCard extends StatelessWidget {
  final Ebook ebook;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const EbookCard({
    super.key,
    required this.ebook,
    required this.onTap,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showActions(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _Book(ebook: ebook)),
          const SizedBox(height: 6),
          Text(
            ebook.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A2A1A),
            ),
          ),
          if (ebook.author != null)
            Text(
              ebook.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8A7B6C)),
            ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF6B4226)),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.download_rounded, color: Color(0xFF6B4226)),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(ctx);
                onDownload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the ebook as a physical hardcover: a spine shadow on the left,
/// a stack of page-edge lines peeking out on the right, and a soft gloss
/// sheen across the cover — so it reads as a real book whether or not a
/// cover image is available.
class _Book extends StatelessWidget {
  final Ebook ebook;
  const _Book({required this.ebook});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageStrip = (constraints.maxWidth * 0.09).clamp(3.0, 7.0);
        return Padding(
          padding: EdgeInsets.only(right: pageStrip * 0.7),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // Page edges, stacked just behind the cover's right side.
              Positioned(
                right: -pageStrip,
                top: 3,
                bottom: 3,
                width: pageStrip,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3EAD8),
                    borderRadius:
                        BorderRadius.horizontal(right: Radius.circular(3)),
                  ),
                  child: Column(
                    children: List.generate(
                      16,
                      (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 0.3),
                          color: i.isEven
                              ? const Color(0xFFEFE3CC)
                              : const Color(0xFFF7EFDF),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The cover, with its own shadow so it lifts off the shelf.
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(3),
                    right: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(3, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(3),
                    right: Radius.circular(8),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCover(),
                      // Spine shadow along the left edge.
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      // Gloss sheen, top-left to center.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.16),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                      ),
                      // Thin outer border for definition against light backgrounds.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.black.withOpacity(0.08)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCover() {
    final url = ebook.coverUrl;
    if (url != null && url.isNotEmpty) {
      final fullUrl =
          url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFEDE1CF),
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6B4226),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  /// A designed hardcover look for books with no cover image — an embossed
  /// frame, a book icon, and the title — rather than a flat color swatch.
  Widget _placeholder() {
    final palette = _palettes[ebook.id % _palettes.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.$1, palette.$2],
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1.2, color: Colors.white.withOpacity(0.55)),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white.withOpacity(0.85),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ebook.title,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1.2, color: Colors.white.withOpacity(0.55)),
        ],
      ),
    );
  }
}


const List<(Color, Color)> _palettes = [
  (Color(0xFF6B4226), Color(0xFF3A2712)),
  (Color(0xFF2B4C5C), Color(0xFF15262E)),
  (Color(0xFF5C3A5C), Color(0xFF2E1D2E)),
  (Color(0xFF3E5C3A), Color(0xFF1F2E1D)),
  (Color(0xFF7A5230), Color(0xFF3D2918)),
  (Color(0xFF4A5C6B), Color(0xFF262E35)),
];