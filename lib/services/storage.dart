import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:digikeyholder/models/constants.dart';

const storage = FlutterSecureStorage();

String userPin = strEmpty;

Future<Map<String, String>> getAllKeys() async {
  Map<String, String> _keys = {};
  final _sk = await getAppKey();
  if (_sk == null) return _keys;

  final _appKey = DigiKey.restore(_sk);

  var entries = await readAllEntries();

  for (var key in entries.keys) {
    if (AppSettings.values.where((element) => element.name == key).isEmpty) {
      var val = _appKey.decrypt(entries[key]!);
      if (val.isNotEmpty) {
        _keys[key] = DigiKey.restore(val).compressedPublic;
      }
    }
  }

  return _keys;
}

Future<DigiKey?> getKey(String id) async {
  if (AppSettings.values.where((element) => element.name == id).isEmpty) {
    final _hex = await readEntry(id);
    return _hex == null || _hex.isEmpty ? null : DigiKey.restore(_hex);
  }
  return null;
}

void saveKey(String id, String key) {
  if (AppSettings.values.where((element) => element.name == id).isEmpty) {
    writeEntry(id, key);
  }
}

void deleteKey(String id) {
  if (AppSettings.values.where((element) => element.name == id).isEmpty) {
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
  await storage.write(key: AppSettings.bioAuthSwitch___.name, value: onOff);
}

Future<String> getBioAuthSwitch() async =>
    await storage.read(key: AppSettings.bioAuthSwitch___.name) ?? strSwitchOff;

Future<Map<String, String>> readAllEntries() async => await storage.readAll();

// appKey - used to encrypt user data
Future<String?> getAppKey() async {
  var _key = await storage.read(key: AppSettings.appKey___.name);
  // if appKey does not exist, create one
  if (_key == null) {
    _key = DigiKey().toString();
    await setAppKey(_key);
  }
  return _key;
}

Future<void> setAppKey(String value) async {
  try {
    hexDecode(value);
    await storage.write(key: AppSettings.appKey___.name, value: value);
  } catch (e) {
    return;
  }
}

void resetAppKey() => storage.delete(key: AppSettings.appKey___.name);

Future<bool> isUserPinSet() async =>
    await storage.containsKey(key: AppSettings.userPin___.name);

void setUserPin(String value) {
  writeEntry(AppSettings.userPin___.name, value);
  userPin = value;
}

Future<String?> getUserPin() async =>
    await readEntry(AppSettings.userPin___.name);

Future<void> resetUserPin() async =>
    await deleteEntry(AppSettings.userPin___.name);

Future<bool> isUserPinMatched(String value) async =>
    await readEntry(AppSettings.userPin___.name) == value;

Future<String?> readEntry(String key) async {
  var _sk = await getAppKey();
  if (_sk != null) {
    var value = await storage.read(key: key);
    if (value != null) return DigiKey.restore(_sk).decrypt(value);
  }
  return null;
}

Future<void> writeEntry(String key, String value) async {
  var _sk = await getAppKey();
  if (_sk != null) {
    await storage.write(key: key, value: DigiKey.restore(_sk).encrypt(value));
  }
}

Future<void> deleteEntry(String key) async => await storage.delete(key: key);
