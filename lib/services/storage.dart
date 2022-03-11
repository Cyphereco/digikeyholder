import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

const strAppKey = 'appKey';
const strUserPin = 'userPin';
const strBioAuthSwitch = 'bioAuthSwitch';

String userPin = '';

Future<Map<String, String>> getAllKeys() async {
  Map<String, String> _keys = {};
  final _sk = await getAppKey();
  if (_sk == null) return _keys;

  final _appKey = DigiKey.restore(_sk);

  var entries = await readAllEntries();

  for (var key in entries.keys) {
    if (key != strAppKey && key != strUserPin && key != strBioAuthSwitch) {
      var val = _appKey.decryptString(entries[key]!);
      if (val.isNotEmpty) {
        _keys[key] = DigiKey.restore(val).compressedPublic;
      }
    }
  }

  return _keys;
}

Future<DigiKey?> getKey(String id) async {
  final _hex = await readEntry(id);
  return _hex == null || _hex.isEmpty ? null : DigiKey.restore(_hex);
}

void saveKey(String id, String key) {
  writeEntry(id, key);
}

void deleteKey(String id) {
  if (id != strAppKey && id != strUserPin && id != strBioAuthSwitch) {
    storage.delete(key: id);
  }
}

Future<void> clearKeys() async {
  final _appKey = await getAppKey();
  final _userPin = await getUserPin();
  final _bioAuthSwitch = await getBioAuthSwitch();
  storage.deleteAll();
  if (_appKey != null) setAppKey(_appKey);
  if (_userPin != null) setUserPin(_userPin);
  setBioAuthSwitch(_bioAuthSwitch);
}

void setBioAuthSwitch(String onOff) async {
  await storage.write(key: strBioAuthSwitch, value: onOff);
}

Future<String> getBioAuthSwitch() async =>
    await storage.read(key: strBioAuthSwitch) ?? 'off';

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

Future<bool> isUserPinSet() async => await storage.containsKey(key: strUserPin);

void setUserPin(String value) {
  writeEntry(strUserPin, value);
  userPin = value;
}

Future<String?> getUserPin() async => await readEntry(strUserPin);

Future<void> resetUserPin() async => await deleteEntry(strUserPin);

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
