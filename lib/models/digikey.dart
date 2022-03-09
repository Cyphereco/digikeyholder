import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:base_codecs/base_codecs.dart';
import 'package:elliptic/ecdh.dart';
import 'package:elliptic/elliptic.dart';
import 'package:ecdsa/ecdsa.dart';
import 'package:encryptor/encryptor.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:pointycastle/digests/sha256.dart';

var s256 = getS256();

class DigiKey {
  late final PrivateKey _k;

  DigiKey() : _k = s256.generatePrivateKey();

  DigiKey.restore(String hex) : _k = PrivateKey.fromHex(s256, hex);

  get publicKey => _k.publicKey;

  get compressedPublic => _k.publicKey.toCompressedHex();

  String computeShareKey(PublicKey p) {
    String? _sk;
    while (_sk == null) {
      try {
        _sk = computeSecretHex(_k, p);
        // print(_s256.isOnCurve(PublicKey.fromHex(_s256, _sk)));
      } catch (e) {
        _sk = null;
      }
    }
    return _sk;
  }

  PrivateKey deriveWithScalar(Uint8List scalar) {
    return PrivateKey.fromHex(
        s256,
        ((BigInt.parse(hexEncode(scalar), radix: 16) * _k.D) % s256.n)
            .toRadixString(16));
  }

  String encryptString(String m, [PublicKey? p]) => Encryptor.encrypt(
      p == null || p == _k.publicKey ? _k.toHex() : computeShareKey(p), m);

  String decryptString(String c, [PublicKey? p]) => Encryptor.decrypt(
      p == null || p == _k.publicKey ? _k.toHex() : computeShareKey(p), c);

  bool verify({required String data, required String sig}) =>
      signatueVerify(publicKey, _toHash(data), sig);

  String sign(String data) => signature(_k, _toHash(data)).toDERHex();

  Uint8List _toHash(String data) {
    bool isHashValue = false;
    if (data.length == 64) {
      try {
        hexEncode(hexDecode(data));
        isHashValue = true;
      } catch (_) {
        // ignore
      }
    }

    return isHashValue ? hexDecode(data) : hexDecode(hashMsgSha256(data));
  }

  @override
  String toString() => _k.toHex();

  @override
  bool operator ==(other) =>
      other is DigiKey &&
      (toString() == other.toString() && publicKey == other.publicKey);

  @override
  int get hashCode => Object.hash(_k, publicKey);
}

PublicKey? publicKeyMul(PublicKey p, List<int> mul) =>
    PublicKey.fromPoint(s256, s256.scalarMul(p, mul));

PublicKey hexToPublicKey(String hex) => PublicKey.fromHex(s256, hex);

String randomID() => _randomValue(3) + '-' + _randomValue(3);

String _randomValue(int length) {
  final rand = Random();
  final codeUnits = List.generate(length, (index) {
    return rand.nextInt(26) + 65;
  });

  return String.fromCharCodes(codeUnits);
}

String hashMsgSha256(String data) =>
    hexEncode(SHA256Digest().process(Uint8List.fromList(utf8.encode(data))));

bool signatueVerify(PublicKey key, Uint8List msgHash, String sig) =>
    verify(key, msgHash, Signature.fromDERHex(sig));

String deriveWif(String priv) => base58CheckEncode(hexDecode('80${priv}01'));

String deriveBtcLegacyAddr(String pubkey) {
  var sha256hash =
      SHA256Digest().process(Uint8List.fromList(hexDecode(pubkey)));
  var ripemd160digest =
      RIPEMD160Digest().process(Uint8List.fromList(sha256hash));
  Uint8List raw = Uint8List(ripemd160digest.length + 1);
  raw.setRange(0, 0, [0]); // add version prefix, 0x00 for mainnet
  raw.setRange(1, raw.length, ripemd160digest);
  return base58CheckEncode(raw);
}
