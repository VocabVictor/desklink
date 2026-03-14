import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static final homeKey = GlobalKey<_HomePageState>();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool get isChatPageCurrentTab => false;

  void refreshPages() {}

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
