import 'dart:async';

import 'package:molang/models/db.dart';
import 'package:molang/models/lang.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:molang/utils/file_utils.dart';

enum AudioEvent {
  play,
  pause,
  stop,
  seek,
  gotLang,
  lostLang,
}

class AudioController {
  AudioController._() {
    _player.onDurationChanged.listen((event) {
      _duration = event.inMilliseconds;
    });
    _player.onPositionChanged.listen((event) {
      _currentPosition = event.inMilliseconds;
      _positionStreamController.add(_currentPosition);
    });
    _player.onPlayerComplete.listen((event) {
      _saveCurrentPosition(true).then((value) {
        if (currentLang?.nextLesson != null) {
          setCurrentLang(_currentLangId, currentLang!.nextLesson!.id);
        }
      });
      _audioEventStreamController.add(AudioEvent.stop);
    });
  }
  static final AudioController _instance = AudioController._();
  static AudioController get instance => _instance;

  String? _currentLangId;
  Lang? get currentLang => _currentLangId != null ? DB.instance.langs[_currentLangId] : null;
  final _player = AudioPlayer();
  int _currentPosition = 0;
  int _duration = 0;

  int get currentPosition => _currentPosition;
  int get duration => _duration;
  bool get isPlaying => _player.state == PlayerState.playing;

  final StreamController<AudioEvent> _audioEventStreamController = StreamController<AudioEvent>.broadcast();
  final StreamController<int> _positionStreamController = StreamController<int>.broadcast();

  Stream<AudioEvent> get onAudioEvent => _audioEventStreamController.stream;
  Stream<int> get onPositionChanged => _positionStreamController.stream;

  void setCurrentLang(String? langId, [String? lessonId]) {
    _currentLangId = langId;
    if (lessonId != null) {
      final newLang = currentLang!.copyWith(currentLessonId: lessonId);
      DB.instance.updateLang(newLang);
    }
    _audioEventStreamController.add(AudioEvent.gotLang);
  }

  void play([String? langId, String? lessonId]) async {
    if (isPlaying) {
      await pause();
    }

    if (langId != null) {
      setCurrentLang(langId, lessonId);
    }

    if (_currentLangId == null) return;

    if (_player.source != null && langId == null && lessonId == null) {
      await _player.resume();
    } else if (currentLang!.currentLesson != null) {
      await _player.play(DeviceFileSource((await FileUtils.getLocalFile(currentLang!.currentLessonId)).path));
      _player.seek(Duration(milliseconds: currentLang!.currentLesson!.position));
    }
    _audioEventStreamController.add(AudioEvent.play);
  }

  void seekTo(int pos) {
    _player.seek(Duration(milliseconds: pos));
    _audioEventStreamController.add(AudioEvent.seek);
  }

  Future<void> pause() async {
    _player.pause();

    if (_currentLangId == null) {
      return;
    }
    await _saveCurrentPosition();

    _audioEventStreamController.add(AudioEvent.pause);
  }

  void stop() {
    _player.stop();
    _audioEventStreamController.add(AudioEvent.stop);
    _currentLangId = null;
    _currentPosition = 0;
    _duration = 0;
  }

  Future<void> _saveCurrentPosition([bool hasFinished = false]) async {
    final currentPos = await _player.getCurrentPosition();
    Lang newLang = currentLang!.copyWithNewSeekPosition(currentPos?.inMilliseconds ?? 0);

    if (((currentPos?.inMilliseconds ?? 1) / _duration) > 0.99 || hasFinished) {
      newLang = newLang.copyWithNewCompletionStatus(true);
    }

    DB.instance.updateLang(newLang);
  }
}
