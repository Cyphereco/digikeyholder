import 'package:flutter/services.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';

class EncryptDecrypt extends StatefulWidget {
  final String selectedKey;
  const EncryptDecrypt({Key? key, required this.selectedKey}) : super(key: key);

  @override
  _EncryptDecryptState createState() => _EncryptDecryptState();
}

// TODO: add QR code generator and scanner for input/output
class _EncryptDecryptState extends State<EncryptDecrypt> {
  final _input = TextEditingController(text: '');
  final _otherPubkey = TextEditingController(text: '');
  final _output = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');

  static const _strEnc = 'Encrypt';
  static const _strDec = 'Decrypt';
  static const _strPlainText = 'Plain Text Message';
  static const _strCipherMsg = 'Ciphered Message';
  late String _act;

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
                    _input.text = '';
                    _output.text = '';
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
                    _showPubkeyError();
                  }
                });
              },
              controller: _otherPubkey,
              maxLines: 1,
              maxLength: 66,
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
                  _msgHash.text = value.isEmpty ? value : hashMsgSha256(value);
                  _output.text = '';
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
              onPressed: _msgHash.text.isEmpty
                  ? null
                  : () => setState(() {
                        if (_otherPubkey.text.isNotEmpty) {
                          try {
                            PublicKey.fromHex(s256, _otherPubkey.text);
                          } catch (e) {
                            _showPubkeyError();
                            return;
                          }
                        }
                        authMe(context, canCancel: true, didUnlocked: () async {
                          var _key = await getKey(widget.selectedKey);
                          if (_key != null) {
                            if (_act == _strEnc) {
                              _output.text = _key.encryptString(
                                  _input.text, _otherPubkey.text);
                            } else {
                              try {
                                _output.text = _key.decryptString(
                                    _input.text, _otherPubkey.text);
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

  _showPubkeyError() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Invalid public key!'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 4),
    ));
  }
}
