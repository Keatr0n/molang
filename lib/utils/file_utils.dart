import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getLocalFile(String filename) async {
    final path = await getLocalPath();

    if (Platform.isWindows) return File('$path\\${filename.replaceAll("/", "\\")}');
    return File('$path/$filename');
  }

  static Future<String> readLocalFile(String filename) async {
    try {
      final file = await getLocalFile(filename);
      if (!(await file.exists())) {
        return "";
      }
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return "ERROR: $e";
    }
  }

  static Future<Directory?> extractZip(String filename, [bool deleteZipFile = false]) async {
    try {
      final file = await getLocalFile(filename);

      if (!(await file.exists())) {
        return null;
      }

      final inputStream = InputFileStream(file.path);

      final archive = await compute<InputFileStream, Archive>((input) => ZipDecoder().decodeBuffer(input), inputStream);
      // For all of the entries in the archive

      final localPath = await getLocalPath();

      final List<Future> futures = [];

      for (var file in archive.files) {
        // If it's a file and not a directory
        if (file.isFile) {
          final outputStream = OutputFileStream('$localPath/${filename.split(".").first}/${file.name}');

          file.writeContent(outputStream);

          futures.add(outputStream.close());
        }
      }

      await Future.wait(futures);

      await inputStream.close();

      if (deleteZipFile) {
        await file.delete();
      }

      return Directory('$localPath/${filename.split(".").first}');
    } catch (e) {
      return null;
    }
  }

  static Future<File> writeLocalFile(String filename, String content) async {
    final file = await getLocalFile(filename);
    return file.writeAsString(content);
  }

  /// returns null if file deletion was successful
  /// returns error message if file deletion failed
  static Future<String?> deleteLocalFile(String filename) async {
    final file = await getLocalFile(filename);
    try {
      await file.delete();
    } catch (e) {
      return "ERROR: $e";
    }
    return null;
  }
}
