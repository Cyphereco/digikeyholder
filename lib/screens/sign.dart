import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/services/storage.dart';

// ignore: must_be_immutable
class SignMessage extends StatefulWidget {
  String _sel;
  SignMessage(this._sel, {Key? key}) : super(key: key);

  @override
  _SignMessageState createState() => _SignMessageState();
}

class _SignMessageState extends State<SignMessage> {
  final _message = TextEditingController(text: '');
  final _pubkey = TextEditingController(text: '');
  final _signatureController = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');
  final SizedBox _linePadding = const SizedBox(height: 12);

  @override
  void initState() {
    _pubkey.text = allKeys[widget._sel]!;
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
                  // _msgHash.text = hashMsgSha256(value);
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
                value: widget._sel,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    widget._sel = newValue!;
                    _pubkey.text = allKeys[widget._sel]!;
                  });
                },
                items: allKeys.keys
                    .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList()),
          ),
          _linePadding,
          TextButton(
              onPressed: _msgHash.text.isEmpty
                  ? null
                  : () {
                      setState(() {
                        // _signatureController.text =
                        //     DigiKey.restore(allKeys[widget._sel]!)
                        //         .sign(_message.text);
                      });
                    },
              child: const Text('Sign')),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onTap: (() {
                  if (_signatureController.text.isEmpty) return;
                  Clipboard.setData(
                      ClipboardData(text: _signatureController.text));
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Signature copied.'),
                    // backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ));
                }),
                controller: _signatureController,
                readOnly: true,
                minLines: 1,
                maxLines: 8,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text('Signature')),
              )),
        ]),
      ),
    );
  }
}
