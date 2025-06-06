import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:logging/logging.dart';

import 'package:dart_pcsc/dart_pcsc.dart';

import 'com_provider.dart';

class PcscProviderError extends ComProviderError {
  PcscProviderError([String message = ""]) : super(message);
  PcscProviderError.fromException(Exception e) : super(e.toString());

  @override
  String toString() => 'PcscProviderError: $message';
}

enum PcscStatus { notSupported, disabled, enabled }

class PcscProvider extends ComProvider {
  static final _log = Logger('pcsc.provider');

  final context = Context(Scope.user);

  Duration timeout = const Duration(seconds: 10);

  Card? card;
  List<String> readers = [];

  PcscProvider() : super(_log);
  String? _selectedReader;

  static Future<PcscStatus> get nfcStatus async {
    return PcscStatus.enabled;

    // NFCAvailability a = await context.scope;
    // switch (a) {
    //   case NFCAvailability.disabled:
    //     return NfcStatus.disabled;
    //   case NFCAvailability.available:
    //   default:
    //     return NfcStatus.notSupported;
    // }
  }

    /// On iOS, sets NFC reader session alert message.
  Future<void> setIosAlertMessage(String message) async {
    if (Platform.isIOS) {
      _log.warning(message);
    } 
  }

  @override
  Future<void> connect(
      {Duration? timeout,
      String alertMessage = "Hold your card near the reader"}) async {
    // if (isConnected()) {
    //   _log.warning('Card reader is alread connected');
    //   return;
    // }
    try {
      await context.establish();
      this.readers = await context.listReaders();

      if (readers.isEmpty) {
        _log.info('No readers');
        return;
      }

      List<String>? withCard = await context.waitForCard(readers).value;
      _log.info('Card detected: ${withCard.first}');
      this.card = await context.connect(
        withCard.first,
        ShareMode.shared,
        Protocol.any,
      );
    } on Exception catch (e) {
      await this.card?.disconnect(Disposition.resetCard);
      throw PcscProviderError.fromException(e);
    }
  }

  @override
  Future<void> disconnect({String? alertMessage, String? errorMessage}) async {
    if (isConnected()) {
      _log.info("Disconnecting");
      try {
        await this.card?.disconnect(Disposition.resetCard);
      } on Exception catch (e) {
        throw PcscProviderError.fromException(e);
      }
    }
  }

  @override
  bool isConnected() {
    _log.info("isConnected ${context}");
    return context != null;
  }

  @override
  Future<Uint8List> transceive(Uint8List data) async {
    try {
      final response = await card?.transmit(data);
      return response
      !;
    } on Exception catch (e) {
      throw PcscProviderError.fromException(e);
    }
  }
}
