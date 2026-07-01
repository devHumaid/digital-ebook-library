import 'package:flutter/material.dart';
import '../models/ebook.dart';
import '../services/api_service.dart';

enum SortOption { recent, title, author }
enum LoadState { loading, loaded, empty, error }

class EbookProvider extends ChangeNotifier {
  final ApiService _api;

  // CHANGED: _api is now injectable so tests can supply a fake instead of
  // hitting the real network. Production code is unaffected — calling
  // EbookProvider() with no args still uses a real ApiService.
  EbookProvider({ApiService? api}) : _api = api ?? ApiService();

  List<Ebook> _ebooks = [];
  LoadState _state = LoadState.loading;
  String _errorMessage = '';
  SortOption _sortOption = SortOption.recent;
  String _searchQuery = '';

  List<Ebook> get ebooks => _ebooks;
  LoadState get state => _state;
  String get errorMessage => _errorMessage;
  SortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;

  Future<void> loadEbooks() async {
    _state = LoadState.loading;
    notifyListeners();
    try {
      final ebooks = await _api.fetchEbooks(sort: _sortOption.name);
      _ebooks = ebooks;
      _state = ebooks.isEmpty ? LoadState.empty : LoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<String> downloadEbook(Ebook ebook) async {
    return _api.downloadEbook(ebook);
  }

  Future<void> searchEbooks(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      await loadEbooks();
      return;
    }
    _state = LoadState.loading;
    notifyListeners();
    try {
      final results = await _api.searchEbooks(query.trim());
      _ebooks = results;
      _state = results.isEmpty ? LoadState.empty : LoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    loadEbooks();
  }

  Future<void> deleteEbook(int id) async {
    await _api.deleteEbook(id);
    _ebooks.removeWhere((e) => e.id == id);
    if (_ebooks.isEmpty) _state = LoadState.empty;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    loadEbooks();
  }
}