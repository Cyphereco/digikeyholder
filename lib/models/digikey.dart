import 'dart:math';
import 'dart:typed_data';
import 'package:base_codecs/base_codecs.dart';
import 'package:elliptic/ecdh.dart';
import 'package:elliptic/elliptic.dart';
import 'package:encryptor/encryptor.dart';

class DigiKey {
  late final PrivateKey _k;

  DigiKey() : _k = getS256().generatePrivateKey();

  DigiKey.restore(String hex) : _k = PrivateKey.fromHex(getS256(), hex);

  get publicKey => _k.publicKey;

  get compressedPublic => _k.publicKey.toCompressedHex();

  String computeShareKey(PublicKey p) {
    String? _sk;
    while (_sk == null) {
      try {
        _sk = computeSecretHex(_k, p);
        // print(getS256().isOnCurve(PublicKey.fromHex(getS256(), _sk)));
      } catch (e) {
        _sk = null;
      }
    }
    return _sk;
  }

  PrivateKey deriveWithScalar(Uint8List scalar) {
    return PrivateKey.fromHex(
        getS256(),
        ((BigInt.parse(hexEncode(scalar), radix: 16) * _k.D) % getS256().n)
            .toRadixString(16));
  }

  String encryptString(String m, [PublicKey? p]) => Encryptor.encrypt(
      p == null || p == _k.publicKey ? _k.toHex() : computeShareKey(p), m);

  String decryptString(String c, [PublicKey? p]) => Encryptor.decrypt(
      p == null || p == _k.publicKey ? _k.toHex() : computeShareKey(p), c);

  @override
  String toString() => _k.toHex();

  @override
  bool operator ==(other) =>
      other is DigiKey &&
      (toString() == other.toString() && publicKey == other.publicKey);

  @override
  int get hashCode => Object.hash(_k, publicKey);
}

class KeyListItem {
  String id = '';
  String pubkey = '';

  @override
  String toString() => {'id': id, 'pub': pubkey}.toString();
}

PublicKey? publicKeyMul(PublicKey p, List<int> mul) =>
    PublicKey.fromPoint(getS256(), getS256().scalarMul(p, mul));

PublicKey hexToPublicKey(String hex) => PublicKey.fromHex(getS256(), hex);

String randomID() => _randomValue(3) + '-' + _randomValue(3);

String _randomValue(int length) {
  final rand = Random();
  final codeUnits = List.generate(length, (index) {
    return rand.nextInt(26) + 65;
  });

  return String.fromCharCodes(codeUnits);
}
