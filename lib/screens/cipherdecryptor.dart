import 'dart:convert';
import 'dart:io';

import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/scanner.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CipherDecryptor extends StatefulWidget {
  const CipherDecryptor({Key? key, required this.keyList}) : super(key: key);
  final List<String> keyList;

  @override
  _CipherDecryptorState createState() => _CipherDecryptorState();
}

class _CipherDecryptorState extends State<CipherDecryptor> {
  final _cipher = TextEditingController(text: '');
  final _pubkey = TextEditingController(text: '');
  final _nonce = TextEditingController(text: '');
  final _secretHash = TextEditingController(text: '');
  final _output = TextEditingController(text: '');
  String _selKey = '';
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
        _cipher.text = json[CipheredMessageField.cipher.name] ?? '';
        _secretHash.text = json[CipheredMessageField.secrethash.name] ?? '';
        _pubkey.text = json[CipheredMessageField.publickey.name] ?? '';
        _nonce.text = json[CipheredMessageField.nonce.name] ?? '';
      });
    } catch (e) {
      snackbarAlert(context, message: 'Invalid content!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Decrypt Cipher'),
        actions: [
          IconButton(
              tooltip: 'Paste content from clipboard',
              onPressed: () async {
                var data = await Clipboard.getData('text/plain') ??
                    const ClipboardData(text: '');

                if (data.text!.isNotEmpty) {
                  _parseImportData(data.text!);
                }
              },
              icon: const Icon(Icons.paste)),
          IconButton(
              tooltip: 'Scan QR code',
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
                  snackbarAlert(context,
                      message: 'Sorry! Only supported on mobile devices.');
                }
              },
              icon: const Icon(Icons.qr_code_scanner_outlined)),
          IconButton(
              tooltip: 'Reset input',
              onPressed: () {
                setState(() {
                  _cipher.text = '';
                  _secretHash.text = '';
                  _pubkey.text = '';
                  _nonce.text = '';
                });
              },
              icon: const Icon(Icons.replay)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.0),
            child: Text(
              'Decrypt Key:',
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
                    'Try All Keys:',
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
              decoration:
                  const InputDecoration(label: Text('Ciphered Message')),
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
              decoration: const InputDecoration(label: Text('Secret Digest')),
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
              decoration: const InputDecoration(label: Text("Public key:")),
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
                        _output.text = '';
                      });
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
                            message: 'Cannot decrypt cipher!',
                            backgroundColor: Colors.red);
                      }
                    },
              child: const Text('Decrypt')),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                controller: _output,
                readOnly: true,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text("Original Message")),
              )),
        ]),
      ),
    );
  }
}
