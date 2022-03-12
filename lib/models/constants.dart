const txtAppName = 'DigiKey Holder';
const txtSignature = 'Signature';
const txtCipherMsg = 'Ciphered message';

enum SingedMessageField { message, publickey, signature }
enum CipheredMessageField { cipher, nonce, publickey, secrethash }

enum KeyActions {
  sign,
  encrypt,
  derive,
  export,
  rename,
  delete,
}

const keyActionText = {
  'sign': 'Sign Message',
  'encrypt': 'Encrypt Message',
  'derive': 'Derive Key',
  'export': 'Export',
  'rename': 'Change ID',
  'delete': 'Delete',
};

enum Options {
  sigValidator,
  cipherDecryptor,
  changePin,
  bioAuthControl,
  about,
}

const optionsText = {
  'sigValidator': 'Signature Validator',
  'cipherDecryptor': 'Cipher Decryptor',
  'changePin': 'Change PIN',
  'bioAuthControl': 'Biometrics Authentication',
  'about': 'About'
};

enum PubKeyFormat {
  compressed,
  raw,
  b32comp,
  b32raw,
  btcp2pkh,
}

const pubKeyFormatText = {
  'compressed': 'Compressed',
  'raw': 'Raw',
  'b32comp': 'Base32 Encoded (Compressed)',
  'b32raw': 'Base32 Encoded (Raw)',
  'btcp2pkh': 'BTC P2PKH Address',
};

enum PrivateKeyFormat {
  raw,
  b32,
  wif,
}

const privKeyFormatText = {
  'raw': 'Raw',
  'b32': 'Base32 Encoded',
  'wif': 'Wallet Import Format',
};
