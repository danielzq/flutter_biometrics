import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'dialog_messages.dart';

enum BiometricType { face, fingerprint, iris }

/// Heavily influenced by [local_auth]
/// 
/// Let's you to create public/private key pair which is stored in native keystore and protected using biometric authentication
/// 
/// You can use generated key pair to create a cryptographic signature
class FlutterBiometrics {
  static const MethodChannel _channel =
      const MethodChannel('flutter_biometrics');

  /// Creates SHA256 RSA key pair for signing using biometrics
  /// 
  /// Will create a new keypair each time method is called
  /// 
  /// Returns Base-64 encoded public key as a [String] if successful
  /// 
  /// [reason] is the message to show when user will be prompted to authenticate using biometrics
  /// 
  /// Provide [dialogMessages] if you want to customize messages for the auth dialog
  Future<String> createKeys({
    @required String reason,
    DialogMessages dialogMessages = const DialogMessages(),
  }) async {
    assert(reason != null);
    final Map<String, Object> args = <String, Object>{
      'reason': reason,
    };
    if (Platform.isAndroid) {
      args.addAll(dialogMessages.messages);
    } else {
      throw PlatformException(
          code: 'OSNotSupported',
          message: 'flutter-biometrics currently supports only Android operating system.',
          details: 'OS you are using is ${Platform.operatingSystem}');
    }
    return await _channel.invokeMethod<String>(
        'createKeys', args);
  }

  /// Signs [payload] using generated private key. [createKeys()] should be called once before using this method.
  /// 
  /// Returns Base-64 encoded signature as a [String] if successful
  /// 
  /// [payload] is Base 64 encoded string you want to sign using SHA256
  /// 
  /// [reason] is the message to show when user will be prompted to authenticate using biometrics
  /// 
  /// Provide [dialogMessages] if you want to customize messages for the auth dialog
  Future<String> sign({
    @required String payload,
    @required String reason,
    DialogMessages dialogMessages = const DialogMessages(),
  }) async {
    assert(payload != null);
    assert(reason != null);
    final Map<String, Object> args = <String, Object>{
      'payload': payload,
      'reason': reason,
    };
    if (Platform.isAndroid) {
      args.addAll(dialogMessages.messages);
    } else {
      throw PlatformException(
          code: 'OSNotSupported',
          message: 'flutter-biometrics currently supports only Android operating system.',
          details: 'OS you are using is ${Platform.operatingSystem}');
    }
    return await _channel.invokeMethod<String>(
        'sign', args);
  }

  /// Returns if device supports any of the available biometric authorisation types
  /// 
  /// Returns a [Future] boolean
  Future<bool> get authAvailable async =>
      (await _channel.invokeListMethod<String>('availableBiometricTypes'))
          .isNotEmpty;

  /// Returns a list of enrolled biometrics
  ///
  /// Returns a [Future] List<BiometricType> with the following possibilities:
  /// - BiometricType.face
  /// - BiometricType.fingerprint
  /// - BiometricType.iris (not yet implemented)
  Future<List<BiometricType>> getAvailableBiometricTypes() async {
    final List<String> result =
    (await _channel.invokeListMethod<String>('availableBiometricTypes'));
    final List<BiometricType> biometrics = <BiometricType>[];
    result.forEach((String value) {
      switch (value) {
        case 'face':
          biometrics.add(BiometricType.face);
          break;
        case 'fingerprint':
          biometrics.add(BiometricType.fingerprint);
          break;
        case 'iris':
          biometrics.add(BiometricType.iris);
          break;
        case 'undefined':
          break;
      }
    });
    return biometrics;
  }
}
