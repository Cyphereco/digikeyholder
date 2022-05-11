import 'dart:io';
import 'dart:math';
import 'package:digikeyholder/screens/cipherdecryptor.dart';
import 'package:digikeyholder/screens/sigvalidator.dart';
import 'package:digikeyholder/services/snackbarnotification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'theme/style.dart';
import 'models/constants.dart';
import 'services/storage.dart';
import 'screens/addkey.dart';
import 'screens/authme.dart';
import 'screens/showpubkey.dart';
import 'screens/dialogs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

var logger = Logger();

// TODO: support multi-language
void main() async {
  // Make sure widget initialized before using storage
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // restore user pin
  userPin = await getUserPin() ?? strEmpty;

  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      gestures: const [
        GestureType.onTap,
        GestureType.onPanUpdateDownDirection,
      ],
      child: MaterialApp(
        title: strAppName,
        debugShowCheckedModeBanner: false,
        theme: normal(),
        darkTheme: dark(),
        themeMode: ThemeMode.system,
        home: const MyHomePage(title: strKeyList),
      ),
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
  bool _canDoBioAuth = false;
  bool _useBioAuth = false;
  bool _authenticated = false;
  Map<String, String> _keyMap = {};
  PackageInfo pkgInfo = PackageInfo(
      appName: strAppName,
      packageName: 'com.cyphereco.mykes',
      version: '1.0.10 (11)',
      buildNumber: 's');

  Future<void> updateKeyMap() async {
    _authenticated = true;
    if (Platform.isAndroid || Platform.isIOS) {
      if (pkgInfo.buildNumber == 's') {
        pkgInfo = await PackageInfo.fromPlatform();
      }
    }
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
    if (state == AppLifecycleState.resumed && !_authenticated) {
      // TODO: check login failure and delay auth
      authMe(context,
          didConfirmed: () => updateKeyMap(),
          didUnlocked: () => updateKeyMap(),
          canCancel: false);
    } else if (!authenticating && state == AppLifecycleState.paused) {
      _authenticated = false;
      Navigator.popUntil(context, (route) => route.isFirst);
      setState(() {
        _keyMap = {};
      });
    }
  }

  void updatePreference() async {
    _canDoBioAuth = await canDoBioAuth();
    var _isSwitchOn = await getBioAuthSwitch();
    setState(() {
      _useBioAuth = _isSwitchOn == strSwitchOn ? true : false;
    });

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      await DesktopWindow.setMinWindowSize(const Size(360, 540));
    }
  }

  @override
  void initState() {
    FlutterNativeSplash.remove();

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
              tooltip: strEmptyKeyLis,
              onPressed: () =>
                  authMe(context, didUnlocked: _deleteAllKeys, canCancel: true),
              icon: const Icon(Icons.delete_forever)),
          PopupMenuButton<Options>(
              icon: const Icon(Icons.extension),
              tooltip: strOptions,
              onSelected: (Options action) {
                switch (action) {
                  case Options.about:
                    showDialog<bool>(
                        context: context,
                        builder: (context) => AppInfoDialog(
                              appName: pkgInfo.appName,
                              version: pkgInfo.version,
                              buildNumber: pkgInfo.buildNumber == 's'
                                  ? ''
                                  : '(${pkgInfo.buildNumber})',
                            ));
                    break;
                  case Options.sigValidator:
                    Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const SigValidator(),
                        ));
                    break;
                  case Options.cipherDecryptor:
                    if (_keyMap.isEmpty) {
                      snackbarAlert(context, message: msgCreateAkeyFirst);
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => CipherDecryptor(
                            keyList: _keyMap.keys.toList(),
                          ),
                        ));
                    break;
                  case Options.bioAuthControl:
                    setState(() {
                      _useBioAuth = !_useBioAuth;
                      setBioAuthSwitch(
                          _useBioAuth ? strSwitchOn : strSwitchOff);
                    });
                    break;
                  case Options.changePin:
                    authMe(context, resetPin: true, canCancel: true);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => Options.values
                  .where((e) =>
                      (_canDoBioAuth || e.name != Options.bioAuthControl.name))
                  .map((e) => PopupMenuItem<Options>(
                        child: e.name != Options.bioAuthControl.name
                            ? Text(optionsStrs[e]!)
                            : StatefulBuilder(
                                builder: (BuildContext context,
                                        StateSetter setState) =>
                                    Row(
                                      children: [
                                        Expanded(child: Text(optionsStrs[e]!)),
                                        Switch(
                                          // key: const Key('switchBioAuth'),
                                          value: _useBioAuth,
                                          onChanged: (isOn) {
                                            setState(() {
                                              _useBioAuth = isOn;
                                              setBioAuthSwitch(isOn
                                                  ? strSwitchOn
                                                  : strSwitchOff);
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
                              child: Text(
                                _keyMap.entries.toList()[index].value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ]),
                        )))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.yellow
            : Colors.blueGrey,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (context) => AddKey(
                        keyMap: _keyMap,
                      ) //SignMessage(),
                  )).whenComplete(() => updateKeyMap());
        },
        tooltip: strAddKey,
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _deleteAllKeys() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => DeleteConfirmationDialog(strEmpty));
    if (result ?? false) {
      await clearKeys();
      updateKeyMap();
    }
  }
}
