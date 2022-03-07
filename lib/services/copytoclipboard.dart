import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

void copyToClipboardWithNotify(BuildContext context, String str,
    [String srcName = '']) {
  if (str.isEmpty) return;

  Clipboard.setData(ClipboardData(text: str));
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('${srcName.isNotEmpty ? srcName : 'Data'} copied.'),
    // backgroundColor: Colors.green,
    duration: const Duration(seconds: 4),
  ));
}
