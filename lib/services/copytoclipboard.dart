import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/constants.dart';

void copyToClipboardWithNotify(BuildContext context, String str,
    [String srcName = strEmpty]) {
  if (str.isEmpty) return;

  Clipboard.setData(ClipboardData(text: str));
  snackbarAlert(context,
      message: '${srcName.isNotEmpty ? srcName : strData} $strCopied.');
}
