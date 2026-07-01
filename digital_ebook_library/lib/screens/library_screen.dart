import 'dart:async';
import 'package:digital_ebook_library/provider/ebook_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ebook.dart';
import '../widgets/bookshelf.dart';
import '../transitions/book_open_route.dart';
import 'reader_screen.dart';
import 'upload_screen.dart';

const _bgDark = Color(0xFF2B1A0E);
const _bgDarkLight = Color(0xFF4A2F18);
const _brown = Color(0xFF6B4226);
const _gold = Color(0xFFD9A05B);
const _cream = Color(0xFFF7EFE3);
const _ink = Color(0xFF3A2A1A);

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // NEW
  Timer? _debounce;

  static const String _woodTextureUrl =
      'https://images.unsplash.com/photo-1517167685826-11342067f7bb?q=80&w=1200&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EbookProvider>().loadEbooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // NEW
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<EbookProvider>().searchEbooks(query.trim());
    });
  }

  void _unfocusSearch() { // NEW helper
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> _deleteEbook(Ebook ebook) async {
    _unfocusSearch(); // NEW — close keyboard before showing dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete ebook?'),
        content: Text(
            'Are you sure you want to delete "${ebook.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<EbookProvider>().deleteEbook(ebook.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${ebook.title}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _downloadEbook(Ebook ebook) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading "${ebook.title}"...')),
    );
    try {
      final path = await context.read<EbookProvider>().downloadEbook(ebook);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _openEbook(Ebook ebook) {
    _unfocusSearch(); // NEW — prevents keyboard popping back on return
    Navigator.push(
      context,
      BookOpenRoute<void>(page: ReaderScreen(ebook: ebook)),
    );
  }

  Future<void> _goToUpload() async {
    _unfocusSearch(); // NEW
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    );
    if (uploaded == true && mounted) {
      context.read<EbookProvider>().loadEbooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // NEW — closes keyboard on outside tap
      behavior: HitTestBehavior.opaque,
      onTap: _unfocusSearch,
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          toolbarHeight: 64,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgDark, _bgDarkLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'My ', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'Bookshelf', style: TextStyle(color: _gold)),
              ],
            ),
          ),
          actions: [
            Consumer<EbookProvider>(
              builder: (context, provider, _) => PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white),
                tooltip: 'Sort',
                onSelected: (option) {
                  _unfocusSearch(); // NEW
                  provider.setSortOption(option);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: SortOption.recent,
                    child: Text('Recently Added'),
                  ),
                  PopupMenuItem(
                    value: SortOption.title,
                    child: Text('By Title'),
                  ),
                  PopupMenuItem(
                    value: SortOption.author,
                    child: Text('By Author'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => context.read<EbookProvider>().loadEbooks(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _goToUpload,
          backgroundColor: _brown,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _woodTextureUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : Container(color: _bgDark),
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: _bgDark),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.45),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode, // NEW
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: _ink),
                    decoration: InputDecoration(
                      hintText: 'Search by title, author, or file name',
                      hintStyle:
                          const TextStyle(color: Color(0xFFA6957F)),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: _brown),
                      filled: true,
                      fillColor: _cream.withOpacity(0.96),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: _brown),
                              onPressed: () {
                                _searchController.clear();
                                context.read<EbookProvider>().clearSearch();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<EbookProvider>(
      builder: (context, provider, _) {
        switch (provider.state) {
          case LoadState.loading:
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          case LoadState.error:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
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
                      onPressed: provider.loadEbooks,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          case LoadState.empty:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 64, color: _gold.withOpacity(0.9)),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Your shelf is empty'
                          : 'No ebooks match your search',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    if (_searchController.text.isEmpty)
                      const Text(
                        'Tap + to upload your first ebook',
                        style: TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            );
          case LoadState.loaded:
            return Bookshelf(
              ebooks: provider.ebooks,
              onOpen: _openEbook,
              onDelete: _deleteEbook,
              onDownload: _downloadEbook,
            );
        }
      },
    );
  }
}