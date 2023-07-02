import 'dart:async';
import 'dart:convert';

import 'package:molang/models/job_scheduler.dart';
import 'package:molang/models/lang.dart';
import 'package:molang/utils/file_utils.dart';

class DB {
  DB._();
  static final DB _instance = DB._();
  static DB get instance => _instance;

  static const String fileName = 'DB.json';

  final StreamController _updateDbStreamController = StreamController.broadcast();
  Stream get updateDbStream => _updateDbStreamController.stream;

  bool _initialized = false;

  final Map<String, Lang> _langs = {};
  Map<String, Lang> get langs => _langs;

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

    for (var i = 0; i < jsonData['langs'].length; i++) {
      final lang = Lang.fromJson(jsonData['langs'][i]);
      _langs[lang.id] = lang;
    }

    _initialized = true;

    return;
  }

  Future<void> save() async {
    _updateDbStreamController.add(null);

    final jsonString = jsonEncode({
      'langs': _langs.values.map((e) => e.toJson()).toList(),
    });

    await FileUtils.writeLocalFile(fileName, jsonString);

    return;
  }

  void deleteLang(Lang lang) {
    for (var element in lang.lessons.values) {
      FileUtils.deleteLocalFile(element.id);
    }

    _langs.remove(lang.id);
    _jobScheduler.addJob(save);
  }

  /// This will add a new lang to the DB if it doesn't already exist
  void updateLang(Lang lang) {
    _langs[lang.id] = lang;
    _jobScheduler.addJob(save);
  }
}
