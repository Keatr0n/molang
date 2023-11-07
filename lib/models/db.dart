import 'dart:async';
import 'dart:convert';

import 'package:mobook/models/job_scheduler.dart';
import 'package:mobook/models/book.dart';
import 'package:mobook/utils/file_utils.dart';

class DB {
  DB._();
  static final DB _instance = DB._();
  static DB get instance => _instance;

  static const String fileName = 'DB.json';

  final StreamController _updateDbStreamController = StreamController.broadcast();
  Stream get updateDbStream => _updateDbStreamController.stream;

  bool _initialized = false;

  final Map<String, Book> _books = {};
  Map<String, Book> get books => _books;

  final JobScheduler _jobScheduler = JobScheduler();

  Future<void> init() async {
    if (_initialized) return;

    final jsonString = await FileUtils.readLocalFile(fileName);

    if (jsonString.startsWith("ERROR:")) {
      throw Exception(jsonString);
    }

    if (jsonString.isEmpty) {
      _initialized = true;
      return;
    }

    final jsonData = jsonDecode(jsonString);

    for (var i = 0; i < jsonData['books'].length; i++) {
      final book = Book.fromJson(jsonData['books'][i]);
      _books[book.id] = book;
    }

    _initialized = true;

    return;
  }

  Future<void> save() async {
    _updateDbStreamController.add(null);

    final jsonString = jsonEncode({
      'books': _books.values.map((e) => e.toJson()).toList(),
    });

    await FileUtils.writeLocalFile(fileName, jsonString);

    return;
  }

  void deleteBook(Book book) {
    for (var element in book.chapters.values) {
      FileUtils.deleteLocalFile(element.id);
    }

    _books.remove(book.id);
    _jobScheduler.addJob(save);
  }

  /// This will add a new book to the DB if it doesn't already exist
  void updateBook(Book book) {
    _books[book.id] = book;
    _jobScheduler.addJob(save);
  }
}
