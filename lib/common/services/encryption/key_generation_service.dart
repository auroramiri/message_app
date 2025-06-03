import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:asn1lib/asn1lib.dart' as asn1lib;
import 'dart:developer' as developer;
import 'package:pointycastle/asymmetric/oaep.dart';

class KeyGenerationService {
  final FlutterSecureStorage secureStorage;

  KeyGenerationService({required this.secureStorage});

  // Generate RSA key pair
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGen =
        RSAKeyGenerator()..init(
          ParametersWithRandom(
            RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
            secureRandom,
          ),
        );

    final pair = keyGen.generateKeyPair();
    final privateKey = pair.privateKey;

    // Log the generated key components
    final p = privateKey.p!;
    final q = privateKey.q!;
    final modulus = privateKey.n!;
    developer.log('Generated p: $p');
    developer.log('Generated q: $q');
    developer.log('Generated modulus: $modulus');
    developer.log('Check p * q == modulus: ${p * q == modulus}');

    return pair;
  }

  // Encode private key to PEM format
  String encodePrivateKeyToPEM(RSAPrivateKey privateKey) {
    var modulus = privateKey.n!;
    var privateExponent = privateKey.privateExponent!;
    var p = privateKey.p!;
    var q = privateKey.q!;

    var sequence = asn1lib.ASN1Sequence();
    sequence.add(asn1lib.ASN1Integer(BigInt.zero));
    sequence.add(asn1lib.ASN1Integer(modulus));
    sequence.add(asn1lib.ASN1Integer(privateExponent));
    sequence.add(asn1lib.ASN1Integer(p));
    sequence.add(asn1lib.ASN1Integer(q));

    var dataBase64 = base64.encode(sequence.encodedBytes);

    return '-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----';
  }

  // Encode public key to PEM format
  String encodePublicKeyToPEM(RSAPublicKey publicKey) {
    var modulus = publicKey.modulus!;
    var exponent = publicKey.publicExponent!;

    var sequence = asn1lib.ASN1Sequence();
    sequence.add(asn1lib.ASN1Integer(modulus));
    sequence.add(asn1lib.ASN1Integer(exponent));

    var bitString = asn1lib.ASN1BitString(
      Uint8List.fromList(sequence.encodedBytes),
    );

    var topLevelSeq = asn1lib.ASN1Sequence();
    topLevelSeq.add(bitString);

    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return '-----BEGIN RSA PUBLIC KEY-----\n$dataBase64\n-----END RSA PUBLIC KEY-----';
  }

  // Save private key to secure storage
  Future<void> savePrivateKey(RSAPrivateKey privateKey) async {
    String pemPrivateKey = encodePrivateKeyToPEM(privateKey);
    await secureStorage.write(key: 'private_key', value: pemPrivateKey);
  }

  // Encrypt a message using a public key
  Future<String> encryptMessage(String message, String publicKeyPEM) async {
    try {
      developer.log('Starting encryption process...');

      // Логируем входное сообщение
      developer.log('Original message: $message');

      // Декодируем публичный ключ из PEM формата
      developer.log('Decoding public key from PEM format...');
      final publicKey = decodePublicKeyFromPEM(publicKeyPEM);

      // Инициализируем шифратор
      developer.log('Initializing encryptor...');
      final encryptor = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      // Преобразуем сообщение в байты
      developer.log('Converting message to bytes...');
      final messageBytes = Uint8List.fromList(utf8.encode(message));

      // Шифруем сообщение
      developer.log('Encrypting message...');
      final encrypted = encryptor.process(messageBytes);

      // Кодируем зашифрованное сообщение в Base64
      developer.log('Encoding encrypted message to Base64...');
      final encryptedMessage = base64.encode(encrypted);

      developer.log('Encryption process completed successfully.');
      return encryptedMessage;
    } catch (e) {
      developer.log('Error during encryption: $e', error: e);
      throw Exception('Failed to encrypt message: $e');
    }
  }

  // Decrypt a message using a private key
  Future<String> decryptMessage(String encryptedMessage) async {
    try {
      developer.log('Starting decryption process for message.');

      // Получение приватного ключа из хранилища
      developer.log('Reading private key from secure storage...');
      final privateKeyPEM = await secureStorage.read(key: 'private_key');
      if (privateKeyPEM == null) {
        developer.log('Private key not found in secure storage.');
        throw Exception('Private key not found');
      }

      // Декодирование приватного ключа из PEM формата
      developer.log('Decoding private key from PEM format...');
      final privateKey = decodePrivateKeyFromPEM(privateKeyPEM);

      // Инициализация дешифратора
      developer.log('Initializing decryptor...');
      final decryptor = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      // Декодирование зашифрованного сообщения из Base64
      developer.log('Decoding encrypted message from Base64...');
      final encryptedBytes = base64.decode(encryptedMessage);

      // Процесс дешифрования
      developer.log('Decrypting message...');
      final decrypted = decryptor.process(encryptedBytes);

      // Преобразование дешифрованных байтов в строку
      developer.log('Converting decrypted bytes to string...');
      final decryptedMessage = String.fromCharCodes(decrypted);

      developer.log('Message decrypted successfully.');
      return decryptedMessage;
    } catch (e) {
      developer.log('Error during decryption: $e');
      throw Exception('Failed to decrypt message: $e');
    }
  }

  RSAPrivateKey decodePrivateKeyFromPEM(String pemString) {
    try {
      final pemLines = pemString.split('\n');
      final base64String =
          pemLines
              .where(
                (line) =>
                    !line.startsWith('-----BEGIN RSA PRIVATE KEY-----') &&
                    !line.startsWith('-----END RSA PRIVATE KEY-----'),
              )
              .join();

      final bytes = base64.decode(base64String);
      final asn1Parser = asn1lib.ASN1Parser(bytes);
      final topLevelSeq = asn1Parser.nextObject() as asn1lib.ASN1Sequence;

      // Expecting at least 5 elements: version, modulus, privateExponent, p, q
      if (topLevelSeq.elements.length < 5) {
        throw Exception(
          'Invalid ASN.1 structure for RSA private key: missing components',
        );
      }

      // Extracting data with type checks based on the structure created by encodePrivateKeyToPEM
      final modulus =
          topLevelSeq.elements[1] is asn1lib.ASN1Integer
              ? (topLevelSeq.elements[1] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for modulus');

      final privateExponent =
          topLevelSeq.elements[2]
                  is asn1lib.ASN1Integer // Corrected index from 3 to 2
              ? (topLevelSeq.elements[2] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for privateExponent');

      final p =
          topLevelSeq.elements[3]
                  is asn1lib.ASN1Integer // Corrected index from 4 to 3
              ? (topLevelSeq.elements[3] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for p');

      final q =
          topLevelSeq.elements[4]
                  is asn1lib.ASN1Integer // Corrected index from 5 to 4
              ? (topLevelSeq.elements[4] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for q');

      // Optional: Check version at index 0 if needed, but not required for RSAPrivateKey constructor.
      // final version = topLevelSeq.elements[0] is asn1lib.ASN1Integer ? (topLevelSeq.elements[0] as asn1lib.ASN1Integer).valueAsBigInteger : null;
      // if (version != BigInt.zero && version != BigInt.one) {
      //   developer.log('Warning: RSA private key version is not 0 or 1.');
      // }

      return RSAPrivateKey(modulus, privateExponent, p, q);
    } catch (e) {
      developer.log('Error decoding private key: $e', error: e);
      throw Exception('Failed to decode private key: $e');
    }
  }

  void logPublicKey(String publicKeyPEM) {
    developer.log('Public Key PEM: $publicKeyPEM');
  }

  bool isValidBase64(String base64String) {
    return RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(base64String);
  }

  String extractBase64FromPEM(String pemString) {
    final pemLines = pemString.split('\n');
    return pemLines
        .where(
          (line) =>
              !line.startsWith('-----BEGIN RSA PUBLIC KEY-----') &&
              !line.startsWith('-----END RSA PUBLIC KEY-----'),
        )
        .join();
  }

  // Decode public key from PEM format
  RSAPublicKey decodePublicKeyFromPEM(String pemString) {
    try {
      final base64String = extractBase64FromPEM(pemString);
      logPublicKey(pemString);

      if (!isValidBase64(base64String)) {
        throw Exception('Invalid Base64 string');
      }

      final bytes = base64.decode(base64String);
      final asn1Parser = asn1lib.ASN1Parser(bytes);
      final topLevelSeq = asn1Parser.nextObject() as asn1lib.ASN1Sequence;

      if (topLevelSeq.elements.isEmpty) {
        throw Exception('Invalid ASN.1 structure for RSA public key');
      }

      final bitString = topLevelSeq.elements[0] as asn1lib.ASN1BitString;
      final publicKeyAsn = asn1lib.ASN1Parser(bitString.contentBytes());
      final publicKeySeq = publicKeyAsn.nextObject() as asn1lib.ASN1Sequence;

      if (publicKeySeq.elements.length < 2) {
        throw Exception(
          'Invalid ASN.1 structure for RSA public key components',
        );
      }

      final modulus =
          (publicKeySeq.elements[0] as asn1lib.ASN1Integer).valueAsBigInteger;
      final exponent =
          (publicKeySeq.elements[1] as asn1lib.ASN1Integer).valueAsBigInteger;

      return RSAPublicKey(modulus, exponent);
    } catch (e) {
      developer.log('Error decoding public key: $e', error: e);
      throw Exception('Failed to decode public key: $e');
    }
  }
}
