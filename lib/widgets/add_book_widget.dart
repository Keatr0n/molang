import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobook/models/db.dart';
import 'package:mobook/models/book.dart';

class AddBookWidget extends StatelessWidget {
  const AddBookWidget({super.key});

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
                showDialog(context: context, builder: (context) => const AddBookDialog());
              },
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Book",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBookDialog extends StatefulWidget {
  const AddBookDialog({super.key});

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fileController = TextEditingController();
  File? file;
  // 0 = not started, 1 = processing, 2 = done
  int processingState = 0;

  @override
  void initState() {
    FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']).then((result) async {
      if (result != null) {
        file = File(result.files.single.path!);
        fileController.text = file!.path;
        setState(() {});
      } else {
        Navigator.pop(context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return const Dialog(child: Center(child: Text('Loading...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500))));
    }

    if (processingState == 1) {
      return const Dialog(child: Center(child: Text('Unzipping...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500))));
    }

    if (processingState == 2) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Done', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fileController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'File',
              ),
              readOnly: true,
              onTap: () async {
                FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']).then((result) async {
                  if (result != null) {
                    file = File(result.files.single.path!);
                    fileController.text = file!.path;
                    if (mounted) setState(() {});
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    setState(() => processingState = 1);

                    // probably use compute or something to make this a little nicer

                    final book = await Book.fromFile(file!, nameController.text);
                    DB.instance.updateBook(book);

                    if (mounted) {
                      setState(() => processingState = 2);
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
