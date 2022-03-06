import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

const strAppKey = 'appKey';
const strUserPin = 'userPin';

Future<Map<String, String>> readAllEntries() async => await storage.readAll();

Future<String?> getAppKey() async => await storage.read(key: strAppKey);

Future<void> setAppKey(String value) async {
  try {
    hexDecode(value);
    await storage.write(key: strAppKey, value: value);
  } catch (e) {
    return;
  }
}

void resetAppKey() => storage.delete(key: strAppKey);

Future<bool> isUserPinSet() async => await readEntry(strUserPin) != null;

void setUserPin(String value) => writeEntry(strUserPin, value);

Future<String?> getUserPin() async => await readEntry(strUserPin);

void resetUserPin() => deleteEntry(strUserPin);

Future<bool> isUserPinMatched(String value) async =>
    await readEntry(strUserPin) == value;

Future<String?> readEntry(String key) async {
  var _sk = await getAppKey();
  if (_sk != null) {
    var value = await storage.read(key: key);
    if (value != null) return DigiKey.restore(_sk).decryptString(value);
  }
  return null;
}

Future<void> writeEntry(String key, String value) async {
  var _sk = await getAppKey();
  if (_sk != null) {
    await storage.write(
        key: key, value: DigiKey.restore(_sk).encryptString(value));
  }
}

Future<void> deleteEntry(String key) async => await storage.delete(key: key);
