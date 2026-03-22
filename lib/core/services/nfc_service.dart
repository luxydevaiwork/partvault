import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  /// Returns true if NFC is available on this device.
  static Future<bool> isAvailable() async {
    return NfcManager.instance.isAvailable();
  }

  /// Writes [payload] string to an NFC tag.
  /// Calls [onSuccess] on success, [onError] with error message on failure.
  static Future<void> writeTag({
    required String payload,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError('Il tag NFC non supporta NDEF');
              await NfcManager.instance.stopSession();
              return;
            }
            if (!ndef.isWritable) {
              onError('Il tag NFC è in sola lettura');
              await NfcManager.instance.stopSession();
              return;
            }
            final bytes = utf8.encode(payload);
            final record = NdefRecord.createMime('text/plain', bytes);
            final message = NdefMessage([record]);
            await ndef.write(message);
            await NfcManager.instance.stopSession();
            onSuccess();
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            onError(e.toString());
          }
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Reads a string payload from an NFC tag.
  /// Calls [onRead] with the payload string, [onError] on failure.
  static Future<void> readTag({
    required void Function(String payload) onRead,
    required void Function(String error) onError,
  }) async {
    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError('Formato tag non supportato');
              await NfcManager.instance.stopSession();
              return;
            }
            final message = ndef.cachedMessage;
            if (message == null || message.records.isEmpty) {
              onError('Tag NFC vuoto');
              await NfcManager.instance.stopSession();
              return;
            }
            final record = message.records.first;
            final payload = utf8.decode(record.payload);
            await NfcManager.instance.stopSession();
            onRead(payload);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            onError(e.toString());
          }
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  static Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }
}
