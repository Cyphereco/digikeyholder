import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/constants.dart';
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

  PublicKey get publicKey => _k.publicKey;

  String get compressedPublic => _k.publicKey.toCompressedHex();

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

  String encrypt(String m, [String p = strEmpty]) => Encryptor.encrypt(
      !isValidPublicKey(p) || hexToPublicKey(p) == publicKey
          ? _k.toHex()
          : computeShareKey(hexToPublicKey(p)),
      m);

  Map encryptMessage(String msg, [String otherPubkey = strEmpty]) {
    final encMsg = {};

    final nonce = DigiKey();
    encMsg[CipheredMessageField.nonce.name] = nonce.publicKey.toCompressedHex();
    final _sk = !isValidPublicKey(otherPubkey) ||
            hexToPublicKey(otherPubkey) == publicKey
        ? _k.toHex()
        : computeShareKey(hexToPublicKey(otherPubkey));
    final secretHash = hexEncode(RIPEMD160Digest().process(hexDecode(
        (BigInt.parse(_sk, radix: 16) + nonce.publicKey.X).toRadixString(16))));
    encMsg[CipheredMessageField.secrethash.name] = secretHash;

    final point = s256.add(
        s256.add(publicKey, nonce.publicKey),
        isValidPublicKey(otherPubkey)
            ? hexToPublicKey(otherPubkey)
            : publicKey);
    encMsg[CipheredMessageField.publickey.name] =
        PublicKey.fromPoint(s256, point).toCompressedHex();

    encMsg[CipheredMessageField.cipher.name] =
        Encryptor.encrypt(_sk + nonce.publicKey.toCompressedHex(), msg);
    return encMsg;
  }

  String decrypt(String c, [String p = strEmpty]) {
    var ret = Encryptor.decrypt(
        !isValidPublicKey(p) || hexToPublicKey(p) == publicKey
            ? _k.toHex()
            : computeShareKey(hexToPublicKey(p)),
        c);
    return ret;
  }

  Map? decryptMessage(Map encMsg, [String otherPubkey = strEmpty]) {
    try {
      final nonce =
          PublicKey.fromHex(s256, encMsg[CipheredMessageField.nonce.name]);

      final pubkey =
          PublicKey.fromHex(s256, encMsg[CipheredMessageField.publickey.name]);
      final sumPubkey = publicKeySubstract(pubkey, nonce);
      final otherPubkey = publicKeySubstract(sumPubkey!, publicKey);
      final _sk = otherPubkey != null && otherPubkey == publicKey
          ? _k.toHex()
          : computeShareKey(otherPubkey!);
      final secretHash = hexEncode(RIPEMD160Digest().process(hexDecode(
          (BigInt.parse(_sk, radix: 16) + nonce.X).toRadixString(16))));
      if (encMsg[CipheredMessageField.secrethash.name] != secretHash) {
        return null;
      }

      return {
        strMessage: Encryptor.decrypt(_sk + nonce.toCompressedHex(),
            encMsg[CipheredMessageField.cipher.name]),
        strOtherParty: otherPubkey.toCompressedHex(),
      };
    } catch (e) {
      return null;
    }
  }

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

bool isValidPublicKey(String p) {
  try {
    PublicKey.fromHex(s256, p);
    return true;
  } catch (e) {
    return false;
  }
}

PublicKey? publicKeyMul(PublicKey p, List<int> mul) {
  try {
    return PublicKey.fromPoint(s256, s256.scalarMul(p, mul));
  } catch (e) {
    return null;
  }
}

PublicKey? publicKeyAdd(PublicKey p, PublicKey q) {
  final r = s256.add(p, q);
  return s256.isOnCurve(r) ? PublicKey.fromPoint(s256, r) : null;
}

PublicKey? publicKeySubstract(PublicKey p, PublicKey q) {
  final negQ = AffinePoint.fromXY(q.X, -q.Y);
  final r = s256.add(p, negQ);
  return s256.isOnCurve(r) ? PublicKey.fromPoint(s256, r) : null;
}

PublicKey hexToPublicKey(String hex) {
  return PublicKey.fromHex(s256, hex);
}

String randomID() => _randomValue(3) + '-' + _randomValue(3);

String _randomValue(int length) {
  final rand = Random();
  final codeUnits = List.generate(length, (index) {
    return rand.nextInt(26) + 65;
  });

  return String.fromCharCodes(codeUnits);
}

String hashMsgSha256(String data) {
  try {
    return hexEncode(
            SHA256Digest().process(Uint8List.fromList(utf8.encode(data))))
        .toLowerCase();
  } catch (e) {
    return strEmpty;
  }
}

bool signatueVerify(PublicKey key, Uint8List msgHash, String sig) {
  try {
    return verify(key, msgHash, Signature.fromDERHex(sig));
  } catch (e) {
    return false;
  }
}

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
