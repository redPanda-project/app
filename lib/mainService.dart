import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:redpanda/redPanda/KademliaId.dart';
import 'package:redpanda/service.dart';

import 'package:pointycastle/pointycastle.dart';

import 'package:cryptography/cryptography.dart';

void main() async {
  Service service = new Service(new KademliaId());
  service.start();

  chacha20_example();

  final ECKeyGenerator generator = KeyGenerator("EC");
  generator.init(
    ParametersWithRandom(
      ECKeyGeneratorParameters(
        ECDomainParameters("secp256r1"),
      ),
      getSecureRandom(),
    ),
  );

  final AsymmetricKeyPair pair = generator.generateKeyPair();

  print(pair);

  final Uint8List message = createUint8ListFromString("TEST");

  final signer = Signer("SHA-256/DET-ECDSA");
  signer.init(
    true,
    PrivateKeyParameter(pair.privateKey),
  );
  final ECSignature sig = signer.generateSignature(message);

  final verifier = Signer("SHA-256/DET-ECDSA");
  verifier.init(false, PublicKeyParameter(pair.publicKey));
  // decrypt
  final isValid = verifier.verifySignature(message, sig);
  print("isValid: $isValid");

  var aesFastEngine = new AESFastEngine();
  var encrypter = CTRStreamCipher(AESFastEngine());
}

SecureRandom getSecureRandom() {
  var secureRandom = FortunaRandom();
  var random = Random.secure();
  List<int> seeds = [];
  for (int i = 0; i < 32; i++) {
    seeds.add(random.nextInt(255));
  }
  secureRandom.seed(new KeyParameter(new Uint8List.fromList(seeds)));
  return secureRandom;
}

Uint8List createUint8ListFromString(String s) {
  var ret = new Uint8List(s.length);
  for (var i = 0; i < s.length; i++) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

void chacha20_example() {
  // Generate a random 256-bit secret key
  final secretKey = chacha20.newSecretKey();

  // Generate a random 96-bit nonce.
  final nonce = chacha20.newNonce();

  // Encrypt
  final result = chacha20.encrypt(
    [1, 2, 3],
    secretKey,
    nonce: nonce,
  );
  print(result);
}
