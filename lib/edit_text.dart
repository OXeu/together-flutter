import 'package:flutter/material.dart';

class EditText extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode node;
  final String? hint;
  final Color? background;
  final Color? textColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const EditText(
      {Key? key,
      required this.controller,
      required this.node,
      this.hint,
      this.background, this.textColor, this.padding, this.margin})
      : super(key: key);

  @override
  State<EditText> createState() => _EditTextState();
}

class _EditTextState extends State<EditText> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
          color: widget.background ?? Colors.white30,
          borderRadius: BorderRadius.circular(8)),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      margin: widget.margin ?? const EdgeInsets.all(8),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration.collapsed(hintText: widget.hint),
        // autofocus: true,
        cursorColor: Colors.blueAccent,
        focusNode: widget.node,
        style: TextStyle(
          color: widget.textColor ?? Colors.white,
        ),
        // selectionColor: Colors.black12,
        // backgroundCursorColor: Colors.grey,
        maxLines: null,
        minLines: 1,
        // keyboardType: TextInputType.multiline,
        // expands: true,
      ),
    );
  }
}
