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
}

const pubKeyFormatText = {
  'compressed': 'Compressed',
  'raw': 'Raw',
  'b32comp': 'Base32 Encoded (Compressed)',
  'b32raw': 'Base32 Encoded (Raw)',
};

enum PrivateKeyFormat { raw, wif, b32 }

const privKeyFormatText = {
  'raw': 'Raw',
  'wif': 'Wallet Import Format',
  'b32': 'Base32 Encoded',
};
