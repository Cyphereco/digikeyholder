import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:flutter/services.dart';

class SigValidator extends StatefulWidget {
  const SigValidator({Key? key}) : super(key: key);

  @override
  _SigValidatorState createState() => _SigValidatorState();
}

// TODO: add QR code scanner for message and public key input
class _SigValidatorState extends State<SigValidator> {
  final _message = TextEditingController(text: '');
  final _pubkey = TextEditingController(text: '');
  final _signature = TextEditingController(text: '');
  final _msgHash = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    const _strSignerTitle = 'Signer\'s public key:';
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Validate Signature'),
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
                  const InputDecoration(label: Text('Message to be signed')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Text('Digest: ' + _msgHash.text),
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
              maxLength: 66,
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
                        PublicKey.fromHex(s256, _pubkey.text);
                      } catch (e) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Invalid public key!'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ));
                        setState(() {
                          _pubkey.clear();
                        });
                        return;
                      }

                      var isValid = false;
                      try {
                        isValid = signatueVerify(
                            PublicKey.fromHex(s256, _pubkey.text),
                            hexDecode(_msgHash.text),
                            _signature.text);
                      } catch (e) {
                        isValid = false;
                      }

                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            isValid ? 'Valid signature' : 'Invalid signature!'),
                        backgroundColor: isValid ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 4),
                      ));
                    },
              child: const Text('Validate')),
        ]),
      ),
    );
  }
}
