import 'dart:io';
import 'package:flutter/material.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:digikeyholder/models/constants.dart';

bool authenticating = false;
final LocalAuthentication auth = LocalAuthentication();

Future<bool> canDoBioAuth() async =>
    (Platform.isIOS || Platform.isAndroid) &&
    (await auth.isDeviceSupported()) &&
    (await auth.canCheckBiometrics);

Future<void> authMe(BuildContext context,
    {bool canCancel = false,
    bool resetPin = false,
    Function? didUnlocked,
    Function? didConfirmed}) async {
  if (authenticating) return;
  authenticating = true;

  bool _useBioAuth = await getBioAuthSwitch() == strSwitchOn ? true : false;

  bool _canDoBioAuth = await canDoBioAuth();

  bool didAuthenticate = false;

  if (_canDoBioAuth && _useBioAuth && !resetPin) {
    didAuthenticate = await auth.authenticate(
      localizedReason: strPleaseAuth,
      biometricOnly: false,
    );

    if (didAuthenticate) {
      if (didUnlocked != null) didUnlocked();
    }
  }

  if (!didAuthenticate) {
    var _pin = await getUserPin() ?? strEmpty;
    final inputController = InputController();

    Navigator.push(
        context,
        MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (context) => ScreenLock(
                  digits: 6,
                  maxRetries: _pin.isEmpty ? 0 : 3,
                  retryDelay: const Duration(seconds: 30),
                  delayChild: Scaffold(
                    // TODO: save login failure times to storage and make a custom delay
                    // TODO: make a count down indicator
                    body: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Expanded(child: SizedBox.expand()),
                          Text(
                            strPleaseTryLater,
                            textAlign: TextAlign.center,
                          ),
                          Expanded(child: SizedBox.expand()),
                        ]),
                  ),
                  correctString: _pin,
                  confirmation: _pin.isEmpty ? true : false,
                  inputController: inputController,
                  canCancel: canCancel,
                  didUnlocked: () async {
                    Navigator.pop(context);
                    if (resetPin) {
                      await resetUserPin();
                      authMe(
                        context,
                        resetPin: true,
                        didConfirmed: didConfirmed,
                      );
                    } else if (didUnlocked != null) {
                      didUnlocked();
                    }
                  },
                  didConfirmed: (pin) {
                    // ignore: avoid_print
                    _pin = pin;
                    setUserPin(pin);
                    inputController.unsetConfirmed();
                    inputController.clear();
                    Navigator.pop(context);
                    if (didConfirmed != null) didConfirmed();
                  },
                  didError: (value) {
                    inputController.unsetConfirmed();
                  },
                ))).whenComplete(() {});
  }
  authenticating = false;
}
