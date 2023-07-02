import 'dart:io';

import 'package:molang/models/lesson.dart';
import 'package:molang/utils/file_utils.dart';

class Lang {
  Lang(this.id, this.name, this.lessons, this.currentLessonId);

  /// Id doubles as file position on disk
  final String id;
  final String name;
  final Map<String, Lesson> lessons;
  final String currentLessonId;

  Lesson? get currentLesson => lessons[currentLessonId];
  Lesson? get nextLesson {
    final lessonIds = lessons.keys.toList();
    final currentLessonIndex = lessonIds.indexOf(currentLessonId);
    if (currentLessonIndex == -1) return null;
    if (currentLessonIndex == lessonIds.length - 1) return null;
    return lessons[lessonIds[currentLessonIndex + 1]];
  }

  Lang copyWith({String? name, Map<String, Lesson>? lessons, String? currentLessonId}) {
    return Lang(
      id,
      name ?? this.name,
      lessons ?? this.lessons,
      currentLessonId ?? this.currentLessonId,
    );
  }

  Lang copyWithNewSeekPosition(int newPosition) {
    final newLessons = lessons;
    newLessons[currentLessonId] = newLessons[currentLessonId]?.copyWith(position: newPosition) ?? const Lesson('', '', 0, false);
    return Lang(
      id,
      name,
      newLessons,
      currentLessonId,
    );
  }

  Lang copyWithNewCompletionStatus(bool isCompleted) {
    final newLessons = lessons;
    newLessons[currentLessonId] = newLessons[currentLessonId]?.copyWith(isCompleted: isCompleted) ?? const Lesson('', '', 0, false);
    return Lang(
      id,
      name,
      newLessons,
      currentLessonId,
    );
  }

  factory Lang.fromJson(Map<String, dynamic> json) {
    return Lang(
      json['id'] as String,
      json['name'] as String,
      (json['lessons'] as Map<String, dynamic>).map((k, e) => MapEntry(k, Lesson.fromJson(e))),
      json['currentLessonId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lessons': lessons.map((k, e) => MapEntry(k, e.toJson())),
      'currentLessonId': currentLessonId,
    };
  }

  static Future<Lang> fromFile(File file, String name) async {
    final path = await FileUtils.getLocalPath();

    final fileName = file.path.split('/').last.split('\\').last.split('.').first;

    await Directory('$path/langs').create(recursive: true);

    await file.copy('$path/langs/$fileName.zip');

    final unzipped = await FileUtils.extractZip("langs/$fileName.zip", true);

    if (unzipped == null) {
      throw Exception('Failed to unzip file');
    }

    Map<String, Lesson> lessons = {};

    Future<void> findAndAddFiles(Directory directory) async {
      final List<Directory> subDirs = [];

      final contents = await directory.list().toList();

      contents.sort((a, b) => a.path.compareTo(b.path));

      for (var i = 0; i < contents.length; i++) {
        final element = contents[i];

        if (element is File) {
          if (element.path.split(".").last.toLowerCase().contains("mp3")) {
            await element.rename("$path/langs/$fileName/${lessons.length}.mp3");
            lessons["langs/$fileName/${lessons.length}.mp3"] = Lesson("langs/$fileName/${lessons.length}.mp3", "Lesson ${lessons.length + 1}", 0, false);
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

    return Lang("langs/$fileName", name, lessons, lessons.keys.first);
  }
}
