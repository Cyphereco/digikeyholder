import 'dart:convert';
import 'dart:io';

import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/scanner.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'authme.dart';

class CipherDecryptor extends StatefulWidget {
  const CipherDecryptor({Key? key, required this.keyList}) : super(key: key);
  final List<String> keyList;

  @override
  _CipherDecryptorState createState() => _CipherDecryptorState();
}

class _CipherDecryptorState extends State<CipherDecryptor> {
  final _cipher = TextEditingController(text: strEmpty);
  final _pubkey = TextEditingController(text: strEmpty);
  final _nonce = TextEditingController(text: strEmpty);
  final _secretHash = TextEditingController(text: strEmpty);
  final _output = TextEditingController(text: strEmpty);
  String _selKey = strEmpty;
  bool _tryAllKeys = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _selKey = widget.keyList[0];
    });
  }

  void _parseImportData(String data) {
    try {
      var json = jsonDecode(data);

      setState(() {
        _cipher.text = json[CipheredMessageField.cipher.name] ?? strEmpty;
        _secretHash.text =
            json[CipheredMessageField.secrethash.name] ?? strEmpty;
        _pubkey.text = json[CipheredMessageField.publickey.name] ?? strEmpty;
        _nonce.text = json[CipheredMessageField.nonce.name] ?? strEmpty;
      });
    } catch (e) {
      snackbarAlert(context, message: msgInvalidContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(strDecryptCipher),
        actions: [
          IconButton(
              tooltip: tipPasteContent,
              onPressed: () async {
                var data = await Clipboard.getData('text/plain') ??
                    const ClipboardData(text: strEmpty);

                if (data.text!.isNotEmpty) {
                  _parseImportData(data.text!);
                }
              },
              icon: const Icon(Icons.paste)),
          IconButton(
              tooltip: strScanQrCode,
              onPressed: () {
                if ((Platform.isIOS || Platform.isAndroid)) {
                  Navigator.push(
                      context,
                      MaterialPageRoute<String?>(
                          builder: (context) => QrScanner())).then((value) {
                    if (value != null && value.isNotEmpty) {
                      _parseImportData(value);
                    }
                  });
                } else {
                  snackbarAlert(context, message: msgUnsupportPlatform);
                }
              },
              icon: const Icon(Icons.qr_code_scanner_outlined)),
          IconButton(
              tooltip: strResetInput,
              onPressed: () {
                setState(() {
                  _cipher.text = strEmpty;
                  _secretHash.text = strEmpty;
                  _pubkey.text = strEmpty;
                  _nonce.text = strEmpty;
                });
              },
              icon: const Icon(Icons.replay)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            height: 10.0,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.0),
            child: Text(
              '$strDecryptKey:',
              textAlign: TextAlign.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: DropdownButton<String>(
                value: _selKey,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _selKey = value!;
                  });
                },
                items: widget.keyList
                    .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    '$strTryAllKeys:',
                    textAlign: TextAlign.end,
                  ),
                ),
                Switch(
                    value: _tryAllKeys,
                    onChanged: (isOn) {
                      setState(
                        () {
                          _tryAllKeys = isOn;
                        },
                      );
                    }),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              controller: _cipher,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration: const InputDecoration(label: Text(strCipherMsg)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
              ],
              controller: _secretHash,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(label: Text(strSecretDigest)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
              ],
              controller: _pubkey,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(label: Text("$strPublicKey:")),
            ),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: TextField(
                onChanged: (value) => setState(() {}),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
                ],
                controller: _nonce,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(label: Text("Nonce")),
              )),
          TextButton(
              onPressed: (_cipher.text.isEmpty ||
                      _pubkey.text.isEmpty ||
                      _nonce.text.isEmpty)
                  ? null
                  : () async {
                      setState(() {
                        _output.text = strEmpty;
                      });

                      authMe(context, canCancel: true, didUnlocked: () async {
                        final encMsg = {};
                        encMsg[CipheredMessageField.cipher.name] = _cipher.text;
                        encMsg[CipheredMessageField.nonce.name] = _nonce.text;
                        encMsg[CipheredMessageField.publickey.name] =
                            _pubkey.text;
                        encMsg[CipheredMessageField.secrethash.name] =
                            _secretHash.text;

                        if (_tryAllKeys) {
                          for (var key in widget.keyList) {
                            setState(() {
                              _selKey = key;
                            });
                            try {
                              final _sk = await getKey(key);
                              if (_sk != null) {
                                var ret = _sk.decryptMessage(encMsg);
                                if (ret != null && ret.isNotEmpty) {
                                  setState(() {
                                    _output.text = ret;
                                  });
                                }
                              }
                              // ignore: empty_catches
                            } catch (e) {}

                            if (_output.text.isNotEmpty) break;
                          }
                        } else {
                          try {
                            final _sk = await getKey(_selKey);
                            if (_sk != null) {
                              var ret = _sk.decryptMessage(encMsg);
                              if (ret != null && ret.isNotEmpty) {
                                setState(() {
                                  _output.text = ret;
                                });
                              }
                            }
                            // ignore: empty_catches
                          } catch (e) {}
                        }

                        if (_output.text.isEmpty) {
                          snackbarAlert(context,
                              message: msgCantDecrypt,
                              backgroundColor: Colors.red);
                        }
                      });
                    },
              child: const Text(strDecrypt)),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                controller: _output,
                readOnly: true,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text(strOrginalMsg)),
              )),
        ]),
      ),
    );
  }
}
