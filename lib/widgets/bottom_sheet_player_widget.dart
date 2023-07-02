import 'dart:async';

import 'package:flutter/material.dart';
import 'package:molang/models/audio_controller.dart';
import 'package:molang/widgets/lesson_widget.dart';

class BottomSheetPlayer extends StatefulWidget {
  const BottomSheetPlayer({super.key});

  @override
  State<BottomSheetPlayer> createState() => _BottomSheetPlayerState();
}

class _BottomSheetPlayerState extends State<BottomSheetPlayer> {
  double height = 0;
  Duration duration = const Duration(milliseconds: 300);

  double get minHeight => MediaQuery.of(context).size.height * 0.14;
  double get maxHeight => MediaQuery.of(context).size.height * 0.8;

  late final StreamSubscription<AudioEvent> audioEventStreamSubscription;
  late final StreamSubscription audioPositionStreamSubscription;

  @override
  void initState() {
    super.initState();
    audioEventStreamSubscription = AudioController.instance.onAudioEvent.listen((event) {
      if (event == AudioEvent.gotLang) {
        setState(() {
          height = minHeight;
        });
      }
      if (event == AudioEvent.stop) {
        setState(() {
          height = 0;
        });
      }
      if (event == AudioEvent.pause) {
        if (mounted) setState(() {});
      }
    });

    audioPositionStreamSubscription = AudioController.instance.onPositionChanged.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    audioEventStreamSubscription.cancel();
    super.dispose();
  }

  getProgressValue() {
    if (AudioController.instance.duration == 0) return 0.0;
    return AudioController.instance.currentPosition / AudioController.instance.duration;
  }

  @override
  Widget build(BuildContext context) {
    height = height.clamp(0, maxHeight);

    return AnimatedContainer(
      curve: Curves.easeInOutCubicEmphasized,
      duration: duration,
      height: height,
      width: MediaQuery.of(context).size.width,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onVerticalDragStart: (details) {
              duration = const Duration(milliseconds: 0);
            },
            onVerticalDragUpdate: (details) {
              setState(() {
                height = MediaQuery.of(context).size.height - details.globalPosition.dy;
              });
            },
            onVerticalDragEnd: (details) {
              duration = const Duration(milliseconds: 300);
              if ((details.primaryVelocity ?? 0) < 10) {
                setState(() {
                  height = maxHeight;
                });
              } else if ((details.primaryVelocity ?? 0) > -10) {
                setState(() {
                  height = minHeight;
                });
              } else {
                if (height > maxHeight / 2) {
                  setState(() {
                    height = maxHeight;
                  });
                } else {
                  setState(() {
                    height = minHeight;
                  });
                }
              }
            },
            child: Container(
              color: Colors.transparent,
              height: 20,
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Container(
                  width: 100,
                  height: 4,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            height: (height - minHeight).clamp(0, maxHeight),
            duration: duration,
            curve: Curves.easeInOutCubicEmphasized,
            child: ListView(
              children: [for (var lesson in (AudioController.instance.currentLang?.lessons.values.toList() ?? [])) LessonWidget(langId: AudioController.instance.currentLang?.id ?? "", lessonId: lesson.id)],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (AudioController.instance.isPlaying) {
                      AudioController.instance.pause();
                    } else {
                      AudioController.instance.play();
                    }
                  },
                  icon: Icon(AudioController.instance.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
                    ),
                    child: Slider(
                      value: getProgressValue(),
                      onChangeStart: (value) => AudioController.instance.pause(),
                      onChanged: (value) {
                        AudioController.instance.seekTo((value * AudioController.instance.duration).round());
                      },
                      onChangeEnd: (value) => AudioController.instance.play(),
                      activeColor: Theme.of(context).colorScheme.onSurface,
                      inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
