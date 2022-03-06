import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'theme/style.dart';
import 'models/constants.dart';
import 'services/storage.dart';
import 'models/digikey.dart';
import 'screens/addkey.dart';
import 'screens/authme.dart';
import 'screens/showpubkey.dart';
import 'screens/sign.dart';
import 'screens/dialogs.dart';

var logger = Logger();

void main() async {
  // Make sure widget initialized before using storage
  WidgetsFlutterBinding.ensureInitialized();

  // Read appKey from the securestorage
  var _appKey = await getAppKey();

  // if appkey entry existed, restore it, otherwise, create a new one
  if (_appKey == null) {
    await setAppKey(DigiKey().toString());
  }

  // === User PIN validation ===
  logger.i('isUserPinSet: ${await isUserPinSet()}');
  // if (!await isUserPinSet()) setUserPin('1234');
  // logger.i('isUserPinMatched(5678): ${await isUserPinMatched('5678')}');
  // logger.i('isUserPinMatched(1234): ${await isUserPinMatched('1234')}');
  // resetUserPin();

  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: normal(),
      darkTheme: dark(),
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
                      logger.i('Auth Success');
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
                            logger.i(
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
    await Future.delayed(const Duration(milliseconds: 150));
    final result = await showDialog<bool>(
        context: context, builder: (context) => DeleteConfirmationDialog(''));
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
          builder: (context) => ShowPublicKey(id, pubkey),
        ));
  }

  Future<void> _doFunc(KeyActions op, int index) async {
    var keySel = allKeys.entries.toList()[index];
    logger.i('$op: ${keySel.key}');

    switch (op) {
      case KeyActions.delete:
        final result = await showDialog<bool>(
            context: context,
            builder: (context) => DeleteConfirmationDialog(keySel.key));
        if (result ?? false) {
          logger.i('Delete Key [${keySel.key}]');
          // deleteKey(keySel.key);
          setState(() {
            loadKeys();
          });
        }
        break;
      case KeyActions.rename:
        final result = await showDialog<String>(
            context: context,
            builder: (context) => ChangeKeyIdDialog(keySel.key));
        if ((result ?? keySel.key) != keySel.key) {
          logger.i('Change Key ID from [${keySel.key}] to [$result]');
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
