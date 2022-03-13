# digikeyholder
A completely off-line SECP256K1 digital key manager application for Android, iOS, Windows, and MacOS.

What is it for?

What does it do?
- Completely off-line application.
- Random private key generation or import from existing private key.
- Mandatory passcode (PIN) authentication on app open, key deletion, and using private key for signing, encrypting, decrypting, exporting, etc.
- Presenting public key in the following formats: compressed, raw, base32 encode, and Bitcoin P2PKH (legacy) address.
- Presenting private key when exporting in the following formats: raw, base32 encode, wallet import format (WIF).
- Support ECDSA digital signing on message and an ECDSA signature validator.
- Support data (text) encryption/decryption with private key or ECDH shared key.

Some tech insights,


From the creator,
This is my first Flutter app development. If you find any bugs or have any improvement advice, please feel free to open an issue and describe it. You are also welcome to contribute in this software or feel free to fork your branch.
