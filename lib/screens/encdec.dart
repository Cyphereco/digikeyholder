import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';

class EncryptDecrypt extends StatefulWidget {
  final String selectedKey;
  const EncryptDecrypt({Key? key, required this.selectedKey}) : super(key: key);

  @override
  _EncryptDecryptState createState() => _EncryptDecryptState();
}

class _EncryptDecryptState extends State<EncryptDecrypt> {
  final _plainText = TextEditingController(text: '');
  final _otherPubkey = TextEditingController(text: '');
  final _cipherText = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');

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
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              controller: _otherPubkey,
              readOnly: true,
              minLines: 1,
              maxLines: 10,
              maxLength: 66,
              decoration:
                  const InputDecoration(label: Text('Recipient\'s Public Key')),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _msgHash.text = value.isEmpty ? value : hashMsgSha256(value);
                  _cipherText.text = '';
                });
              },
              controller: _plainText,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration:
                  const InputDecoration(label: Text('Plain Text Message')),
            ),
          ),
          TextButton(
              onPressed: _msgHash.text.isEmpty
                  ? null
                  : () => setState(() {
                        authMe(context, canCancel: true, didUnlocked: () async {
                          var _key = await getKey(widget.selectedKey);
                          if (_key != null) {
                            _cipherText.text =
                                _key.encryptString(_plainText.text);
                          }
                        });
                      }),
              child: const Text('Encrypt')),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onTap: () => copyToClipboardWithNotify(
                    context, _cipherText.text, txtSignature),
                controller: _cipherText,
                readOnly: true,
                minLines: 1,
                maxLines: 8,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text('Ciphered Message')),
              )),
        ]),
      ),
    );
  }
}
