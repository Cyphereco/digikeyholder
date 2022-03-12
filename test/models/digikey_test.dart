import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/models/digikey.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SECP256K1 key generation and sign/verify correctness validation', () {
    const privHex =
        '9d7be01e50a2d562301ebb64cfbbde5cb8783a7f6648f48804a0a80e84039298';
    const pubHex =
        '0430e44780ae9c764be784876b7eff68f8b23fc6a519f592fa5c8ce6c87f1a2f72f7d843c1e5f806804a0a79af8d4a9602ae775504fb67878dec6fa17c105beb9d';
    final m = DigiKey.restore(privHex);

    expect(m.toString() == privHex, true);
    expect(m.publicKey.toString() == pubHex, true);

    const otherPubHex =
        '045a1b3aa77891a9d13224e7d728b95772a623d79b615c5703765e1865a2c85bdb03836a40187240ed87c7a9d65a3563ddc217862f86720d15788e9c672aef3f6b';
    const preCalcShareKey =
        '591c93295a82570e9f135e4a564b0c37be0746c840fc8e5739b3dedceaa50b10';
    var sk = m.computeShareKey(hexToPublicKey(otherPubHex));

    expect(sk == preCalcShareKey, true);

    const msg = 'hello';
    const preComputedSig =
        '3045022100b5eae34a3cd7b92f65205b9c3befc50445b3af74958c561653de5399a94c6d1c022056b582a0777b3b7ea23d7a7b5c270dcd9decb266d5ef03e63822d87d3924f305';
    var sig = m.sign(msg);

    expect(m.verify(data: msg, sig: preComputedSig), true);
    expect(m.verify(data: msg, sig: sig), true);
    expect(
        signatueVerify(
            m.publicKey, hexDecode(hashMsgSha256(msg)), preComputedSig),
        true);
  });

  test('SECP256K1 AffinePoint math examples', () {
    final m = DigiKey();
    final n = DigiKey();

    // calc shareKey using ECDH computeSecretHex()
    var sk = m.computeShareKey(n.publicKey);
    var scalarM = BigInt.parse(m.toString(), radix: 16);
    // calc shareKey manually using m.privatekey * n.publickey
    var p = s256.scalarMul(n.publicKey, hexDecode(scalarM.toRadixString(16)));
    expect(sk == p.X.toRadixString(16), true);

    // calc shareKey manually usign m.privatekey * n.privatekey * G
    var scalarN = BigInt.parse(n.toString(), radix: 16);
    var scalarMN = scalarM * scalarN;
    var p1 = s256.scalarBaseMul(hexDecode(scalarMN.toRadixString(16)));
    expect(sk == p1.X.toRadixString(16), true);

    // generate new privatekey from (m.privatekey * n.privatekey) % S256.n
    // and validate publickey.X is the same as shareKey
    var o = PrivateKey.fromHex(s256, (scalarMN % s256.n).toRadixString(16));
    expect(sk == o.publicKey.X.toRadixString(16), true);

    // Add two AffintePoint (m+n)=t, expect (t+(-m))=n and (t+(-n))=m
    final s = s256.add(m.publicKey, n.publicKey);
    final t = PublicKey.fromPoint(
        s256, AffinePoint.fromXY(m.publicKey.X, -(m.publicKey.Y)));
    final u = PublicKey.fromPoint(
        s256, AffinePoint.fromXY(n.publicKey.X, -(n.publicKey.Y)));
    final v = PublicKey.fromPoint(s256, s256.add(s, t));
    final w = PublicKey.fromPoint(s256, s256.add(s, u));
    expect(v == n.publicKey, true);
    expect(w == m.publicKey, true);
  });

  test('DigiKey generate random key validation', () {
    final m = DigiKey();
    final n = DigiKey();

    expect(m != n, true);
    expect(m.toString() != n.toString(), true);
    expect(m.publicKey != n.publicKey, true);
  });

  test('DigiKey restore private key from hex validation', () {
    final m = DigiKey();
    final hex = m.toString();
    final n = DigiKey.restore(hex);

    expect(m == n, true);
  });

  test('SHA256 digest on text validation', () {
    const msg = 'hello';
    const hash =
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

    expect(hashMsgSha256(msg) == hash, true);
  });

  test('DigiKey ECDH computeShareKey validation', () {
    final m = DigiKey();
    final n = DigiKey();

    expect(
        m.computeShareKey(n.publicKey) == n.computeShareKey(m.publicKey), true);
  });

  test('DigiKey eccrypt/decrypt using privateKey', () {
    final m = DigiKey();
    const msg = 'Test Plain Text';
    final cipherM = m.encrypt(msg);
    final decipherM = m.decrypt(cipherM);

    expect(cipherM != msg, true);
    expect(decipherM == msg, true);
  });

  test('DigiKey encrypt/decrypt using shareKey', () {
    final m = DigiKey();
    final n = DigiKey();
    const msg = 'Test Plain Text';

    final cipherM = m.encrypt(msg, n.publicKey.toString());
    expect(cipherM != msg, true);

    final cipherN = n.encrypt(msg, m.publicKey.toString());
    expect(cipherM == cipherN, true);

    final decipherM = n.decrypt(cipherM, m.publicKey.toString());
    expect(decipherM == msg, true);

    final decipherN = m.decrypt(cipherN, n.publicKey.toString());
    expect(decipherM == decipherN, true);
  });

  test('DigiKey deriveWithScalar validation', () {
    final m = DigiKey();
    final n = DigiKey();

    // Calc shareKey of (m, n)
    var sk = m.computeShareKey(n.publicKey);

    // Derive new privateKey (d) from (m) with scalar (sk)
    final d = m.deriveWithScalar(hexDecode(sk));

    // Calc publicKey sk * M
    final p =
        PublicKey.fromPoint(s256, s256.scalarMul(m.publicKey, hexDecode(sk)));

    // match calculated publicKey with derived publicKey
    expect(p == d.publicKey, true);
  });

  test('Derive WIF valition', () {
    const priv =
        '5373bc51f2bb0675d799798213b9afb9361cf8f82e188894bd52591d836ec59b';
    const wif = 'Kz1vwcRLRGj4FL7gBkxPcoTzx7C6pxDFzkqdkyGsqmGS3gx2DgSo';

    expect(deriveWif(priv) == wif, true);
  });

  test('Derive BTC P2PKH address validation', () {
    const pubkey =
        '03fb1531988d0e576db4773e68bbf72b272d8d2bbad02ad84f2ce93ec31a393ad0';
    const addr = '15eCyMKFNJMuzLXmK1QXCpUaSiCCLpwQpM';

    expect(deriveBtcLegacyAddr(pubkey) == addr, true);
  });
}
