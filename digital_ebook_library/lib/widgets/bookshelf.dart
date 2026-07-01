import 'package:flutter/material.dart';
import '../models/ebook.dart';
import 'ebook_card.dart';

/// Displays ebooks in a grid where each row sits on a wooden shelf strip,
/// mimicking the classic iOS Books app bookshelf look.
class Bookshelf extends StatelessWidget {
  final List<Ebook> ebooks;
  final void Function(Ebook) onOpen;
  final void Function(Ebook) onDelete;
  final void Function(Ebook) onDownload;

  const Bookshelf({
    super.key,
    required this.ebooks,
    required this.onOpen,
    required this.onDelete,
    required this.onDownload,
  });

  static const int columns = 3;

  @override
  Widget build(BuildContext context) {
    final rows = (ebooks.length / columns).ceil();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: rows,
      itemBuilder: (context, rowIndex) {
        final start = rowIndex * columns;
        final end = (start + columns).clamp(0, ebooks.length);
        final rowBooks = ebooks.sublist(start, end);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    ...rowBooks.map(
                      (e) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: EbookCard(
                            ebook: e,
                            onTap: () => onOpen(e),
                            onDelete: () => onDelete(e),
                            onDownload: () => onDownload(e),
                          ),
                        ),
                      ),
                    ),
                    // Fill remaining slots in the last row so the shelf still looks full-width
                    for (int i = rowBooks.length; i < columns; i++)
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // The wooden shelf strip — a top highlight plus a deeper
              // gradient body reads as a lit, rounded edge of real wood.
              Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C6B3E), Color(0xFF4A2F18)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.9],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}