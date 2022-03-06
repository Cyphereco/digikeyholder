import 'package:flutter/material.dart';
import 'package:digikeyholder/services/storage.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

class EnterPinCode extends StatefulWidget {
  const EnterPinCode({Key? key, this.cbAfterConfirmed}) : super(key: key);

  final Function? cbAfterConfirmed;

  @override
  State<EnterPinCode> createState() => _EnterPinCodeState();
}

class _EnterPinCodeState extends State<EnterPinCode> {
  final inputController = InputController();

  @override
  Widget build(BuildContext context) {
    return ScreenLock(
      digits: 6,
      correctString: userPin,
      confirmation: userPin.isEmpty ? true : false,
      inputController: inputController,
      didUnlocked: () {
        Navigator.pop(context);
        if (widget.cbAfterConfirmed != null) widget.cbAfterConfirmed!();
      },
      didConfirmed: (pin) {
        // ignore: avoid_print
        setUserPin(pin);
        inputController.unsetConfirmed();
        inputController.clear();
        Navigator.pop(context);
      },
      didError: (value) {
        inputController.unsetConfirmed();
      },
    );
  }
}

Future<void> authMe(BuildContext context, {Function? didUnlocked}) async {
  Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => EnterPinCode(
                cbAfterConfirmed: didUnlocked,
              )));
}
