import 'package:base_codecs/base_codecs.dart';
import 'package:digikeyholder/model.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SECP256K1 AffinePoint math examples', () {
    final m = DigiKey();
    final n = DigiKey();

    // calc shareKey using ECDH computeSecretHex()
    var sk = m.computeShareKey(n.publicKey);
    var scalarM = BigInt.parse(m.toString(), radix: 16);
    // calc shareKey manually using m.privatekey * n.publickey
    var p =
        getS256().scalarMul(n.publicKey, hexDecode(scalarM.toRadixString(16)));
    expect(sk == p.X.toRadixString(16), true);

    // calc shareKey manually usign m.privatekey * n.privatekey * G
    var scalarN = BigInt.parse(n.toString(), radix: 16);
    var scalarMN = scalarM * scalarN;
    var p1 = getS256().scalarBaseMul(hexDecode(scalarMN.toRadixString(16)));
    expect(sk == p1.X.toRadixString(16), true);

    // generate new privatekey from (m.privatekey * n.privatekey) % S256.n
    // and validate publickey.X is the same as shareKey
    var o = PrivateKey.fromHex(
        getS256(), (scalarMN % getS256().n).toRadixString(16));
    expect(sk == o.publicKey.X.toRadixString(16), true);
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

  test('DigiKey computeShareKey validation', () {
    final m = DigiKey();
    final n = DigiKey();

    expect(
        m.computeShareKey(n.publicKey) == n.computeShareKey(m.publicKey), true);
  });

  test('DigiKey eccrypt/decrypt using privateKey', () {
    final m = DigiKey();
    const msg = 'Test Plain Text';
    final cipherM = m.encryptString(msg);
    final decipherM = m.decryptString(cipherM);

    expect(cipherM != msg, true);
    expect(decipherM == msg, true);
  });

  test('DigiKey encrypt/decrypt using shareKey', () {
    final m = DigiKey();
    final n = DigiKey();
    const msg = 'Test Plain Text';

    final cipherM = m.encryptString(msg, n.publicKey);
    expect(cipherM != msg, true);

    final cipherN = n.encryptString(msg, m.publicKey);
    expect(cipherM == cipherN, true);

    final decipherM = n.decryptString(cipherM, m.publicKey);
    expect(decipherM == msg, true);

    final decipherN = m.decryptString(cipherN, n.publicKey);
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
    final p = PublicKey.fromPoint(
        getS256(), getS256().scalarMul(m.publicKey, hexDecode(sk)));

    // match calculated publicKey with derived publicKey
    expect(p == d.publicKey, true);
  });
}
