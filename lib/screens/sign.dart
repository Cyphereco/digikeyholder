import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';

class SignMessage extends StatefulWidget {
  final String selectedKey;
  const SignMessage({Key? key, required this.selectedKey, required this.keyMap})
      : super(key: key);
  final Map<String, String> keyMap;

  @override
  _SignMessageState createState() => _SignMessageState();
}

class _SignMessageState extends State<SignMessage> {
  final _message = TextEditingController(text: '');
  final _pubkey = TextEditingController(text: '');
  final _signatureController = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');
  final SizedBox _linePadding = const SizedBox(height: 12);
  late String _selKeyId;

  @override
  void initState() {
    _selKeyId = widget.selectedKey;
    _pubkey.text = widget.keyMap[widget.selectedKey]!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
            child: TextField(
              controller: _msgHash,
              minLines: 1,
              maxLines: 10,
              readOnly: true,
              decoration:
                  const InputDecoration(label: Text('Message Hash (SHA256)')),
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
              decoration: const InputDecoration(label: Text('Public Key')),
            ),
          ),
          _linePadding,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: DropdownButton<String>(
                value: _selKeyId,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selKeyId = newValue!;
                    _pubkey.text = widget.keyMap[widget.selectedKey]!;
                  });
                },
                items: widget.keyMap.keys
                    .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList()),
          ),
          _linePadding,
          TextButton(
              onPressed: _msgHash.text.isEmpty
                  ? null
                  : () => setState(() {
                        authMe(context,
                            canCancel: true,
                            didUnlocked: () => _signatureController.text =
                                DigiKey.restore(
                                        widget.keyMap[widget.selectedKey]!)
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
