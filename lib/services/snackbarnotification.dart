import 'package:flutter/material.dart';

void snackbarAlert(BuildContext context,
    {required String message, Color? backgroundColor}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor,
    duration: const Duration(seconds: 4),
  ));
}
