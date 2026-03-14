import 'package:flutter/material.dart';

abstract class PageShape {
  String get title;
  Widget get icon;
  List<Widget> get appBarActions;
}
