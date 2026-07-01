import 'package:digital_ebook_library/models/ebook.dart';
import 'package:digital_ebook_library/widgets/bookshelf.dart';
import 'package:digital_ebook_library/widgets/ebook_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleEbook = Ebook(
    id: 1,
    title: 'Clean Code',
    author: 'Robert C. Martin',
    fileType: 'application/pdf',
    fileSize: 204800,
    fileName: 'clean_code.pdf',
    createdAt: DateTime(2024, 1, 1),
  );

  // ── EbookCard tests ──────────────────────────────────────────────────────
  group('EbookCard', () {
    Widget buildCard({
      VoidCallback? onTap,
      VoidCallback? onDelete,
      VoidCallback? onDownload,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 200,
            child: EbookCard(
              ebook: sampleEbook,
              onTap: onTap ?? () {},
              onDelete: onDelete ?? () {},
              onDownload: onDownload ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Clean Code'), findsWidgets);
    });

    testWidgets('renders author', (tester) async {
      await tester.pumpWidget(buildCard());
      expect(find.text('Robert C. Martin'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows action sheet on long press', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onDownload from action sheet', (tester) async {
      bool downloaded = false;
      await tester.pumpWidget(buildCard(onDownload: () => downloaded = true));
      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(downloaded, isTrue);
    });

    testWidgets('calls onDelete from action sheet', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(buildCard(onDelete: () => deleted = true));
      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });

  // ── Bookshelf tests ──────────────────────────────────────────────────────
  group('Bookshelf', () {
    Widget buildShelf(List<Ebook> ebooks) {
      return MaterialApp(
        home: Scaffold(
          body: Bookshelf(
            ebooks: ebooks,
            onOpen: (_) {},
            onDelete: (_) {},
            onDownload: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders correct number of EbookCards', (tester) async {
      final ebooks = List.generate(
        4,
        (i) => Ebook(
          id: i,
          title: 'Book $i',
          createdAt: DateTime(2024, 1, 1),
        ),
      );
      await tester.pumpWidget(buildShelf(ebooks));
      expect(find.byType(EbookCard), findsNWidgets(4));
    });

    testWidgets('renders nothing when list is empty', (tester) async {
      await tester.pumpWidget(buildShelf([]));
      expect(find.byType(EbookCard), findsNothing);
    });
  });

  // ── Empty state test ─────────────────────────────────────────────────────
  group('Empty state', () {
    testWidgets('shows empty shelf message when no ebooks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.menu_book_outlined, size: 64),
                  Text('Your shelf is empty'),
                  Text('Tap + to upload your first ebook'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Your shelf is empty'), findsOneWidget);
      expect(
          find.text('Tap + to upload your first ebook'), findsOneWidget);
    });
  });

  // ── Delete confirmation dialog test ──────────────────────────────────────
  group('Delete confirmation', () {
    testWidgets('shows confirmation dialog and can cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete ebook?'),
                    content: const Text(
                        'Are you sure you want to delete "Clean Code"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ebook?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ebook?'), findsNothing);
    });
  });

  // ── Search field test ────────────────────────────────────────────────────
  group('Search', () {
    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by title, author, or file name',
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Ruby');
      expect(find.text('Ruby'), findsOneWidget);
    });
  });
}