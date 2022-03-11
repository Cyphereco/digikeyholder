import 'dart:io';
import 'dart:math';
import 'package:digikeyholder/screens/sigvalidator.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'theme/style.dart';
import 'models/constants.dart';
import 'services/storage.dart';
import 'models/digikey.dart';
import 'screens/addkey.dart';
import 'screens/authme.dart';
import 'screens/showpubkey.dart';
import 'screens/dialogs.dart';

var logger = Logger();

// TODO: support multi-language
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
    var _list = all.entries.toList();
    _list.sort(
      (a, b) => a.key.compareTo(b.key),
    );
    setState(() {
      _keyMap = Map.fromEntries(_list);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && await isUserPinSet()) {
      authMe(context,
          didConfirmed: () => updateKeyMap(),
          didUnlocked: () => updateKeyMap(),
          canCancel: false);
    } else {
      setState(() {
        _keyMap = {};
      });
    }
  }

  void updatePreference() async {
    var _isSwitchOn = await getBioAuthSwitch();
    setState(() {
      _useBioAuth = _isSwitchOn == 'on' ? true : false;
    });
  }

  @override
  void initState() {
    super.initState();
    updatePreference();
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
              tooltip: 'Empty key list',
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
                  case Options.sigValidator:
                    Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const SigValidator(),
                        ));
                    break;
                  case Options.bioAuthControl:
                    setState(() {
                      _useBioAuth = !_useBioAuth;
                      setBioAuthSwitch(_useBioAuth ? 'on' : 'off');
                    });
                    break;
                  case Options.changePin:
                    authMe(context, resetPin: true, canCancel: true);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => Options.values
                  .where((e) => ((Platform.isIOS || Platform.isAndroid) ||
                      e.name != Options.bioAuthControl.name))
                  .map((e) => PopupMenuItem<Options>(
                        child: e.name != Options.bioAuthControl.name
                            ? Text(optionsText[e.name]!)
                            : StatefulBuilder(
                                builder: (BuildContext context,
                                        StateSetter setState) =>
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(optionsText[e.name]!)),
                                        Switch(
                                          key: const Key('switchBioAuth'),
                                          value: _useBioAuth,
                                          onChanged: (isOn) {
                                            setState(() {
                                              _useBioAuth = isOn;
                                              setBioAuthSwitch(
                                                  isOn ? 'on' : 'off');
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
                            Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => ShowPublicKey(
                                      _keyMap.entries.toList()[index].key,
                                      _keyMap.entries.toList()[index].value),
                                )).whenComplete(() => updateKeyMap());
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (context) => AddKey(
                        keyMap: _keyMap,
                      ) //SignMessage(),
                  )).whenComplete(() => updateKeyMap());
        },
        tooltip: 'Add key',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
}
