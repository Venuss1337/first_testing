import 'package:encrypt/encrypt.dart' as encrypt;

/// Service to handle message encryption/decryption
class MessageEncryptionService {
  final encrypt.Key key;
  final encrypt.IV iv;

  /// Create a new encryption service with the given key
  /// [encryptionKey] - A secret key used for AES encryption
  MessageEncryptionService({required String encryptionKey})
      : key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, '0').substring(0, 32)),
        iv = encrypt.IV.fromLength(16);

  /// Decrypt an encrypted message
  /// [encryptedMessage] - Base64 encoded encrypted message
  /// Returns the decrypted message as a string
  String decryptMessage(String encryptedMessage) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypt.Encrypted.fromBase64(encryptedMessage);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Encrypt a plain text message
  /// [message] - Plain text message to encrypt
  /// Returns Base64 encoded encrypted message
  String encryptMessage(String message) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(message, iv: iv).base64;
  }
}