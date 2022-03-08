import 'package:flutter/material.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

bool _authenticating = false;

Future<void> authMe(BuildContext context,
    {bool? canCancel, Function? didUnlocked, Function? didConfirmed}) async {
  if (_authenticating) return;
  _authenticating = true;

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
                canCancel: canCancel ?? false,
                didUnlocked: () {
                  Navigator.pop(context);
                  if (didUnlocked != null) didUnlocked();
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
