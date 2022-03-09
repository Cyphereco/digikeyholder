import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';

class SignMessage extends StatefulWidget {
  final String selectedKey;
  final String pubkey;
  const SignMessage({Key? key, required this.selectedKey, required this.pubkey})
      : super(key: key);

  @override
  _SignMessageState createState() => _SignMessageState();
}

class _SignMessageState extends State<SignMessage> {
  final _message = TextEditingController(text: '');
  final _pubkey = TextEditingController(text: '');
  final _signatureController = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');
  late String _selKeyId;

  @override
  void initState() {
    _selKeyId = widget.selectedKey;
    _pubkey.text = widget.pubkey;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _strSignerTitle = 'Signer\'s public key: ($_selKeyId)';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Sign Message'),
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
                  _signatureController.text = '';
                });
              },
              controller: _message,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration:
                  const InputDecoration(label: Text('Message to be signed')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: TextField(
              controller: _msgHash,
              minLines: 1,
              maxLines: 10,
              readOnly: true,
              decoration:
                  const InputDecoration(label: Text('Message Digest (SHA256)')),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              controller: _pubkey,
              readOnly: true,
              minLines: 1,
              maxLines: 10,
              maxLength: 66,
              decoration: InputDecoration(label: Text(_strSignerTitle)),
            ),
          ),
          TextButton(
              onPressed: _msgHash.text.isEmpty
                  ? null
                  : () => setState(() {
                        authMe(context,
                            canCancel: true,
                            didUnlocked: () async => _signatureController.text =
                                (await getKey(widget.selectedKey))!
                                    .sign(_message.text));
                      }),
              child: const Text('Sign')),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onTap: () => copyToClipboardWithNotify(
                    context, _signatureController.text, txtSignature),
                controller: _signatureController,
                readOnly: true,
                minLines: 1,
                maxLines: 8,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text(txtSignature)),
              )),
        ]),
      ),
    );
  }
}
