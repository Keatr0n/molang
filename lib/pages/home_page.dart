import 'dart:async';

import 'package:flutter/material.dart';
import 'package:molang/models/db.dart';
import 'package:molang/widgets/add_lang_widget.dart';
import 'package:molang/widgets/bottom_sheet_player_widget.dart';
import 'package:molang/widgets/lang_widget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final StreamSubscription _updateDbStreamSubscription;

  @override
  void dispose() {
    _updateDbStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _updateDbStreamSubscription = DB.instance.updateDbStream.listen((_) {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Text('MOLANG', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const Divider(),
            ...DB.instance.langs.values.map((e) => LangWidget(lang: e)).toList(),
            const AddLangWidget(),
          ],
        ),
      ),
      bottomSheet: const BottomSheetPlayer(),
    );
  }
}
