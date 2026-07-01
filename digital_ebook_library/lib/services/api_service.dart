import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/ebook.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://192.168.0.105:3000';

  Future<List<Ebook>> fetchEbooks({String? sort}) async {
    final uri = Uri.parse('$baseUrl/api/ebooks').replace(
      queryParameters: sort != null ? {'sort': sort} : null,
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw ApiException('Failed to load ebooks (${res.statusCode})');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => Ebook.fromJson(e)).toList();
  }

  Future<List<Ebook>> searchEbooks(String query) async {
    final uri = Uri.parse('$baseUrl/api/ebooks/search')
        .replace(queryParameters: {'q': query});
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw ApiException('Search failed (${res.statusCode})');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => Ebook.fromJson(e)).toList();
  }

  Future<Ebook> uploadEbook({
    required String title,
    String? author,
    required String filePath,
    required String fileName,
    String? coverPath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/ebooks');
    final request = http.MultipartRequest('POST', uri);
    request.fields['title'] = title;
    if (author != null && author.isNotEmpty) {
      request.fields['author'] = author;
    }
    request.files.add(await http.MultipartFile.fromPath(
      'file', filePath,
      filename: fileName,
    ));
    if (coverPath != null) {
      request.files
          .add(await http.MultipartFile.fromPath('cover', coverPath));
    }
    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode == 201) {
      return Ebook.fromJson(jsonDecode(res.body));
    } else {
      final body = jsonDecode(res.body);
      final errors = (body['errors'] as List?)?.join(', ') ??
          body['error'] ??
          'Upload failed';
      throw ApiException(errors);
    }
  }

  Future<void> deleteEbook(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/api/ebooks/$id'));
    if (res.statusCode != 204) {
      throw ApiException('Failed to delete ebook (${res.statusCode})');
    }
  }

  Future<String> downloadEbook(Ebook ebook) async {
    final dir = await getApplicationDocumentsDirectory();
    final savePath =
        '${dir.path}/${ebook.fileName ?? 'ebook_${ebook.id}.pdf'}';
    final dio = Dio();
    try {
      await dio.download(
          '$baseUrl/api/ebooks/${ebook.id}/download', savePath);
      return savePath;
    } on DioException catch (e) {
      throw ApiException('Download failed: ${e.message}');
    }
  }

  Future<File> localFileIfExists(Ebook ebook) async {
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/${ebook.fileName ?? 'ebook_${ebook.id}.pdf'}';
    return File(path);
  }
}