import 'dart:async';

import 'package:mobook/models/db.dart';
import 'package:mobook/models/book.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobook/utils/file_utils.dart';

enum AudioEvent {
  play,
  pause,
  stop,
  seek,
  gotBook,
  lostBook,
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
        if (currentBook?.nextChapter != null) {
          setCurrentBook(_currentBookId, currentBook!.nextChapter!.id);
        }
      });
      _audioEventStreamController.add(AudioEvent.stop);
    });
  }
  static final AudioController _instance = AudioController._();
  static AudioController get instance => _instance;

  String? _currentBookId;
  Book? get currentBook => _currentBookId != null ? DB.instance.books[_currentBookId] : null;
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

  void setCurrentBook(String? bookId, [String? chapterId]) {
    _currentBookId = bookId;
    if (chapterId != null) {
      final newBook = currentBook!.copyWith(currentChapterId: chapterId);
      DB.instance.updateBook(newBook);
    }
    _audioEventStreamController.add(AudioEvent.gotBook);
  }

  void play([String? bookId, String? chapterId]) async {
    if (isPlaying) {
      await pause();
    }

    if (bookId != null) {
      setCurrentBook(bookId, chapterId);
    }

    if (_currentBookId == null) return;

    if (_player.source != null && bookId == null && chapterId == null) {
      await _player.resume();
    } else if (currentBook!.currentChapter != null) {
      await _player.play(DeviceFileSource((await FileUtils.getLocalFile(currentBook!.currentChapterId)).path));
      _player.seek(Duration(milliseconds: currentBook!.currentChapter!.position));
    }
    _audioEventStreamController.add(AudioEvent.play);
  }

  void seekTo(int pos) {
    _player.seek(Duration(milliseconds: pos));
    _audioEventStreamController.add(AudioEvent.seek);
  }

  Future<void> pause() async {
    _player.pause();

    if (_currentBookId == null) {
      return;
    }
    await _saveCurrentPosition();

    _audioEventStreamController.add(AudioEvent.pause);
  }

  void stop() {
    _player.stop();
    _audioEventStreamController.add(AudioEvent.stop);
    _currentBookId = null;
    _currentPosition = 0;
    _duration = 0;
  }

  Future<void> _saveCurrentPosition([bool hasFinished = false]) async {
    final currentPos = await _player.getCurrentPosition();
    Book newBook = currentBook!.copyWithNewSeekPosition(currentPos?.inMilliseconds ?? 0);

    if (((currentPos?.inMilliseconds ?? 1) / _duration) > 0.99 || hasFinished) {
      newBook = newBook.copyWithNewCompletionStatus(true);
    }

    DB.instance.updateBook(newBook);
  }
}
