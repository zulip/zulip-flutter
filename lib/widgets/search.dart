import 'package:flutter/material.dart';

import 'icons.dart';
import 'theme.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        autocorrect: false,
        cursorColor: designVariables.textInput,
        style: TextStyle(
          color: designVariables.textInput,
          fontSize: 17,
          height: 22 / 17,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: designVariables.labelSearchPrompt,
            fontSize: 17,
            height: 22 / 17),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
            child: Icon(size: 20, ZulipIcons.search)),
          prefixIconColor: designVariables.labelSearchPrompt,
          prefixIconConstraints: const BoxConstraints(),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          filled: true,
          fillColor: designVariables.bgSearchInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        )));
  }
}
