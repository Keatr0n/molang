import 'dart:io';

import 'package:mobook/models/chapter.dart';
import 'package:mobook/utils/file_utils.dart';

class Book {
  Book(this.id, this.name, this.chapters, this.currentChapterId);

  /// Id doubles as file position on disk
  final String id;
  final String name;
  final Map<String, Chapter> chapters;
  final String currentChapterId;

  Chapter? get currentChapter => chapters[currentChapterId];
  Chapter? get nextChapter {
    final chapterIds = chapters.keys.toList();
    final currentChapterIndex = chapterIds.indexOf(currentChapterId);
    if (currentChapterIndex == -1) return null;
    if (currentChapterIndex == chapterIds.length - 1) return null;
    return chapters[chapterIds[currentChapterIndex + 1]];
  }

  Book copyWith({String? name, Map<String, Chapter>? chapters, String? currentChapterId}) {
    return Book(
      id,
      name ?? this.name,
      chapters ?? this.chapters,
      currentChapterId ?? this.currentChapterId,
    );
  }

  Book copyWithNewSeekPosition(int newPosition) {
    final newChapters = chapters;
    newChapters[currentChapterId] = newChapters[currentChapterId]?.copyWith(position: newPosition) ?? const Chapter('', '', 0, false);
    return Book(
      id,
      name,
      newChapters,
      currentChapterId,
    );
  }

  Book copyWithNewCompletionStatus(bool isCompleted) {
    final newChapters = chapters;
    newChapters[currentChapterId] = newChapters[currentChapterId]?.copyWith(isCompleted: isCompleted) ?? const Chapter('', '', 0, false);
    return Book(
      id,
      name,
      newChapters,
      currentChapterId,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      json['id'] as String,
      json['name'] as String,
      (json['chapters'] as Map<String, dynamic>).map((k, e) => MapEntry(k, Chapter.fromJson(e))),
      json['currentChapterId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chapters': chapters.map((k, e) => MapEntry(k, e.toJson())),
      'currentChapterId': currentChapterId,
    };
  }

  static Future<Book> fromFile(File file, String name) async {
    final path = await FileUtils.getLocalPath();

    final fileName = file.path.split('/').last.split('\\').last.split('.').first;

    await Directory('$path/books').create(recursive: true);

    await file.copy('$path/books/$fileName.zip');

    final unzipped = await FileUtils.extractZip("books/$fileName.zip", true);

    if (unzipped == null) {
      throw Exception('Failed to unzip file');
    }

    Map<String, Chapter> chapters = {};

    Future<void> findAndAddFiles(Directory directory) async {
      final List<Directory> subDirs = [];

      final contents = await directory.list().toList();

      contents.sort((a, b) => a.path.compareTo(b.path));

      for (var i = 0; i < contents.length; i++) {
        final element = contents[i];

        if (element is File) {
          if (element.path.split(".").last.toLowerCase().contains("mp3")) {
            await element.rename("$path/books/$fileName/${chapters.length}.mp3");
            chapters["books/$fileName/${chapters.length}.mp3"] = Chapter("books/$fileName/${chapters.length}.mp3", "Chapter ${chapters.length + 1}", 0, false);
          }
        } else if (element is Directory) {
          subDirs.add(element);
        }
      }

      for (var i = 0; i < subDirs.length; i++) {
        await findAndAddFiles(subDirs[i]);
      }
    }

    await findAndAddFiles(unzipped);

    // clean up

    final files = await unzipped.list().toList();

    for (var i = files.length - 1; i >= 0; i--) {
      if (!files[i].path.split(".").last.toLowerCase().contains("mp3")) {
        await files[i].delete(recursive: true);
      }
    }

    return Book("books/$fileName", name, chapters, chapters.keys.first);
  }
}
