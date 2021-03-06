# digikeyholder
An off-line SECP256K1 digital key manager for Android, iOS, Windows, and macOS written in Dart/Flutter.

What is it for?

Generate/import Elliptic Curve (SECP256K1) keys and save them in local storage with encryption. A user can then uses these keys to sign, encrypt, and decrypt messages, and so on.

What does it do?
- Completely off-line application.
- Generate random private key.
- Import from an existing private key.
- Mandatory passcode/biometric(mobile only) authentication on app open/resume, key deletion, and any actions utilized the private key such as digital signature, encrypt/decrypt, private key export, etc.
- Show public key in the following formats: compressed, raw, base32 encode, and Bitcoin P2PKH (legacy) address.
- Export private key in the following formats: raw, base32 encode, wallet import format (WIF).
- Support ECDSA signing/validating.
- Support (enhanced) ECDH encryption/decryption.

Techincal insights,
- Store private keys with encryption on the device's secure storage: KeyStore (Android) and KeyChain (iOS).
- Private key is only loaded and decrypted at use time. The private key is kept in memory as short as possible at all times.
- Encrypt/decrypt the message using the enhanced ECDH algorithm. For more detail, check https://www.github.com/quarkli/enhancedecdh



From the creator,

This is my first Flutter app development. If you find any bugs or have any improvement advice, please feel free to open an issue and describe it. You are also welcome to contribute to this project or feel free to fork your branch.
