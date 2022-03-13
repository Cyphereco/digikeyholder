import 'dart:io';

import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/screens/scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:digikeyholder/models/constants.dart';

class AddKey extends StatefulWidget {
  const AddKey({required this.keyMap, Key? key}) : super(key: key);
  final Map<String, String> keyMap;

  @override
  State<AddKey> createState() => _AddKeyState();
}

class _AddKeyState extends State<AddKey> {
  final TextEditingController _id = TextEditingController(text: strEmpty);
  final TextEditingController _privateKey =
      TextEditingController(text: strEmpty);
  final TextEditingController _publicKey =
      TextEditingController(text: strEmpty);
  bool _hideSecretKey = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(strAddKey),
        actions: [
          IconButton(
              tooltip: strScanQrCode,
              onPressed: () {
                if ((Platform.isIOS || Platform.isAndroid)) {
                  Navigator.push(
                      context,
                      MaterialPageRoute<String?>(
                          builder: (context) => QrScanner())).then((value) {
                    if (value != null && value.length <= 64) {
                      try {
                        var _priv = hexEncode(hexDecode(value));
                        setState(() {
                          _privateKey.text = _priv;
                          _publicKey.text = DigiKey.restore(_priv)
                              .publicKey
                              .toCompressedHex();
                          return;
                        });
                      } catch (e) {
                        snackbarAlert(context, message: msgNoValidDataFounded);
                      }
                    }
                  });
                } else {
                  snackbarAlert(context, message: msgUnsupportPlatform);
                }
              },
              icon: const Icon(Icons.qr_code_scanner_outlined)),
          IconButton(
              tooltip: strGenerate,
              onPressed: () {
                setState(() {
                  DigiKey k = DigiKey();
                  _id.text = randomID();
                  _privateKey.text = k.toString();
                  _publicKey.text = k.publicKey.toCompressedHex();
                });
              },
              icon: const Icon(Icons.auto_awesome)),
          IconButton(
              tooltip: strClearAll,
              onPressed: () {
                setState(() {
                  _id.text = strEmpty;
                  _privateKey.text = strEmpty;
                  _publicKey.text = strEmpty;
                });
              },
              icon: const Icon(Icons.clear)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
          child: TextField(
            controller: _publicKey,
            minLines: 1,
            maxLines: 10,
            readOnly: true,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text(strPublickeyCompressed)),
          ),
        ),
        Focus(
          onFocusChange: (focus) {
            setState(() {
              _hideSecretKey = focus ? false : true;
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
              ],
              maxLength: 64,
              onChanged: ((value) {
                setState(() {
                  _publicKey.text = value.isEmpty
                      ? value
                      : DigiKey.restore(_privateKey.text)
                          .publicKey
                          .toCompressedHex();
                });
              }),
              controller: _privateKey,
              obscureText: _hideSecretKey,
              decoration: const InputDecoration(label: Text(strPrivateKey)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
          child: TextField(
            onChanged: (value) => setState(() {}),
            controller: _id,
            autofocus: true,
            decoration: const InputDecoration(label: Text(strIdKeyAlias)),
          ),
        ),
        TextButton(
            onPressed: (_publicKey.text.isEmpty || _id.text.isEmpty)
                ? null
                : () => _saveKey(),
            child: const Text(strSave)),
      ]),
    );
  }

  void _saveKey() {
    setState(() {
      var msg = strEmpty;
      if (_id.text.isEmpty) {
        msg = msgKeyIdCantBeEmpty;
      } else if (widget.keyMap.containsKey(_id.text)) {
        msg = msgKeyIdDuplicated;
      } else if (_privateKey.text.isEmpty) {
        msg = msgPrivateKeyCantBeEmpty;
      }

      if (msg.isNotEmpty) {
        snackbarAlert(context, message: msg);
        return;
      }

      writeEntry(_id.text, _privateKey.text);
      Navigator.pop(context);
    });
  }
}
