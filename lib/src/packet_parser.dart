import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'models.dart';
import 'mbus_enums.dart';
import 'mbus_record_decoder.dart';

/// Overridable print function for debugging the M-Bus parser library.
/// Defaults to standard [print].
void Function(String) debugPrint = print;

class _PreprocessResult {
  final Uint8List payload;
  final int payloadOffset;
  final String? errorMsg;

  _PreprocessResult({
    required this.payload,
    required this.payloadOffset,
    this.errorMsg,
  });
}

/// The main parser class containing static methods to unpack and decode M-Bus telegraphs.
class PacketParser {
  /// Decodes the 2-byte manufacturer code into a 3-character ASCII string.
  static void decodeManufacturer(int mCode, List<int> out) {
    out[0] = ((mCode >> 10) & 0x1F) + 64;
    out[1] = ((mCode >> 5) & 0x1F) + 64;
    out[2] = (mCode & 0x1F) + 64;
  }

  static Uint8List _hexToBytes(String hexString) {
    final hex = hexString.replaceAll(' ', '');
    final len = hex.length ~/ 2;
    if (len == 0) return Uint8List(0);
    final buffer = Uint8List(len);
    for (int i = 0; i < len; i++) {
      buffer[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return buffer;
  }

  /// Parses a raw M-Bus hexadecimal string into a [ParsedResult].
  ///
  /// Automatically handles stripping packet boundaries, decryption, and decoding.
  /// If the payload is encrypted (Mode 5), you must supply a 16-byte [keyHex].
  static ParsedResult parseHex(
    String hexString, {
    String? keyHex,
    String? ivHex,
    MBusDriver? driver,
    bool isPayloadOnly = false,
  }) {
    debugPrint("Hex Input: $hexString");
    final rawBuffer = _hexToBytes(hexString);
    if (rawBuffer.isEmpty) {
      debugPrint("Error: Empty or Invalid Hex String");
      return const ParsedResult(error: 'Empty or Invalid Hex String');
    }

    Uint8List? keyBytes;
    if (keyHex != null && keyHex.isNotEmpty) {
      keyBytes = _hexToBytes(keyHex);
      if (keyBytes.length != 16) {
        debugPrint(
          "Error: AES Key must be 16 bytes (32 hex chars). Provided len: ${keyBytes.length}",
        );
        return const ParsedResult(error: 'Invalid Key Length');
      }
    }

    Uint8List? ivBytes;
    if (ivHex != null && ivHex.isNotEmpty) {
      ivBytes = _hexToBytes(ivHex);
      if (ivBytes.length != 16) {
        debugPrint(
          "Error: IV must be 16 bytes (32 hex chars). Provided len: ${ivBytes.length}",
        );
        return const ParsedResult(error: 'Invalid IV Length');
      }
    }

    return parsePacket(
      rawBuffer,
      key: keyBytes,
      iv: ivBytes,
      driver: driver,
      isPayloadOnly: isPayloadOnly,
    );
  }

  /// Parses a raw [Uint8List] buffer representing an M-Bus packet.
  static ParsedResult parsePacket(
    Uint8List rawBuffer, {
    Uint8List? key,
    Uint8List? iv,
    MBusDriver? driver,
    bool isPayloadOnly = false,
  }) {
    final headerInfo = HeaderInfo();
    List<int> payload;
    int payloadOffset = 0;

    if (isPayloadOnly) {
      if (key != null) {
        // Direct AES decryption on the payload without headers.
        // Uses provided IV or an empty IV if the full header was stripped.
        Uint8List ivBytes = iv ?? Uint8List(16);

        int decryptableLen = (rawBuffer.length ~/ 16) * 16;
        Uint8List decrypted = Uint8List(decryptableLen);

        final cipher = CBCBlockCipher(AESEngine());
        final params = ParametersWithIV(KeyParameter(key), ivBytes);
        cipher.init(false, params);

        for (int offset = 0; offset < decryptableLen; offset += 16) {
          cipher.processBlock(rawBuffer, offset, decrypted, offset);
        }

        // The remaining bytes (if any) are appended undecrypted
        payload = List<int>.from(decrypted);
        if (rawBuffer.length > decryptableLen) {
          payload.addAll(rawBuffer.sublist(decryptableLen));
        }

        // Clean trailing padding bytes usually added for AES
        if (payload.isNotEmpty && payload.last == 0x2F) {
          while (payload.isNotEmpty && payload.last == 0x2F) {
            payload.removeLast();
          }
        }
      } else {
        payload = List<int>.from(rawBuffer);
      }
    } else {
      final result = _preprocessFrame(rawBuffer, key, headerInfo);

      if (result.errorMsg != null) {
        return ParsedResult(
          header: headerInfo.isValid ? headerInfo : null,
          error: result.errorMsg,
        );
      }

      if (result.payload.isEmpty) {
        debugPrint("Error: Preprocessing failed (Frame ignored or invalid).");
        return ParsedResult(
          header: headerInfo.isValid ? headerInfo : null,
          error: "Preprocessing failed (Frame ignored or invalid).",
        );
      }

      payload = List<int>.from(result.payload);
      payloadOffset = result.payloadOffset;
    }

    debugPrint("Normalized Payload Size: ${payload.length}");

    // Cleanup: Strip trailing 0x2F (Idle Fill Bytes)
    while (payload.isNotEmpty && payload.last == 0x2F) {
      payload.removeLast();
    }

    final mbus = MBusRecordDecoder();
    final records = <MBusRecord>[];
    int count = mbus.decode(
      Uint8List.fromList(payload),
      records,
      offset: payloadOffset,
      driver: driver,
    );
    MBusError err = mbus.getError();

    final originalRecords = List<MBusRecord>.from(records);
    MBusError originalErr = err;

    // Retry Logic for BUFFER_OVERFLOW (Strip footer strategy)
    if (err == MBusError.bufferOverflow && payload.length > 2) {
      debugPrint(
        "Warning: BUFFER_OVERFLOW. Retrying with last 2 bytes stripped...",
      );
      records.clear();
      final retryPayload = List<int>.from(payload);
      retryPayload.removeLast();
      retryPayload.removeLast();
      int retryCount = mbus.decode(
        Uint8List.fromList(retryPayload),
        records,
        offset: payloadOffset,
        driver: driver,
      );
      err = mbus.getError();
      if (err == MBusError.noError) {
        debugPrint("Recovery: Success.");
        count = retryCount;
      } else {
        debugPrint("Recovery: Failed. Reverting to original records.");
        records.clear();
        records.addAll(originalRecords);
        err = originalErr;
        count = records.length;
      }
    }

    if (err == MBusError.bufferOverflow && records.isNotEmpty) {
      debugPrint(
        "Warning: Frame truncated. Extracted $count valid records before overflow.",
      );
      err = MBusError.noError;
    }

    if (err != MBusError.noError && err != MBusError.unsupportedVif) {
      debugPrint("Decode failed. Error Code: $err");
      return ParsedResult(
        header: headerInfo.isValid ? headerInfo : null,
        records: records,
        error: "Decode Failed: $err",
      );
    }

    debugPrint("Success! Records found: $count");
    return ParsedResult(
      header: headerInfo.isValid ? headerInfo : null,
      records: records,
    );
  }

  static bool parseHeader(Uint8List buff, HeaderInfo info) {
    _preprocessFrame(buff, null, info);
    return info.isValid;
  }

  static _PreprocessResult _preprocessFrame(
    Uint8List rawBuffer,
    Uint8List? key,
    HeaderInfo info,
  ) {
    if (rawBuffer.isEmpty) {
      return _PreprocessResult(
        payload: Uint8List(0),
        payloadOffset: 0,
        errorMsg: "Empty Buffer",
      );
    }

    int byte0 = rawBuffer[0];

    // Wired M-Bus
    if (byte0 == 0x10) {
      if (rawBuffer.length == 5 && rawBuffer[4] == 0x16) {
        debugPrint(
          "Frame Type: Wired M-Bus (Short Frame)\nAction: Ignoring (Command/No Data)",
        );
        return _PreprocessResult(
          payload: Uint8List(0),
          payloadOffset: 0,
          errorMsg: "Ignored: Wired Short Frame (No Data)",
        );
      }
    }

    if (byte0 == 0x68) {
      if (rawBuffer.length > 3 &&
          rawBuffer[3] == 0x68 &&
          rawBuffer.last == 0x16) {
        debugPrint("Frame Type: Wired M-Bus (Long Frame)");
        return _processWired(rawBuffer, info);
      }
    }

    // Wireless M-Bus
    debugPrint("Frame Type: Wireless M-Bus");
    return _processWireless(rawBuffer, key, info);
  }

  static _PreprocessResult _processWired(Uint8List buffer, HeaderInfo info) {
    final len = buffer.length;
    if (len < 9) {
      return _PreprocessResult(
        payload: Uint8List(0),
        payloadOffset: 0,
        errorMsg: "Wired Frame Too Short",
      );
    }

    int cs = 0;
    for (int i = 4; i < len - 2; i++) {
      cs += buffer[i];
    }

    if ((cs & 0xFF) != buffer[len - 2]) {
      debugPrint(
        "Error: Wired Checksum Failed. Calc: 0x${(cs & 0xFF).toRadixString(16)} Exp: 0x${buffer[len - 2].toRadixString(16)}",
      );
      return _PreprocessResult(
        payload: Uint8List(0),
        payloadOffset: 0,
        errorMsg: "Wired Checksum Failed",
      );
    }

    int ci = 0;
    if (len > 6) {
      ci = buffer[6];
      info.cField = buffer[4];
      info.ciField = ci;
      debugPrint("CI Field: 0x${ci.toRadixString(16)}");
    }

    int fixedHeaderLen = 0;
    if (ci == 0x72 || ci == 0x7E || ci == 0x8D) {
      fixedHeaderLen = 12;
      debugPrint("Header: Long (12 bytes fixed)");

      if (len >= 19) {
        info.deviceId =
            (buffer[10] << 24) |
            (buffer[9] << 16) |
            (buffer[8] << 8) |
            buffer[7];
        int mCode = (buffer[12] << 8) | buffer[11];
        List<int> mChars = [0, 0, 0];
        decodeManufacturer(mCode, mChars);
        info.manufacturer = String.fromCharCodes(mChars);
        info.version = buffer[13];
        info.deviceType = buffer[14];
        info.isValid = true;
      }
    } else if (ci == 0x7A) {
      fixedHeaderLen = 4;
      debugPrint("Header: Short (4 bytes fixed)");
    }

    int startIdx = 7 + fixedHeaderLen;
    int endIdx = len - 2;

    if (startIdx >= endIdx) {
      return _PreprocessResult(
        payload: Uint8List(0),
        payloadOffset: 0,
        errorMsg: "No payload",
      );
    }

    return _PreprocessResult(
      payload: buffer.sublist(startIdx, endIdx),
      payloadOffset: startIdx,
    );
  }

  static _PreprocessResult _processWireless(
    Uint8List buffer,
    Uint8List? key,
    HeaderInfo info,
  ) {
    final len = buffer.length;
    int byte0 = buffer[0];
    List<int> cleanBuffer = [];
    bool isFrameA = false;

    info.cField = buffer[0];
    if (len > 10) {
      info.cField = buffer[1];
      int mCode = (buffer[3] << 8) | buffer[2];
      List<int> mChars = [0, 0, 0];
      decodeManufacturer(mCode, mChars);
      info.manufacturer = String.fromCharCodes(mChars);

      info.deviceId =
          (buffer[7] << 24) | (buffer[6] << 16) | (buffer[5] << 8) | buffer[4];
      info.version = buffer[8];
      info.deviceType = buffer[9];
      info.isValid = true;
    }

    if (len > byte0 + 1) {
      debugPrint("Format: Frame A ON-WIRE (Has CRCs)");
      isFrameA = true;

      for (int i = 1; i <= 9; i++) {
        cleanBuffer.add(buffer[i]);
      }

      int cursor = 12;
      int remainingBytesToRead = byte0 - 9;
      while (cursor < len && remainingBytesToRead > 0) {
        int r = len - cursor;
        int chunkTotal = remainingBytesToRead > 16
            ? 18
            : remainingBytesToRead + 2;
        if (chunkTotal > r) chunkTotal = r; // Handle truncated frame

        int dataSize = chunkTotal > 2 ? chunkTotal - 2 : chunkTotal;
        if (dataSize > remainingBytesToRead) dataSize = remainingBytesToRead;

        for (int i = 0; i < dataSize; i++) {
          cleanBuffer.add(buffer[cursor + i]);
        }
        cursor += chunkTotal;
        remainingBytesToRead -= dataSize;
      }
    } else {
      debugPrint("Format: Frame B or Payload-Only (No CRCs)");
      int payloadBytes = byte0;
      if (payloadBytes >= len) payloadBytes = len - 1;
      for (int i = 1; i <= payloadBytes; i++) {
        cleanBuffer.add(buffer[i]);
      }
    }

    if (cleanBuffer.length < 10) {
      debugPrint("Error: Wireless frame too short for header");
      return _PreprocessResult(
        payload: Uint8List(0),
        payloadOffset: 0,
        errorMsg: "Wireless frame too short",
      );
    }

    int ci = cleanBuffer[9];
    info.ciField = ci;
    debugPrint("CI Field: 0x${ci.toRadixString(16)}");

    int fixedHeaderLen = 0;
    if (ci == 0x72 || ci == 0x7E || ci == 0x8D) {
      fixedHeaderLen = 12;
      debugPrint("Header: Long (12 bytes fixed)");
    } else if (ci == 0x7A) {
      fixedHeaderLen = 4;
      debugPrint("Header: Short (4 bytes fixed)");
    } else {
      debugPrint("Header: None/Unknown (0 bytes fixed)");
    }

    bool hasConfig = false;
    int configIdx = 0;

    if (fixedHeaderLen >= 2) {
      configIdx = 10 + fixedHeaderLen - 2;
      if (cleanBuffer.length >= configIdx + 2) {
        hasConfig = true;
      }
    }

    int payloadStart = 10 + fixedHeaderLen;

    if (cleanBuffer.length > payloadStart) {
      int currentLen = cleanBuffer.length - payloadStart;
      bool stripFooter = false;
      bool isEncrypted = false;

      if (hasConfig) {
        int configWord =
            (cleanBuffer[configIdx + 1] << 8) | cleanBuffer[configIdx];
        debugPrint("Config Word: 0x${configWord.toRadixString(16)}");

        int modeLow = cleanBuffer[configIdx] & 0x1F;
        int modeHigh = cleanBuffer[configIdx + 1] & 0x1F;

        if (modeLow == 0x05 || modeHigh == 0x05) {
          bool keyProvided = key != null;
          if (key != null) {
            bool allZero = true;
            for (int k = 0; k < 16; k++) {
              if (key[k] != 0) allZero = false;
            }
            if (allZero) keyProvided = false;
          }

          if (keyProvided) {
            debugPrint(
              "Status: Encrypted (Mode 5) and Key provided. Decrypting...",
            );
            info.isEncrypted = true;
            isEncrypted = true;
          } else {
            debugPrint(
              "Warning: Config suggests Mode 5 but no Key provided. Attempting unencrypted parsing...",
            );
          }
        }
      }

      if (isEncrypted) {
        if (currentLen % 16 == 0) {
          stripFooter = false;
        } else if (currentLen >= 2 && (currentLen - 2) % 16 == 0) {
          stripFooter = true;
        } else {
          debugPrint("Warning: Encrypted Payload Misaligned. Len: $currentLen");
        }
      }

      if (stripFooter && cleanBuffer.length >= 2) {
        debugPrint("Action: Stripping last 2 bytes (Footer/CRC)");
        cleanBuffer.removeLast();
        cleanBuffer.removeLast();
      }
    }

    if (payloadStart > cleanBuffer.length) payloadStart = cleanBuffer.length;

    if (info.isEncrypted && key != null) {
      Uint8List iv = Uint8List(16);
      iv[0] = cleanBuffer[1];
      iv[1] = cleanBuffer[2];
      iv[2] = cleanBuffer[3];
      iv[3] = cleanBuffer[4];
      iv[4] = cleanBuffer[5];
      iv[5] = cleanBuffer[6];
      iv[6] = cleanBuffer[7];
      iv[7] = cleanBuffer[8];
      int accNo = cleanBuffer[10];
      for (int i = 8; i < 16; i++) {
        iv[i] = accNo;
      }

      int encryptedLen = cleanBuffer.length - payloadStart;
      if (encryptedLen % 16 != 0) {
        debugPrint(
          "Warning: Encrypted payload length ($encryptedLen) is not multiple of 16. Decryption may fail or truncate.",
        );
      }

      try {
        final cipher = CBCBlockCipher(AESEngine());
        final params = ParametersWithIV(KeyParameter(key), iv);
        cipher.init(false, params);

        Uint8List input = Uint8List.fromList(cleanBuffer.sublist(payloadStart));

        int decryptableLen = (encryptedLen ~/ 16) * 16;
        Uint8List decrypted = Uint8List(decryptableLen);

        for (
          int offset = 0;
          offset < decryptableLen;
          offset += cipher.blockSize
        ) {
          cipher.processBlock(input, offset, decrypted, offset);
        }

        debugPrint("Decryption Successful.");
        for (int i = 0; i < decryptableLen; i++) {
          cleanBuffer[payloadStart + i] = decrypted[i];
        }

        // Truncate to what was actually decrypted successfully
        if (decryptableLen < encryptedLen) {
          cleanBuffer.length = payloadStart + decryptableLen;
        }

        if (encryptedLen >= 2) {
          if (cleanBuffer[payloadStart] == 0x2F &&
              cleanBuffer[payloadStart + 1] == 0x2F) {
            debugPrint("Action: Stripping Mode 5 Check Bytes (0x2F 0x2F)");
            cleanBuffer.removeRange(payloadStart, payloadStart + 2);
          }
        }
      } catch (e) {
        debugPrint("Error: Decryption Failed. Exception: $e");
        return _PreprocessResult(
          payload: Uint8List(0),
          payloadOffset: 0,
          errorMsg: "Decryption Failed: $e",
        );
      }
    }

    if (payloadStart > cleanBuffer.length) payloadStart = cleanBuffer.length;

    int payloadOffset = 0;
    if (isFrameA) {
      payloadOffset = payloadStart + 3;
    } else {
      payloadOffset = payloadStart + 1;
    }

    Uint8List payloadPart = Uint8List(0);
    if (cleanBuffer.length > payloadStart) {
      payloadPart = Uint8List.fromList(cleanBuffer.sublist(payloadStart));
    }

    return _PreprocessResult(
      payload: payloadPart,
      payloadOffset: payloadOffset,
    );
  }
}
