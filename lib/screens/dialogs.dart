import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  DeleteConfirmationDialog(String id, {Key? key})
      : _id = id,
        _message = id.isNotEmpty
            ? 'Are you sure to delete this key? \n'
            : 'Are you sure to delete all keys?',
        super(key: key);

  final String _id;
  final String _message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(
              Icons.warning,
              color: Colors.redAccent,
            ),
          ),
          Expanded(child: Text('Delete Confirmation'))
        ],
      ),
      content: Text(_message + _id),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
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
      title: Row(
        children: const [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Icon(Icons.edit),
          ),
          Expanded(child: Text('Change Key ID'))
        ],
      ),
      content: TextField(
        controller: _id,
        autofocus: true,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(_id.text),
            child: const Text('Save')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
      ],
    );
  }
}

class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Version :  0.0.1',
            textAlign: TextAlign.center,
          ),
          const Divider(),
          const Text('Source code:'),
          TextField(
            readOnly: true,
            // TODO: replace with real source code link
            controller: TextEditingController(
                text: 'https://github/cyphereco/digikeyholder'),
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK')),
      ],
    );
  }
}
