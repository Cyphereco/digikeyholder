import 'dart:math';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:elliptic/elliptic.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';

class ShowPublicKey extends StatefulWidget {
  const ShowPublicKey(this._id, this._pubkey, {Key? key}) : super(key: key);

  final String _id;
  final String _pubkey;

  @override
  State<ShowPublicKey> createState() => _ShowPublicKeyState();
}

class _ShowPublicKeyState extends State<ShowPublicKey> {
  PubKeyFormat _format = PubKeyFormat.compressed;
  late TextEditingController _pubKey;
  late final PublicKey _key;

  @override
  void initState() {
    _pubKey = TextEditingController(text: widget._pubkey);
    _key = hexToPublicKey(_pubKey.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Row(
            children: [
              Transform.rotate(
                  angle: 0.5 * pi,
                  child: const Icon(
                    Icons.key,
                    color: Colors.grey,
                  )),
              Expanded(child: Text(widget._id)),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
          child: Column(children: [
            const Text('Key Format:'),
            DropdownButton<PubKeyFormat>(
                value: _format,
                isExpanded: true,
                onChanged: (PubKeyFormat? newValue) {
                  setState(() {
                    _format = newValue!;
                    switch (_format) {
                      case PubKeyFormat.compressed:
                        _pubKey.text = _key.toCompressedHex();
                        break;
                      case PubKeyFormat.raw:
                        _pubKey.text = _key.toHex();
                        break;
                      case PubKeyFormat.b32comp:
                        _pubKey.text =
                            base32RfcEncode(hexDecode(_key.toCompressedHex()));
                        break;
                      case PubKeyFormat.b32raw:
                        _pubKey.text = base32RfcEncode(hexDecode(_key.toHex()));
                        break;
                      default:
                    }
                  });
                },
                items: PubKeyFormat.values
                    .map((e) => DropdownMenuItem<PubKeyFormat>(
                        value: e, child: Text(pubKeyFormatText[e.name]!)))
                    .toList()),
            Container(
              padding: const EdgeInsets.all(15.0),
              width: 180,
              height: 180,
              child: PhysicalModel(
                  color: Colors.white,
                  elevation: 10.0,
                  child: QrImage(
                    data: _pubKey.text,
                    size: 180,
                    backgroundColor: Colors.white,
                  )),
            ),
            Flexible(
                fit: FlexFit.loose,
                child: TextField(
                  minLines: 1,
                  maxLines: 6,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  controller: _pubKey,
                  readOnly: true,
                  onTap: () {
                    copyToClipboardWithNotify(context, _pubKey.text,
                        '${pubKeyFormatText[_format.name]} Publc Key');
                  },
                )),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ]),
        ));
  }
}
