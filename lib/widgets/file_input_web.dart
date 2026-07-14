import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _registered = false;

Widget createWebFileInput({
  required String viewId,
  required Function(List<int> bytes) onFileSelected,
}) {
  if (!_registered) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final input = html.InputElement(type: 'file')
        ..accept = 'image/*'
        ..style.color = 'white'
        ..style.padding = '8px 12px'
        ..style.borderRadius = '8px'
        ..style.border = '1px dashed #009688'
        ..style.backgroundColor = 'rgba(0, 150, 136, 0.1)'
        ..style.fontSize = '12px'
        ..style.cursor = 'pointer'
        ..style.outline = 'none';

      input.onChange.listen((e) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            final bytes = reader.result as List<int>;
            onFileSelected(bytes);
          });
        }
      });
      return input;
    });
    _registered = true;
  }

  return SizedBox(
    width: 300,
    height: 50,
    child: HtmlElementView(viewType: viewId),
  );
}
