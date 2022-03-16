import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:digikeyholder/models/constants.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  DeleteConfirmationDialog(String id, {Key? key})
      : _id = id,
        _message =
            id.isNotEmpty ? msgComfirmDeleteOneKey : msgConfirmDeleteAllKeys,
        super(key: key);

  final String _id;
  final String _message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Row(
        children: const [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(
              Icons.warning,
              color: Colors.redAccent,
            ),
          ),
          Expanded(child: Text(strConfirmDelete))
        ],
      ),
      content: Text(_message + _id),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(strDelete)),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(strCancel)),
      ],
    );
  }
}

class ChangeKeyIdDialog extends StatelessWidget {
  ChangeKeyIdDialog(String id, {Key? key})
      : _id = TextEditingController(text: id),
        super(key: key);

  final TextEditingController _id;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Row(
        children: const [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(Icons.edit),
          ),
          Expanded(child: Text(strChangeKeyId))
        ],
      ),
      content: TextField(
        controller: _id,
        autofocus: true,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(_id.text),
            child: const Text(strSave)),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(strCancel)),
      ],
    );
  }
}

class QrDataDialog extends StatelessWidget {
  const QrDataDialog({Key? key, required this.title, required this.data})
      : super(key: key);
  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 20.0,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 20.0,
          ),
          PhysicalModel(
              color: Colors.white,
              elevation: 10.0,
              child: QrImage(
                data: data,
                size: 180,
              )),
          const SizedBox(
            height: 20.0,
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(strOk)),
          const SizedBox(
            height: 20.0,
          ),
        ],
      ),
    );
  }
}

class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: const Text(strAbout),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(strAppName),
          const Text(
            'Version : 1.0.1',
            textAlign: TextAlign.center,
          ),
          const Divider(),
          const Text('by CYPHERECO'),
          const SizedBox(
            height: 5.0,
          ),
          const Text('License: MIT'),
          TextField(
            readOnly: true,
            controller: TextEditingController(
                text: 'github.com/cyphereco/digikeyholder'),
            decoration: const InputDecoration(border: InputBorder.none),
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(strOk)),
      ],
    );
  }
}
