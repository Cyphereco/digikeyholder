import 'dart:convert';

import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/scanner.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:flutter/services.dart';

class SigValidator extends StatefulWidget {
  const SigValidator({Key? key}) : super(key: key);

  @override
  _SigValidatorState createState() => _SigValidatorState();
}

class _SigValidatorState extends State<SigValidator> {
  final _message = TextEditingController(text: '');
  final _pubkey = TextEditingController(text: '');
  final _signature = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');

  void _parseImportData(String data) {
    try {
      var json = jsonDecode(data);

      setState(() {
        _message.text = json[SingedMessageField.message.name] ?? '';
        _msgHash.text =
            _message.text.isEmpty ? '' : hashMsgSha256(_message.text);
        _pubkey.text = json[SingedMessageField.publickey.name] ?? '';
        _signature.text = json[SingedMessageField.signature.name] ?? '';
      });
    } catch (e) {
      snackbarAlert(context, message: 'Invalid content!');
    }
  }

  @override
  Widget build(BuildContext context) {
    const _strSignerTitle = 'Signer\'s public key:';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Validate Signature'),
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
                Navigator.push(
                    context,
                    MaterialPageRoute<String?>(
                        builder: (context) => QrScanner())).then((value) {
                  if (value != null && value.isNotEmpty) {
                    _parseImportData(value);
                  }
                });
              },
              icon: const Icon(Icons.qr_code_scanner_outlined)),
          IconButton(
              tooltip: 'Reset input',
              onPressed: () {
                setState(() {
                  _message.text = '';
                  _msgHash.text = '';
                  _pubkey.text = '';
                  _signature.text = '';
                });
              },
              icon: const Icon(Icons.replay)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _msgHash.text = value.isEmpty ? value : hashMsgSha256(value);
                });
              },
              controller: _message,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration:
                  const InputDecoration(label: Text('Original Message')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Text('Digest (SHA256): ' + _msgHash.text),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              onChanged: (value) => setState(() {}),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
              ],
              controller: _pubkey,
              maxLines: 1,
              maxLength: 130,
              decoration: const InputDecoration(label: Text(_strSignerTitle)),
            ),
          ),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onChanged: (value) => setState(() {}),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-fA-F0-9]"))
                ],
                controller: _signature,
                minLines: 1,
                maxLines: 4,
                maxLength: 144,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text(txtSignature)),
              )),
          TextButton(
              onPressed: (_message.text.isEmpty ||
                      _pubkey.text.isEmpty ||
                      _signature.text.isEmpty)
                  ? null
                  : () {
                      try {
                        hexToPublicKey(_pubkey.text);
                      } catch (e) {
                        snackbarAlert(context,
                            message: 'Invalid public key!',
                            backgroundColor: Colors.red);
                        setState(() {
                          _pubkey.clear();
                        });
                        return;
                      }

                      var isValid = false;
                      try {
                        isValid = signatueVerify(hexToPublicKey(_pubkey.text),
                            hexDecode(_msgHash.text), _signature.text);
                      } catch (e) {
                        isValid = false;
                      }
                      snackbarAlert(context,
                          message: isValid
                              ? 'Valid signature'
                              : 'Invalid signature!',
                          backgroundColor: isValid ? Colors.green : Colors.red);
                    },
              child: const Text('Validate')),
        ]),
      ),
    );
  }
}
