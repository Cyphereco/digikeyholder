import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:pointycastle/digests/ripemd160.dart';

import 'dialogs.dart';

class EncryptDecrypt extends StatefulWidget {
  final String selectedKey;
  const EncryptDecrypt({Key? key, required this.selectedKey}) : super(key: key);

  @override
  _EncryptDecryptState createState() => _EncryptDecryptState();
}

class _EncryptDecryptState extends State<EncryptDecrypt> {
  final _input = TextEditingController(text: '');
  final _otherPubkey = TextEditingController(text: '');
  final _output = TextEditingController(text: '');

  static const _strEnc = 'Encrypt';
  static const _strDec = 'Decrypt';
  static const _strPlainText = 'Plain Text Message';
  static const _strCipherMsg = 'Ciphered Message';
  late String _act;

  var cipherMsg = {
    CipheredMessageField.cipher.name: '',
    CipheredMessageField.publickey.name: '',
    CipheredMessageField.secrethash.name: '',
  };

  @override
  void initState() {
    super.initState();
    _act = _strEnc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Message En/Decrypt'),
        actions: _act == _strEnc
            ? (_output.text.isEmpty
                ? null
                : [
                    IconButton(
                        tooltip: 'Copy ciphered message',
                        onPressed: () {
                          copyToClipboardWithNotify(context,
                              jsonEncode(cipherMsg), 'Ciphered message');
                        },
                        icon: const Icon(Icons.copy)),
                    IconButton(
                        tooltip: 'Show QR code',
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => QrDataDialog(
                                    title: 'Ciphered Message',
                                    data: jsonEncode(cipherMsg),
                                  ));
                        },
                        icon: const Icon(Icons.qr_code)),
                  ])
            : [
                IconButton(
                    tooltip: 'Paste input from clipboard',
                    onPressed: () {
                      // TODO: implement read encrypt message QR scanner
                    },
                    icon: const Icon(Icons.paste)),
                IconButton(
                    tooltip: 'Scan QR code',
                    onPressed: () {
                      // TODO: implement read encrypt message QR scanner
                    },
                    icon: const Icon(Icons.qr_code_scanner_outlined)),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: DropdownButton<String>(
                value: _act,
                isExpanded: true,
                onChanged: (act) {
                  setState(() {
                    _act = act!;
                    cipherMsg[CipheredMessageField.cipher.name] = '';
                    cipherMsg[CipheredMessageField.publickey.name] = '';
                    cipherMsg[CipheredMessageField.secrethash.name] = '';
                  });
                },
                items: const [
                  DropdownMenuItem<String>(
                      value: _strEnc, child: Text(_strEnc)),
                  DropdownMenuItem<String>(value: _strDec, child: Text(_strDec))
                ]),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
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
              decoration: InputDecoration(
                  label: Text(
                      '${_act == _strEnc ? 'Recipient' : 'Sender'}\'s Public Key')),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _output.text = '';
                  cipherMsg[CipheredMessageField.cipher.name] = '';
                  cipherMsg[CipheredMessageField.publickey.name] = '';
                  cipherMsg[CipheredMessageField.secrethash.name] = '';
                });
              },
              controller: _input,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration: InputDecoration(
                  label: Text(_act == _strEnc ? _strPlainText : _strCipherMsg)),
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
                                message: 'Invalid public key!',
                                backgroundColor: Colors.red);
                            return;
                          }
                        }
                        authMe(context, canCancel: true, didUnlocked: () async {
                          var _key = await getKey(widget.selectedKey);
                          if (_key != null) {
                            if (_act == _strEnc) {
                              setState(() {
                                _output.text = _key.encryptString(
                                    _input.text, _otherPubkey.text);
                                cipherMsg[CipheredMessageField.cipher.name] =
                                    _output.text;
                                cipherMsg[CipheredMessageField.publickey.name] =
                                    _otherPubkey.text.isEmpty
                                        ? publicKeyAdd(_key.publicKey,
                                                    _key.publicKey)
                                                ?.toCompressedHex() ??
                                            ''
                                        : publicKeyAdd(
                                                    _key.publicKey,
                                                    hexToPublicKey(
                                                        _otherPubkey.text))
                                                ?.toCompressedHex() ??
                                            '';
                                cipherMsg[
                                        CipheredMessageField.secrethash.name] =
                                    hexEncode(RIPEMD160Digest().process(
                                        hexDecode(_otherPubkey.text.isEmpty
                                            ? _key.toString()
                                            : _key.computeShareKey(
                                                hexToPublicKey(
                                                    _otherPubkey.text)))));
                              });
                            } else {
                              try {
                                setState(() {
                                  _output.text = _key.decryptString(
                                      _input.text, _otherPubkey.text);
                                });
                              } catch (e) {
                                _output.text =
                                    'Input [ ${_input.text} ] is not a valid ciphered message or the used key or sender\'s public key is incorrect!';
                              }
                            }
                          }
                        });
                      }),
              child: Text(_act == _strEnc ? _strEnc : _strDec)),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onTap: () => copyToClipboardWithNotify(
                    context, _output.text, txtCipherMsg),
                controller: _output,
                readOnly: true,
                minLines: 1,
                maxLines: 8,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    label:
                        Text(_act == _strEnc ? _strCipherMsg : _strPlainText)),
              )),
        ]),
      ),
    );
  }

  String exportToJson(String cipher, String pubkey, String hash) {
    return jsonEncode(cipherMsg);
  }
}
