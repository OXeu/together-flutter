import 'package:flutter/material.dart';

extension DurationExt on Duration {
  String string() {
    return "${inHours == 0 ? "" : "$inHours:"}"
        "${inMinutes % 60 < 10 ? "0${inMinutes%60}" : inMinutes % 60}:"
        "${inSeconds % 60 < 10 ? "0${inSeconds%60}" : inSeconds % 60}";
  }
}

extension Landscape on BuildContext{
  bool landscape(){
    return MediaQuery.of(this).size.width >
        MediaQuery.of(this).size.height;
  }
}