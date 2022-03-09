import 'dart:io';

import 'package:flutter/material.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';

bool _authenticating = false;
final LocalAuthentication auth = LocalAuthentication();

Future<void> authMe(BuildContext context,
    {bool canCancel = false,
    bool resetPin = false,
    Function? didUnlocked,
    Function? didConfirmed}) async {
  if (_authenticating) return;
  _authenticating = true;

  bool _useBioAuth = await getBioAuthSwitch() == 'on' ? true : false;

  bool _canDoBioAuth = (Platform.isIOS || Platform.isAndroid) &&
      (await auth.isDeviceSupported()) &&
      (await auth.canCheckBiometrics);

  if (_canDoBioAuth && _useBioAuth && !resetPin) {
    final didAuthenticate = await auth.authenticate(
      localizedReason: 'Please authorize access',
      biometricOnly: false,
      stickyAuth: true,
    );
    if (didAuthenticate) {
      if (didUnlocked != null) didUnlocked();
    } else {
      if (!canCancel) exit(0);
    }
    _authenticating = false;
  } else {
    var _pin = await getUserPin() ?? '';
    final inputController = InputController();

    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (context) => ScreenLock(
                  digits: 6,
                  maxRetries: _pin.isEmpty ? 0 : 3,
                  retryDelay: const Duration(seconds: 30),
                  delayChild: const Text('Please try again in 30 seconds'),
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
                ))).whenComplete(() {
      _authenticating = false;
    });
  }
}
