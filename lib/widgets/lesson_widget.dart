import 'package:flutter/material.dart';
import 'package:molang/models/audio_controller.dart';
import 'package:molang/models/db.dart';
import 'package:molang/models/lang.dart';

class LessonWidget extends StatefulWidget {
  const LessonWidget({required this.langId, required this.lessonId, super.key});

  final String langId;
  final String lessonId;

  @override
  State<LessonWidget> createState() => _LessonWidgetState();
}

class _LessonWidgetState extends State<LessonWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            IconButton.filled(
              onPressed: () {
                AudioController.instance.play(widget.langId, widget.lessonId);
              },
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DB.instance.langs[widget.langId]?.lessons[widget.lessonId]?.name ?? "Unknown Lesson",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (DB.instance.langs[widget.langId]?.lessons[widget.lessonId]?.isCompleted ?? false)
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: () {
                  Lang newLang = DB.instance.langs[widget.langId]!;
                  newLang = newLang.copyWith(currentLessonId: widget.lessonId);
                  newLang = newLang.copyWithNewCompletionStatus(false);
                  newLang = newLang.copyWith(currentLessonId: DB.instance.langs[widget.langId]!.currentLessonId);

                  DB.instance.updateLang(newLang);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}
