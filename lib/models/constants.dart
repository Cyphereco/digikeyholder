enum AppSettings {
  // ignore: constant_identifier_names
  appKey___,
  // ignore: constant_identifier_names
  bioAuthSwitch___,
  // ignore: constant_identifier_names
  userPin___,
  // ignore: constant_identifier_names
  authFailures___,
}

const strAbout = 'About';
const strActions = 'Actions';
const strAddKey = 'Add key';
const strAppName = 'My Keys';
const strB32Enc = 'Base32 Encode';
const strBioAuthCtrl = 'Biometrics Authentication';
const strBtcAddr = 'BTC P2PKH Address';
const strCancel = 'Cancel';
const strChangeId = 'Change ID';
const strChangeKeyId = 'Change Key ID';
const strChangePin = 'Change PIN';
const strCipherDecryptor = 'Cipher Decryptor';
const strCipherMsg = 'Ciphered Message';
const strClearAll = 'Clear All';
const strClose = 'Close';
const strCompressed = 'Compressed';
const strConfirmDelete = 'Confirm Delete';
const strCopied = 'copied';
const strData = 'Data';
const strDecrypt = 'Decrypt';
const strDecryptCipher = 'Decrypt Cipher';
const strDecryptKey = 'Decrypt Key';
const strDelete = 'Delete';
const strDeriveKey = 'Derive Key';
const strDigest = 'Digest';
const strEmpty = '';
const strEmptyKeyLis = 'Empty key list';
const strEncrypt = 'Encrypt';
const strEncryptMessage = 'Encrypt Message';
const strExport = 'Export';
const strOtherParty = 'Other Party';
const strGenerate = 'Generate';
const strId = 'ID';
const strIdKeyAlias = '$strId ($strKeyAlias)';
const strInvalid = 'Invalid';
const strKeyAlias = 'Key Alias';
const strKeyFormat = 'Key Format';
const strKeyList = 'Key List';
const strMessage = 'Message';
const strMsgDigest = '$strMessage $strDigest';
const strMsgDigestSha256 = '$strMsgDigest ($strSha256)';
const strMsgToSign = 'Message to be signed';
const strOk = 'OK';
const strOptions = 'Options';
const strOrginalMsg = 'Original Message';
const strOversizeData = 'Data size exceeds the QR code limit!';
const strPlainText = 'Plain Text Message';
const strPleaseAuth = 'Please authorize access';
const strPleaseTryLater = 'Please try again in 30 seconds';
const strPrivateKey = 'Private Key';
const strPublicKey = 'Public Key';
const strPublickeyCompressed = '$strPublicKey ($strCompressed)';
const strRaw = 'Raw';
const strRecipient = 'Recipient';
const strResetInput = 'Reset input';
const strSave = 'Save';
const strScanQrCode = 'Scan QR code';
const strSecretDigest = 'Secret Digest';
const strSha256 = 'SHA256';
const strSign = 'Sign';
const strSignedMsg = 'Singed message';
const strSignersPubkey = 'Signer\'s $strPublicKey';
const strSignature = 'Signature';
const strSignMessage = 'Sign Message';
const strSigValidator = 'Signature Validator';
const strSwitchOff = 'off';
const strSwitchOn = 'on';
const strTryAllKeys = 'Try All Keys';
const strValid = 'Valid';
const strValidate = 'Validate';
const strValidateSignature = 'Validate Signature';
const strWIF = 'Wallet Import Format';

const msgCantDecrypt = 'Cannot decrypt cipher!';
const msgConfirmDeleteAllKeys = 'Are you sure to delete all keys?';
const msgComfirmDeleteOneKey = 'Are you sure to delete this key? \n';
const msgInvalidContent = 'Invalid content!';
const msgInvalidPubkey = 'Invalid public key!';
const msgNoValidDataFounded = 'No valid data founded.';
const msgKeyIdCantBeEmpty = 'Key ID cannot be empty!';
const msgKeyIdDuplicated = 'Key ID duplicated! Please use a different ID.';
const msgPrivateKeyCantBeEmpty = 'Private Key cannot be empty!';
const msgUnsupportPlatform = 'Sorry! Only supported on mobile devices.';

const tipCopyCipherMsg = 'Copy ciphered message';
const tipCopySignedMsg = 'Copy signed message';
const tipPasteContent = 'Paste content from clipboard';
const tipShowQrCode = 'Show QR code';

enum SingedMessageField { message, publickey, signature }
enum CipheredMessageField { cipher, nonce, publickey, secrethash }

enum KeyActions {
  sign,
  encrypt,
  // derive,
  export,
  rename,
  delete,
}

const keyActionStrs = {
  KeyActions.sign: strSignMessage,
  KeyActions.encrypt: strEncryptMessage,
  // KeyActions.derive : strDeriveKey,
  KeyActions.export: strExport,
  KeyActions.rename: strChangeId,
  KeyActions.delete: strDelete,
};

enum Options {
  sigValidator,
  cipherDecryptor,
  changePin,
  bioAuthControl,
  about,
}

const optionsStrs = {
  Options.sigValidator: strSigValidator,
  Options.cipherDecryptor: strCipherDecryptor,
  Options.changePin: strChangePin,
  Options.bioAuthControl: strBioAuthCtrl,
  Options.about: strAbout,
};

enum PubKeyFormat {
  compressed,
  raw,
  b32comp,
  b32raw,
  btcp2pkh,
}

const pubKeyFormatStrs = {
  PubKeyFormat.compressed: strCompressed,
  PubKeyFormat.raw: strRaw,
  PubKeyFormat.b32comp: '$strB32Enc ($strCompressed)',
  PubKeyFormat.b32raw: '$strB32Enc ($strRaw)',
  PubKeyFormat.btcp2pkh: strBtcAddr,
};

enum PrivateKeyFormat {
  raw,
  b32,
  wif,
}

const privKeyFormatStrs = {
  PrivateKeyFormat.raw: strRaw,
  PrivateKeyFormat.b32: strB32Enc,
  PrivateKeyFormat.wif: strWIF,
};
