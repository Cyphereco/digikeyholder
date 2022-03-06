import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:digikeyholder/services/storage.dart';

class AddKey extends StatefulWidget {
  const AddKey({Key? key}) : super(key: key);

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
                  _publicKey.text = DigiKey.restore(_privateKey.text)
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
            controller: _id,
            autofocus: true,
            decoration: const InputDecoration(label: Text('ID (Key Alias)')),
          ),
        ),
        TextButton(onPressed: () => _saveKey(), child: const Text('Save')),
      ]),
    );
  }

  void _saveKey() {
    setState(() {
      var msg = '';
      if (_id.text.isEmpty) {
        msg = 'Key ID cannot be empty!';
      } else if (allKeys.containsKey(_id.text)) {
        msg = 'Key ID duplicated! Please use a different ID.';
      } else if (_privateKey.text.isEmpty) {
        msg = 'Private Key cannot be empty!';
      }

      if (msg.isNotEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          // backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ));
        return;
      }

      writeEntry(_id.text, _privateKey.text);
      Navigator.pop(context);
    });
  }
}
