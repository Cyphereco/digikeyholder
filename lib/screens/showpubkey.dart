import 'dart:math';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:flutter/material.dart';
import 'package:digikeyholder/models/constants.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:elliptic/elliptic.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digikeyholder/services/copytoclipboard.dart';
import 'authme.dart';
import 'package:digikeyholder/screens/dialogs.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:digikeyholder/screens/encdec.dart';
import 'package:digikeyholder/screens/sign.dart';
import 'package:digikeyholder/screens/exportprivkey.dart';

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
                    color: Colors.green,
                  )),
              Expanded(child: Text(widget._id)),
            ],
          ),
          actions: [
            PopupMenuButton(
                tooltip: 'Actions',
                onSelected: (KeyActions op) {
                  _doFunc(op);
                },
                itemBuilder: (BuildContext context) => KeyActions.values
                    .map((e) => PopupMenuItem<KeyActions>(
                          value: e,
                          child: Text(keyActionText[e.name]!),
                        ))
                    .toList()),
          ],
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
                      case PubKeyFormat.btcp2pkh:
                        _pubKey.text =
                            deriveBtcLegacyAddr(_key.toCompressedHex());
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
                    backgroundColor: Colors.green,
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

  Future<void> _doFunc(KeyActions op) async {
    switch (op) {
      case KeyActions.delete:
        authMe(context, didUnlocked: () async {
          final result = await showDialog<bool>(
              context: context,
              builder: (context) => DeleteConfirmationDialog(widget._id));
          if (result ?? false) {
            deleteKey(widget._id);
            Navigator.pop(context);
          }
        }, canCancel: true);
        break;
      case KeyActions.rename:
        final result = await showDialog<String>(
            context: context,
            builder: (context) => ChangeKeyIdDialog(widget._id));
        if ((result ?? widget._id) != widget._id) {
          var _k = await getKey(result!);

          if (_k == null) {
            var old = await getKey(widget._id);
            deleteKey(widget._id);
            saveKey(result, old.toString());
          } else {
            snackbarAlert(context,
                message: 'Key ID duplicated!', backgroundColor: Colors.red);
          }
        }
        break;
      case KeyActions.derive:
        // TODO: derive key
        break;
      case KeyActions.sign:
        Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => SignMessage(
                selectedKey: widget._id,
                pubkey: widget._pubkey,
              ),
            ));
        break;
      case KeyActions.encdec:
        Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => EncryptDecrypt(
                selectedKey: widget._id,
              ),
            ));
        break;
      case KeyActions.export:
        authMe(context, canCancel: true, didUnlocked: () async {
          var _key = await getKey(widget._id);
          if (_key == null) return;
          Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    ExportPrivateKey(widget._id, _key.toString()),
              ));
        });
        break;
      default:
    }
  }
}
