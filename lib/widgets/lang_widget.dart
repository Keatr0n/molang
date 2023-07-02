import 'package:flutter/material.dart';
import 'package:molang/models/audio_controller.dart';
import 'package:molang/models/db.dart';
import 'package:molang/models/lang.dart';

class LangWidget extends StatelessWidget {
  const LangWidget({required this.lang, super.key});

  final Lang lang;

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
                AudioController.instance.play(lang.id);
              },
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Lang'),
                    content: Text('Are you sure you want to delete ${lang.name}?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        onPressed: () {
                          if (AudioController.instance.currentLang?.id == lang.id) {
                            AudioController.instance.stop();
                          }
                          DB.instance.deleteLang(lang);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
