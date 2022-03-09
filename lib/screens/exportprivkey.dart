import 'dart:math';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';

class ExportPrivateKey extends StatefulWidget {
  const ExportPrivateKey(this._id, this._privkey, {Key? key}) : super(key: key);

  final String _id;
  final String _privkey;

  @override
  State<ExportPrivateKey> createState() => _ExportPrivateKeyState();
}

class _ExportPrivateKeyState extends State<ExportPrivateKey> {
  PrivateKeyFormat _format = PrivateKeyFormat.raw;
  late TextEditingController _privKey;

  @override
  void initState() {
    _privKey = TextEditingController(text: widget._privkey);
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
            DropdownButton<PrivateKeyFormat>(
                value: _format,
                isExpanded: true,
                onChanged: (PrivateKeyFormat? newValue) {
                  setState(() {
                    _format = newValue!;
                    switch (_format) {
                      case PrivateKeyFormat.raw:
                        _privKey.text = widget._privkey;
                        break;
                      case PrivateKeyFormat.wif:
                        _privKey.text = deriveWif(widget._privkey);
                        break;
                      case PrivateKeyFormat.b32:
                        _privKey.text =
                            base32RfcEncode(hexDecode(widget._privkey));
                        break;
                      default:
                    }
                  });
                },
                items: PrivateKeyFormat.values
                    .map((e) => DropdownMenuItem<PrivateKeyFormat>(
                        value: e, child: Text(privKeyFormatText[e.name]!)))
                    .toList()),
            Container(
              padding: const EdgeInsets.all(15.0),
              width: 180,
              height: 180,
              child: PhysicalModel(
                  color: Colors.white,
                  elevation: 10.0,
                  child: QrImage(
                    data: _privKey.text,
                    size: 180,
                    backgroundColor: Colors.pink,
                  )),
            ),
            Flexible(
                fit: FlexFit.loose,
                child: TextField(
                  minLines: 1,
                  maxLines: 6,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  controller: _privKey,
                  readOnly: true,
                  onTap: () {
                    copyToClipboardWithNotify(context, _privKey.text,
                        '${privKeyFormatText[_format.name]} Publc Key');
                  },
                )),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ]),
        ));
  }
}
