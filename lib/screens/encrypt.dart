import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';

import 'dialogs.dart';
import 'scanner.dart';

class EncryptDecrypt extends StatefulWidget {
  final String selectedKey;
  const EncryptDecrypt({Key? key, required this.selectedKey}) : super(key: key);

  @override
  _EncryptDecryptState createState() => _EncryptDecryptState();
}

class _EncryptDecryptState extends State<EncryptDecrypt> {
  final _input = TextEditingController(text: strEmpty);
  final _otherPubkey = TextEditingController(text: strEmpty);
  final _output = TextEditingController(text: strEmpty);

  static const _strCipherMsg = strCipherMsg;

  var cipherMsg = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(strEncryptMessage),
        actions: _output.text.isEmpty
            ? null
            : [
                IconButton(
                    tooltip: tipCopyCipherMsg,
                    onPressed: () {
                      copyToClipboardWithNotify(
                          context, jsonEncode(cipherMsg), strCipherMsg);
                    },
                    icon: const Icon(Icons.copy)),
                IconButton(
                    tooltip: tipShowQrCode,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => QrDataDialog(
                                title: strCipherMsg,
                                data: jsonEncode(cipherMsg),
                              ));
                    },
                    icon: const Icon(Icons.qr_code)),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
                    ],
                    onChanged: (value) {
                      setState(() {
                        try {
                          hexDecode(_otherPubkey.text);
                        } catch (e) {
                          _otherPubkey.clear();
                        }
                      });
                    },
                    controller: _otherPubkey,
                    maxLines: 1,
                    maxLength: 130,
                    decoration: const InputDecoration(
                        label: Text('$strRecipient\'s $strPublicKey')),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      if ((Platform.isIOS || Platform.isAndroid)) {
                        Navigator.push(
                                context,
                                MaterialPageRoute<String?>(
                                    builder: (context) => QrScanner()))
                            .then((value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              isValidPublicKey(value)) {
                            setState(() {
                              _otherPubkey.text = value;
                            });
                          }
                        });
                      } else {
                        snackbarAlert(context, message: msgUnsupportPlatform);
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner_outlined)),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _output.text = strEmpty;
                  cipherMsg = {};
                });
              },
              controller: _input,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration: const InputDecoration(label: Text(strPlainText)),
            ),
          ),
          TextButton(
              onPressed: _input.text.isEmpty
                  ? null
                  : () => setState(() {
                        if (_otherPubkey.text.isNotEmpty) {
                          try {
                            hexToPublicKey(_otherPubkey.text);
                          } catch (e) {
                            snackbarAlert(context,
                                message: msgInvalidPubkey,
                                backgroundColor: Colors.red);
                            return;
                          }
                        }
                        authMe(context, canCancel: true, didUnlocked: () async {
                          var _key = await getKey(widget.selectedKey);
                          if (_key != null) {
                            setState(() {
                              cipherMsg = _key.encryptMessage(
                                  _input.text, _otherPubkey.text);
                              _output.text =
                                  cipherMsg[CipheredMessageField.cipher.name];
                            });
                          }
                        });
                      }),
              child: const Text(strEncrypt)),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onTap: () => copyToClipboardWithNotify(
                    context, _output.text, strCipherMsg),
                controller: _output,
                readOnly: true,
                minLines: 1,
                maxLines: 8,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text(_strCipherMsg)),
              )),
        ]),
      ),
    );
  }
}
