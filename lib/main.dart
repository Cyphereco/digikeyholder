import 'dart:math';
import 'package:digikeyholder/screens/exportprivkey.dart';
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

  // restore user pin
  userPin = await getUserPin() ?? '';

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
      title: txtAppName,
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _useBioAuth = false;
  Map<String, String> _keyMap = {};

  Future<void> updateKeyMap() async {
    final all = await getAllKeys();
    setState(() {
      _keyMap = all;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && await isUserPinSet()) {
      authMe(context,
          didConfirmed: () => updateKeyMap(),
          didUnlocked: () => updateKeyMap(),
          canCancel: false);
    }
  }

  @override
  void initState() {
    super.initState();
    authMe(context,
        didConfirmed: () => updateKeyMap(),
        didUnlocked: () => updateKeyMap(),
        canCancel: false);
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
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
                        builder: (context) => AddKey(
                              keyMap: _keyMap,
                            ) //SignMessage(),
                        )).whenComplete(() => updateKeyMap());
              },
              icon: const Icon(Icons.add)),
          IconButton(
              tooltip: 'Clear Key List',
              onPressed: () =>
                  authMe(context, didUnlocked: _deleteAllKeys, canCancel: true),
              icon: const Icon(Icons.delete_forever)),
          PopupMenuButton<Options>(
              icon: const Icon(Icons.extension),
              tooltip: 'Options',
              onSelected: (Options action) {
                switch (action) {
                  case Options.about:
                    showDialog<bool>(
                        context: context,
                        builder: (context) => const AppInfoDialog());
                    break;
                  case Options.sigveri:
                    // TODO: add signature validator
                    break;
                  case Options.bioauth:
                    // TODO: enable biometric authentication
                    break;
                  case Options.changepin:
                    authMe(context, didUnlocked: () async {
                      await resetUserPin();
                      authMe(context,
                          didConfirmed: () => updateKeyMap(),
                          didUnlocked: () => updateKeyMap());
                    }, canCancel: true);
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
                    itemCount: _keyMap.length,
                    itemBuilder: (BuildContext context, int index) => ListTile(
                          onTap: () {
                            _showKey(
                                id: _keyMap.entries.toList()[index].key,
                                key: _keyMap.entries.toList()[index].value);
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
                          title: Text(_keyMap.entries.toList()[index].key),
                          subtitle: Row(children: [
                            Transform.rotate(
                                angle: 0.5 * pi,
                                child: const Icon(
                                  Icons.key,
                                  color: Colors.grey,
                                )),
                            Expanded(
                                child:
                                    Text(_keyMap.entries.toList()[index].value))
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
      await clearKeys();
      updateKeyMap();
    }
  }

  Future<void> _showKey(
      {required String id, required String key, bool isPrivate = false}) async {
    if (key.isEmpty && !isPrivate) return;
    Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) =>
              isPrivate ? ExportPrivateKey(id, key) : ShowPublicKey(id, key),
        ));
  }

  Future<void> _doFunc(KeyActions op, int index) async {
    var keySel = _keyMap.entries.toList()[index];
    logger.i('$op: ${keySel.key}');

    switch (op) {
      case KeyActions.delete:
        authMe(context, didUnlocked: () async {
          final result = await showDialog<bool>(
              context: context,
              builder: (context) => DeleteConfirmationDialog(keySel.key));
          if (result ?? false) {
            logger.i('Delete Key [${keySel.key}]');
            deleteKey(keySel.key);
            updateKeyMap();
          }
        }, canCancel: true);
        break;
      case KeyActions.rename:
        final result = await showDialog<String>(
            context: context,
            builder: (context) => ChangeKeyIdDialog(keySel.key));
        if ((result ?? keySel.key) != keySel.key) {
          logger.i('Change Key ID from [${keySel.key}] to [$result]');
          var old = await getKey(keySel.key);
          deleteKey(keySel.key);
          saveKey(result!, old.toString());
          updateKeyMap();
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
                selectedKey: keySel.key,
                keyMap: _keyMap,
              ),
            )).then((value) {
          updateKeyMap();
        });
        break;
      case KeyActions.encdec:
        // TODO: message encrypt/decrypt
        break;
      case KeyActions.export:
        authMe(context, canCancel: true, didUnlocked: () async {
          var _key = await readEntry(_keyMap.entries.toList()[index].key) ?? '';
          if (_key.isEmpty) return;
          _showKey(
              id: _keyMap.entries.toList()[index].key,
              key: _key,
              isPrivate: true);
        });
        break;
      default:
    }
  }
}
