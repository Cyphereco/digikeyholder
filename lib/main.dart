import 'dart:math';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'model.dart';
import 'processor.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:base_codecs/base_codecs.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'global.dart';

Map<String, String> allKeys = {};

void main() async {
  // Make sure widget initialized before calling securestorage
  WidgetsFlutterBinding.ensureInitialized();

  // Read appKey from the securestorage
  var _appKey = await getAppKey();

  // if appkey entry existed, restore it, otherwise, create a new one
  if (_appKey == null) {
    await setAppKey(DigiKey().toString());
  }

  // === User PIN validation ===
  print('isUserPinSet: ${await isUserPinSet()}');
  // if (!await isUserPinSet()) setUserPin('1234');
  // print('isUserPinMatched(5678): ${await isUserPinMatched('5678')}');
  // print('isUserPinMatched(1234): ${await isUserPinMatched('1234')}');
  // resetUserPin();

  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digikey Holder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // scaffoldBackgroundColor: Colors.yellowAccent,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.blueGrey,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Key List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _useBioAuth = false;

  @override
  void initState() {
    authMe(context);
    loadKeys();
    super.initState();
  }

  void loadKeys() async {
    allKeys.clear();

    var entries = await readAllEntries();
    entries.forEach(
      (key, value) async {
        if (key != strAppKey && key != strUserPin) {
          var _hex = await readEntry(key) ?? '';
          if (_hex.isNotEmpty) {
            setState(() {
              allKeys[key] = DigiKey.restore(_hex).publicKey.toCompressedHex();
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              tooltip: 'Add Key',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (context) => const AddKey() //SignMessage(),
                        )).then((value) {
                  setState(() {
                    loadKeys();
                  });
                }).whenComplete(() {
                  setState(() {});
                });
              },
              icon: const Icon(Icons.add)),
          IconButton(
              tooltip: 'Clear Key List',
              onPressed: () => authMe(context, didUnlocked: _deleteAllKeys),
              icon: const Icon(Icons.delete_forever)),
          PopupMenuButton<Options>(
              icon: const Icon(Icons.extension),
              tooltip: 'Options',
              onSelected: (Options action) {
                switch (action) {
                  case Options.about:
                    // TODO: show app info
                    authMe(context, didUnlocked: () {
                      print('Auth Success');
                    });
                    break;
                  case Options.sigveri:
                    // TODO: add signature validator
                    break;
                  case Options.bioauth:
                    // TODO: enable authentication
                    break;
                  case Options.changepin:
                    // TODO: Handle this case.
                    break;
                }
              },
              itemBuilder: (BuildContext context) => Options.values
                  .map((e) => PopupMenuItem<Options>(
                        child: e.name != 'bioauth'
                            ? Text(optionsText[e.name]!)
                            : StatefulBuilder(
                                builder: (BuildContext context,
                                        StateSetter setState) =>
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(optionsText[e.name]!)),
                                        Switch(
                                          value: _useBioAuth,
                                          onChanged: (isOn) {
                                            setState(() {
                                              _useBioAuth = isOn;
                                            });
                                          },
                                        ),
                                      ],
                                    )),
                        value: e,
                      ))
                  .toList())
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: ListView.builder(
                    itemCount: allKeys.length,
                    itemBuilder: (BuildContext context, int index) => ListTile(
                          onTap: () {
                            // show QR code of public key
                            print(
                                'show QR code of pubkey, and pubkey format options');
                            _showPublicKey(allKeys.entries.toList()[index].key,
                                allKeys.entries.toList()[index].value);
                          },
                          trailing: PopupMenuButton(
                              tooltip: 'Actions',
                              onSelected: (KeyActions op) {
                                _doFunc(op, index);
                              },
                              itemBuilder: (BuildContext context) =>
                                  KeyActions.values
                                      .map((e) => PopupMenuItem<KeyActions>(
                                            value: e,
                                            child: Text(keyActionText[e.name]!),
                                          ))
                                      .toList()),
                          title: Text(allKeys.entries.toList()[index].key),
                          subtitle: Row(children: [
                            Transform.rotate(
                                angle: 0.5 * pi,
                                child: const Icon(
                                  Icons.key,
                                  color: Colors.grey,
                                )),
                            Expanded(
                                child:
                                    Text(allKeys.entries.toList()[index].value))
                          ]),
                        )))
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _deleteAllKeys() async {
    await Future.delayed(Duration(milliseconds: 150));
    final result = await showDialog<bool>(
        context: context, builder: (context) => _DeleteConfirmationDialog(''));
    if (result ?? false) {
      // clearKeys();
      setState(() {
        loadKeys();
      });
    }
  }

  Future<void> _doOptions(Options op) async {
    switch (op) {
      case Options.bioauth:
        break;
      case Options.sigveri:
        break;
      default:
    }
  }

  Future<void> _showPublicKey(String id, String pubkey) async {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => PublicKeyDialog(id, pubkey),
        ));
  }

  Future<void> _doFunc(KeyActions op, int index) async {
    var keySel = allKeys.entries.toList()[index];
    print('$op: ${keySel.key}');

    switch (op) {
      case KeyActions.delete:
        final result = await showDialog<bool>(
            context: context,
            builder: (context) => _DeleteConfirmationDialog(keySel.key));
        if (result ?? false) {
          print('Delete Key [${keySel.key}]');
          // deleteKey(keySel.key);
          setState(() {
            loadKeys();
          });
        }
        break;
      case KeyActions.rename:
        final result = await showDialog<String>(
            context: context, builder: (context) => _ChangeKeyId(keySel.key));
        if ((result ?? keySel.key) != keySel.key) {
          print('Change Key ID from [${keySel.key}] to [$result]');
          // var old = await getKey(keySel.key);
          // deleteKey(keySel.key);
          // saveKey(result!, old.privatekey.toHex());
          setState(() {
            loadKeys();
          });
        }
        break;
      case KeyActions.derive:
        break;
      case KeyActions.sign:
        Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => SignMessage(keySel.key),
            )).then((value) {
          setState(() {
            loadKeys();
          });
        }).whenComplete(() {
          setState(() {});
        });
        break;
      case KeyActions.encdec:
        break;
      default:
    }
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  _DeleteConfirmationDialog(String id)
      : _id = id,
        _message = id.isNotEmpty
            ? 'Are you sure to delete this key? \n'
            : 'Are you sure to delete all keys?';

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

class PublicKeyDialog extends StatefulWidget {
  const PublicKeyDialog(this._id, this._pubkey, {Key? key}) : super(key: key);

  final String _id;
  final String _pubkey;

  @override
  State<PublicKeyDialog> createState() => _PublicKeyDialog();
}

class _PublicKeyDialog extends State<PublicKeyDialog> {
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
                    Clipboard.setData(ClipboardData(text: _pubKey.text));
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Key copied.'),
                      // backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ));
                  },
                )),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ]),
        ));
  }
}

class _ChangeKeyId extends StatelessWidget {
  _ChangeKeyId(String id) : _id = TextEditingController(text: id);

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

Future<void> authMe(BuildContext context, {Function? didUnlocked}) async {
  var _pin = await getUserPin() ?? '';
  final inputController = InputController();

  Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => ScreenLock(
                digits: 6,
                correctString: _pin,
                confirmation: _pin.isEmpty ? true : false,
                inputController: inputController,
                didUnlocked: () {
                  Navigator.pop(context);
                  didUnlocked!();
                },
                didConfirmed: (pin) {
                  // ignore: avoid_print
                  _pin = pin;
                  setUserPin(pin);
                  inputController.unsetConfirmed();
                  inputController.clear();
                  Navigator.pop(context);
                },
                didError: (value) {
                  inputController.unsetConfirmed();
                },
              )));
}

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
