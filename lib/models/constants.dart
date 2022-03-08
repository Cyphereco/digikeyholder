const txtAppName = 'DigiKey Holder';
const txtSignature = 'Signature';

enum KeyActions {
  sign,
  encdec,
  derive,
  export,
  rename,
  delete,
}

const keyActionText = {
  'sign': 'Sign Message',
  'encdec': 'En/De-cryption',
  'derive': 'Derive Key',
  'export': 'Export',
  'rename': 'Change ID',
  'delete': 'Delete',
};

enum Options {
  sigveri,
  changepin,
  bioauth,
  about,
}

const optionsText = {
  'sigveri': 'Signature Validator',
  'changepin': 'Change PIN',
  'bioauth': 'Biometrics Authentication',
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