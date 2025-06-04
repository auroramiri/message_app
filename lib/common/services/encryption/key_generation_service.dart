import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:asn1lib/asn1lib.dart' as asn1lib;
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

    return pair;
  }

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

  Future<void> savePrivateKey(RSAPrivateKey privateKey) async {
    String pemPrivateKey = encodePrivateKeyToPEM(privateKey);
    await secureStorage.write(key: 'private_key', value: pemPrivateKey);
  }

  Future<String> encryptMessage(String message, String publicKeyPEM) async {
    try {
      final publicKey = decodePublicKeyFromPEM(publicKeyPEM);

      final encryptor = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      final messageBytes = Uint8List.fromList(utf8.encode(message));

      final encrypted = encryptor.process(messageBytes);

      final encryptedMessage = base64.encode(encrypted);

      return encryptedMessage;
    } catch (e) {
      throw Exception('Failed to encrypt message: $e');
    }
  }

  Future<String> decryptMessage(String encryptedMessage) async {
    try {
      final privateKeyPEM = await secureStorage.read(key: 'private_key');
      if (privateKeyPEM == null) {
        throw Exception('Private key not found');
      }

      final privateKey = decodePrivateKeyFromPEM(privateKeyPEM);

      final decryptor = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      final encryptedBytes = base64.decode(encryptedMessage);

      final decrypted = decryptor.process(encryptedBytes);

      final decryptedMessage = utf8.decode(decrypted);

      return decryptedMessage;
    } catch (e) {
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

      if (topLevelSeq.elements.length < 5) {
        throw Exception(
          'Invalid ASN.1 structure for RSA private key: missing components',
        );
      }

      final modulus =
          topLevelSeq.elements[1] is asn1lib.ASN1Integer
              ? (topLevelSeq.elements[1] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for modulus');

      final privateExponent =
          topLevelSeq.elements[2] is asn1lib.ASN1Integer
              ? (topLevelSeq.elements[2] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for privateExponent');

      final p =
          topLevelSeq.elements[3] is asn1lib.ASN1Integer
              ? (topLevelSeq.elements[3] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for p');

      final q =
          topLevelSeq.elements[4] is asn1lib.ASN1Integer
              ? (topLevelSeq.elements[4] as asn1lib.ASN1Integer)
                  .valueAsBigInteger
              : throw Exception('Invalid type for q');

      return RSAPrivateKey(modulus, privateExponent, p, q);
    } catch (e) {
      throw Exception('Failed to decode private key: $e');
    }
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
      throw Exception('Failed to decode public key: $e');
    }
  }
}
