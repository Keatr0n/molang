import 'package:flutter/material.dart';
import 'package:mobook/models/audio_controller.dart';
import 'package:mobook/models/db.dart';
import 'package:mobook/models/book.dart';

class ChapterWidget extends StatefulWidget {
  const ChapterWidget({required this.bookId, required this.chapterId, super.key});

  final String bookId;
  final String chapterId;

  @override
  State<ChapterWidget> createState() => _ChapterWidgetState();
}

class _ChapterWidgetState extends State<ChapterWidget> {
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
                AudioController.instance.play(widget.bookId, widget.chapterId);
              },
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DB.instance.books[widget.bookId]?.chapters[widget.chapterId]?.name ?? "Unknown Chapter",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (DB.instance.books[widget.bookId]?.chapters[widget.chapterId]?.isCompleted ?? false)
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: () {
                  Book newBook = DB.instance.books[widget.bookId]!;
                  newBook = newBook.copyWith(currentChapterId: widget.chapterId);
                  newBook = newBook.copyWithNewCompletionStatus(false);
                  newBook = newBook.copyWith(currentChapterId: DB.instance.books[widget.bookId]!.currentChapterId);

                  DB.instance.updateBook(newBook);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}
