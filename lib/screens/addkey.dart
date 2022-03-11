import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/screens/scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';

class AddKey extends StatefulWidget {
  const AddKey({required this.keyMap, Key? key}) : super(key: key);
  final Map<String, String> keyMap;

  @override
  State<AddKey> createState() => _AddKeyState();
}

class _AddKeyState extends State<AddKey> {
  final TextEditingController _id = TextEditingController(text: '');
  final TextEditingController _privateKey = TextEditingController(text: '');
  final TextEditingController _publicKey = TextEditingController(text: '');
  bool _hideSecretKey = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Add Key'),
        actions: [
          IconButton(
              tooltip: 'Scan QR code',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute<String?>(
                        builder: (context) => QrScanner())).then((value) {
                  if (value != null && value.length <= 64) {
                    try {
                      var _priv = hexEncode(hexDecode(value));
                      setState(() {
                        _privateKey.text = _priv;
                        _publicKey.text =
                            DigiKey.restore(_priv).publicKey.toCompressedHex();
                        return;
                      });
                    } catch (e) {
                      snackbarAlert(context, message: 'No valid data founded.');
                    }
                  }
                });
              },
              icon: const Icon(Icons.qr_code_scanner_outlined)),
          IconButton(
              tooltip: 'Generate',
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
              tooltip: 'Clear All',
              onPressed: () {
                setState(() {
                  _id.text = '';
                  _privateKey.text = '';
                  _publicKey.text = '';
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
                label: Text('Public Key (Compressed)')),
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
              decoration: const InputDecoration(label: Text('Private Key')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
          child: TextField(
            onChanged: (value) => setState(() {}),
            controller: _id,
            autofocus: true,
            decoration: const InputDecoration(label: Text('ID (Key Alias)')),
          ),
        ),
        TextButton(
            onPressed: (_publicKey.text.isEmpty || _id.text.isEmpty)
                ? null
                : () => _saveKey(),
            child: const Text('Save')),
      ]),
    );
  }

  void _saveKey() {
    setState(() {
      var msg = '';
      if (_id.text.isEmpty) {
        msg = 'Key ID cannot be empty!';
      } else if (widget.keyMap.containsKey(_id.text)) {
        msg = 'Key ID duplicated! Please use a different ID.';
      } else if (_privateKey.text.isEmpty) {
        msg = 'Private Key cannot be empty!';
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
