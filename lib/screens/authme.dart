import 'package:flutter/material.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

Future<void> authMe(BuildContext context,
    {bool? canCancel, Function? didUnlocked}) async {
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
                },
                didError: (value) {
                  inputController.unsetConfirmed();
                },
              )));
}
