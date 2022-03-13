import 'dart:convert';

import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/screens/authme.dart';
import 'package:digikeyholder/screens/dialogs.dart';
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
  final _message = TextEditingController(text: strEmpty);
  final _pubkey = TextEditingController(text: strEmpty);
  final _signature = TextEditingController(text: strEmpty);
  final _msgHash = TextEditingController(text: strEmpty);
  late String _selKeyId;

  Widget resetInput() => IconButton(
      tooltip: strResetInput,
      onPressed: () {
        setState(() {
          _message.text = strEmpty;
          _msgHash.text = strEmpty;
          _signature.text = strEmpty;
        });
      },
      icon: const Icon(Icons.replay));

  @override
  void initState() {
    _selKeyId = widget.selectedKey;
    _pubkey.text = widget.pubkey;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _strSignerTitle = '$strSignersPubkey: ($_selKeyId)';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(strSignMessage),
        actions: _signature.text.isEmpty
            ? [
                resetInput(),
              ]
            : [
                IconButton(
                    tooltip: tipCopySignedMsg,
                    onPressed: () {
                      copyToClipboardWithNotify(
                          context, exportToJson(), strSignedMsg);
                    },
                    icon: const Icon(Icons.copy_all)),
                IconButton(
                    tooltip: tipShowQrCode,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => QrDataDialog(
                                title: strSignMessage,
                                data: exportToJson(),
                              ));
                    },
                    icon: const Icon(Icons.qr_code)),
                resetInput(),
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
                  _signature.text = strEmpty;
                });
              },
              controller: _message,
              minLines: 1,
              maxLines: 10,
              autofocus: true,
              decoration: const InputDecoration(label: Text(strMsgToSign)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: TextField(
              controller: _msgHash,
              minLines: 1,
              maxLines: 10,
              readOnly: true,
              decoration: const InputDecoration(
                  border: InputBorder.none, label: Text(strMsgDigestSha256)),
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
              decoration: InputDecoration(
                  border: InputBorder.none, label: Text(_strSignerTitle)),
            ),
          ),
          TextButton(
              onPressed: _msgHash.text.isEmpty
                  ? null
                  : () => setState(() {
                        authMe(context, canCancel: true, didUnlocked: () async {
                          var _sig = (await getKey(widget.selectedKey))!
                              .sign(_message.text);
                          setState(() {
                            _signature.text = _sig;
                          });
                        });
                      }),
              child: const Text(strSign)),
          Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              child: TextField(
                onTap: () => copyToClipboardWithNotify(
                    context, _signature.text, strSignature),
                controller: _signature,
                readOnly: true,
                minLines: 1,
                maxLines: 8,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), label: Text(strSignature)),
              )),
        ]),
      ),
    );
  }

  String exportToJson() {
    var signedMsg = {
      SingedMessageField.message.name: _message.text,
      SingedMessageField.publickey.name: _pubkey.text,
      SingedMessageField.signature.name: _signature.text,
    };

    return jsonEncode(signedMsg);
  }
}
