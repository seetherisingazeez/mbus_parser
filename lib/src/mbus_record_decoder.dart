import 'dart:math';
import 'dart:typed_data';
import 'mbus_enums.dart';
import 'models.dart';

class MBusRecordDecoder {
  MBusError _error = MBusError.noError;

  MBusError getError() {
    final error = _error;
    _error = MBusError.noError;
    return error;
  }

  int decode(
    Uint8List buffer,
    List<MBusRecord> root, {
    int offset = 0,
    MBusDriver? driver,
  }) {
    int count = 0;
    int index = 0;
    final int size = buffer.length;

    while (index < size) {
      count++;

      int startRecordIndex = index;
      int dif = buffer[index++];
      int difLeast4bit = dif & 0x0F;
      int difFunctionField = (dif & 0x30) >> 4;
      int len = 0;
      int dataCodingType = 0;

      switch (difLeast4bit) {
        case 0x00:
          len = 0;
          dataCodingType = 0;
          break;
        case 0x01:
          len = 1;
          dataCodingType = 1;
          break;
        case 0x02:
          len = 2;
          dataCodingType = 1;
          break;
        case 0x03:
          len = 3;
          dataCodingType = 1;
          break;
        case 0x04:
          len = 4;
          dataCodingType = 1;
          break;
        case 0x05:
          len = 4;
          dataCodingType = 3;
          break;
        case 0x06:
          len = 6;
          dataCodingType = 1;
          break;
        case 0x07:
          len = 8;
          dataCodingType = 1;
          break;
        case 0x08:
          len = 0;
          dataCodingType = 0;
          break;
        case 0x09:
          len = 1;
          dataCodingType = 2;
          break;
        case 0x0A:
          len = 2;
          dataCodingType = 2;
          break;
        case 0x0B:
          len = 3;
          dataCodingType = 2;
          break;
        case 0x0C:
          len = 4;
          dataCodingType = 2;
          break;
        case 0x0D:
          len = 0;
          dataCodingType = 4;
          break;
        case 0x0E:
          len = 6;
          dataCodingType = 2;
          break;
        case 0x0F:
          len = 0;
          dataCodingType = 5;
          break;
      }

      String stringFunctionField = "";
      switch (difFunctionField) {
        case 0:
          stringFunctionField = "";
          break;
        case 1:
          stringFunctionField = "_max";
          break;
        case 2:
          stringFunctionField = "_min";
          break;
        case 3:
          stringFunctionField = "_err";
          break;
      }

      int storageNumber = 0;
      if ((dif & 0x40) == 0x40) {
        storageNumber = 1;
      }

      int difeNumber = 0;
      List<int> dife = List.filled(10, 0);
      bool ifDife = (dif & 0x80) == 0x80;

      while (ifDife && index < size) {
        difeNumber++;
        if (difeNumber < 10) {
          dife[difeNumber] = buffer[index];
        }
        ifDife = (buffer[index] & 0x80) == 0x80;
        index++;
      }

      int subUnit = 0;
      int tariff = 0;

      for (int i = 0; difeNumber > 0 && i <= difeNumber && i < 10; i++) {
        if (i == 0) {
          storageNumber = storageNumber | ((dife[i + 1] & 0x0F) << 1);
        } else {
          storageNumber = storageNumber | ((dife[i + 1] & 0x0F) << (4 * i));
        }
        subUnit = subUnit | (((dife[i + 1] & 0x40) >> 6) << i);
        tariff = tariff | (((dife[i + 1] & 0x30) >> 4) << (2 * i));
      }

      int vif = 0;
      List<int> vifarray = List.filled(10, 0);
      int vifcounter = 0;

      int customVIFlen = 0;
      String customVIF = "";
      bool ifcustomVIF = false;
      int firstVifeExtension = 1;

      do {
        if (index >= size) {
          _error = MBusError.bufferOverflow;
          return 0;
        }

        if (vifcounter < 10) {
          vifarray[vifcounter] = buffer[index++];
        } else {
          index++;
        }

        if ((vifarray[0] & 0x7F) == 0x7C && vifcounter == 0) {
          if (index < size) {
            customVIFlen = buffer[index];
            if (vifarray[0] == 0xFC) {
              index = index + customVIFlen + 1;
            }
          }
        }

        if (vifcounter < 2) {
          vif = (vif << 8) + vifarray[vifcounter];
        } else if (vifcounter == 2 && vif == 0xFDFD) {
          vif = (vif << 8) + vifarray[vifcounter];
        }

        vifcounter++;
      } while (vifcounter <= 10 && (vifarray[vifcounter - 1] & 0x80) == 0x80);

      if (((vifarray[0] & 0x80) == 0x80) &&
          (vifarray[0] != 0xFD) &&
          (vifarray[0] != 0xFC) &&
          (vifarray[0] != 0xFB) &&
          (vifarray[0] != 0xFF)) {
        vif = vifarray[0] & 0x7F;
      }

      if (vifarray[0] == 0x7C) {
        vif = 0x7C00;
      }

      if ((vif & 0x7F) == 0x6D) {
        dataCodingType = 6;
      } else if ((vif & 0x7F) == 0x6C) {
        dataCodingType = 7;
      } else if ((vif & 0x7F00) == 0x7C00) {
        vif = 0xFC00;
        if (vifarray[0] == 0xFC) {
          index = index - customVIFlen - 1;
        }

        if (index + customVIFlen > size) {
          _error = MBusError.bufferOverflow;
        } else {
          List<int> vifBuffer = [];
          for (int i = 0; i <= customVIFlen; i++) {
            if (customVIFlen - i < 21) {
              vifBuffer.insert(0, buffer[index - vifcounter + 1]);
            }
            index++;
          }
          customVIF = String.fromCharCodes(
            vifBuffer,
          ).replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '.');
          ifcustomVIF = true;
        }
      }

      vif = vif & 0xFFFFFF7F;

      int def = _findDefinition(vif);
      if (def < 0) {
        _error = MBusError.unsupportedVif;
        def = 0; // mapped to unknownVif
      }

      int extensionScaler = 0;
      double extensionAdditiveConstant = 0;
      String stringNameExtension = "";
      bool noUnit = false;

      if (vifcounter - 1 > 0) {
        if (vifarray[0] == 0xFB ||
            (vifarray[0] == 0xFD && vifarray[1] != 0xFD) ||
            vifarray[0] == 0xEF ||
            vifarray[0] == 0xFF) {
          firstVifeExtension = 2;
        } else if (vifarray[0] == 0xFD && vifarray[1] == 0xFD) {
          firstVifeExtension = 3;
        } else {
          firstVifeExtension = 1;
        }

        int extensionsCounter = firstVifeExtension;
        while (extensionsCounter < vifcounter) {
          int currentVife = vifarray[extensionsCounter];

          if ((currentVife & 0x7F) == 0x7D) {
            extensionScaler = 3;
          } else if ((currentVife & 0x78) == 0x70) {
            extensionScaler = (currentVife & 7) - 6;
          } else if ((currentVife & 0x7C) == 0x78) {
            int extensionAdditiveConstantScaler = (currentVife & 3) - 3;
            extensionAdditiveConstant = pow(
              10,
              extensionAdditiveConstantScaler,
            ).toDouble();
          } else if ((currentVife & 0x6A) == 0x6A) {
            if (difLeast4bit == 4) {
              dataCodingType = 6;
            } else if (difLeast4bit == 2) {
              dataCodingType = 7;
            }
            stringNameExtension += "_TimeSt";
            noUnit = true;
          } else if (currentVife == 0xFC || currentVife == 0xFF) {
            if (extensionsCounter + 1 < vifcounter) {
              int vifExtensionBuffer = vifarray[extensionsCounter + 1] & 0x7F;
              switch (vifExtensionBuffer) {
                case 0x01:
                  stringNameExtension += "_L1";
                  extensionsCounter++;
                  break;
                case 0x02:
                  stringNameExtension += "_L2";
                  extensionsCounter++;
                  break;
                case 0x03:
                  stringNameExtension += "_L3";
                  extensionsCounter++;
                  break;
                case 0x04:
                  stringNameExtension += "_N";
                  extensionsCounter++;
                  break;
                case 0x05:
                  stringNameExtension += "_L1-L2";
                  extensionsCounter++;
                  break;
                case 0x06:
                  stringNameExtension += "_L2-L3";
                  extensionsCounter++;
                  break;
                case 0x07:
                  stringNameExtension += "_L3-L1";
                  extensionsCounter++;
                  break;
                case 0x08:
                  stringNameExtension += "_Q1";
                  extensionsCounter++;
                  break;
                case 0x09:
                  stringNameExtension += "_Q2";
                  extensionsCounter++;
                  break;
                case 0x0A:
                  stringNameExtension += "_Q3";
                  extensionsCounter++;
                  break;
                case 0x0B:
                  stringNameExtension += "_Q4";
                  extensionsCounter++;
                  break;
                case 0x0C:
                  stringNameExtension += "_delta";
                  extensionsCounter++;
                  break;
                case 0x10:
                  stringNameExtension += "_abs.";
                  extensionsCounter++;
                  break;
              }
            }
          } else if (currentVife == 0x12) {
            stringNameExtension += " Average";
          } else if (currentVife == 0x13) {
            stringNameExtension += " Inverse";
          } else if (currentVife >= 0x20 && currentVife <= 0x27) {
            const rates = [
              " / s",
              " / min",
              " / h",
              " / d",
              " / wk",
              " / mo",
              " / yr",
              " / rev",
            ];
            stringNameExtension += rates[currentVife - 0x20];
          } else if (currentVife == 0x3B) {
            stringNameExtension += " Forward";
          } else if (currentVife == 0x3C) {
            stringNameExtension += " Backward";
          } else if (currentVife >= 0x40 && currentVife <= 0x4B) {
            if (currentVife == 0x40) {
              stringNameExtension += " Lower Limit";
            } else if (currentVife == 0x48) {
              stringNameExtension += " Upper Limit";
            }
          }
          extensionsCounter++;
        }
      }

      if (index + len > size) {
        _error = MBusError.bufferOverflow;
        return 0;
      }

      int value16 = 0;
      int value32 = 0;
      int value =
          0; // Dart handles up to 53-bits safely in JS, 64-bits safely in AOT/JIT, we'll use bigInt if strictly necessary, but M-Bus doesn't usually overflow 53 bits payload
      double valueFloat = 0;

      List<int> date = List.filled(16, 0);
      String valueString = "";
      bool switchAgain = false;
      bool negative = false;
      int asciiValue = 0;

      do {
        switchAgain = false;
        switch (dataCodingType) {
          case 0:
            break;
          case 1: // Integer
            if (len == 2) {
              for (int i = 0; i < len; i++) {
                value16 = (value16 << 8) + buffer[index + len - i - 1];
              }
              // Interpret as signed 16-bit
              if (value16 >= 0x8000) value16 -= 0x10000;
              value = value16;
            } else if (len == 4) {
              for (int i = 0; i < len; i++) {
                value32 = (value32 << 8) + buffer[index + len - i - 1];
              }
              // Interpret as signed 32-bit
              if (value32 >= 0x80000000) value32 -= 0x100000000;
              value = value32;
            } else {
              // Up to 64 bits. For simplicity we assume positive representation of bigger blocks unless manually sign extending.
              // Since standard Dart integer uses safe 53bits for web, larger numbers are typically just mapped as is unsigned.
              for (int i = 0; i < len; i++) {
                value = (value << 8) + buffer[index + len - i - 1];
              }
            }
            break;
          case 2: // BCD
            if (len == 2) {
              for (int i = 0; i < len; i++) {
                int byte = buffer[index + len - i - 1];
                if (i == 0 && (byte & 0xF0) == 0xF0) {
                  byte = byte & 0x0F;
                  negative = true;
                }
                int high = (byte >> 4) & 0x0F;
                int low = byte & 0x0F;
                value16 = (value16 * 100) + (high * 10) + low;
              }
              value = negative ? -value16 : value16;
            } else if (len == 4) {
              for (int i = 0; i < len; i++) {
                int byte = buffer[index + len - i - 1];
                if (i == 0 && (byte & 0xF0) == 0xF0) {
                  byte = byte & 0x0F;
                  negative = true;
                }
                int high = (byte >> 4) & 0x0F;
                int low = byte & 0x0F;
                value32 = (value32 * 100) + (high * 10) + low;
              }
              value = negative ? -value32 : value32;
            } else {
              for (int i = 0; i < len; i++) {
                int byte = buffer[index + len - i - 1];
                if (i == 0 && (byte & 0xF0) == 0xF0) {
                  byte = byte & 0x0F;
                  negative = true;
                }
                int high = (byte >> 4) & 0x0F;
                int low = byte & 0x0F;
                value = (value * 100) + (high * 10) + low;
              }
              if (negative) value = -value;
            }
            break;
          case 3: // Real/Float
            int tempInt = 0;
            for (int i = 0; i < len; i++) {
              tempInt = (tempInt << 8) | buffer[index + len - i - 1];
            }
            if (len == 4) {
              final bd = ByteData(4)..setUint32(0, tempInt, Endian.big);
              valueFloat = bd.getFloat32(0, Endian.big);
            } else if (len == 8) {
              // While standard doesn't typically output 64-bit float here, standardizing conversion
              final bd = ByteData(8)..setUint64(0, tempInt, Endian.big);
              valueFloat = bd.getFloat64(0, Endian.big);
            } else {
              valueFloat = tempInt.toDouble();
            }
            break;
          case 4: // Variable length
            int byteVal = buffer[index];
            if (byteVal >= 0x00 && byteVal <= 0xBF) {
              len = byteVal;
              index++;

              if (index + len > size) {
                _error = MBusError.bufferOverflow;
                break;
              }

              List<int> strBuffer = [];
              for (int i = 0; i < len; i++) {
                int c = buffer[index + (len - i - 1)];
                if (c < 32 || c > 126) {
                  strBuffer.add(46); // '.'
                } else {
                  strBuffer.add(c);
                }
              }
              valueString = String.fromCharCodes(strBuffer);
              asciiValue = 1;
            } else if (byteVal >= 0xC0 && byteVal <= 0xCF) {
              // positive BCD
              len = byteVal - 0xC0;
              index++;
              if (index + len > size) {
                _error = MBusError.bufferOverflow;
                break;
              }
              dataCodingType = 2;
              switchAgain = true;
              break;
            } else if (byteVal >= 0xD0 && byteVal <= 0xDF) {
              // negative BCD
              len = byteVal - 0xD0;
              index++;
              if (index + len > size) {
                _error = MBusError.bufferOverflow;
                break;
              }
              dataCodingType = 2;
              switchAgain = true;
              negative = true;
              break;
            } else if (byteVal >= 0xE0 && byteVal <= 0xEF) {
              // binary number
              len = byteVal - 0xE0;
              index++;
              if (index + len > size) {
                _error = MBusError.bufferOverflow;
                break;
              }
              dataCodingType = 1;
              switchAgain = true;
              break;
            } else if (byteVal >= 0xF0 && byteVal <= 0xFA) {
              // floating point
              len = byteVal - 0xF0;
              index++;
              if (index + len > size) {
                _error = MBusError.bufferOverflow;
                break;
              }
              dataCodingType = 3;
              switchAgain = true;
              break;
            }
            break;
          case 5:
            break;
          case 6: // TimePoint DateTime Typ F
            for (int i = 0; i < len; i++) {
              date[i] = buffer[index + i];
            }
            if ((date[0] & 0x80) != 0) break; // Time valid?

            int year = ((date[2] & 0xE0) >> 5) | ((date[3] & 0xF0) >> 1);
            int month = date[3] & 0x0F;
            int mday = date[2] & 0x1F;
            int hour = date[1] & 0x1F;
            int min = date[0] & 0x3F;

            String yStr = year.toString().padLeft(2, '0');
            String mStr = month.toString().padLeft(2, '0');
            String dayStr = mday.toString().padLeft(2, '0');
            String hStr = hour.toString().padLeft(2, '0');
            String minStr = min.toString().padLeft(2, '0');

            value = int.tryParse("20$yStr$mStr$dayStr$hStr$minStr") ?? 0;
            valueString = "20$yStr-$mStr-$dayStr $hStr:$minStr:00";
            asciiValue = 2;
            break;
          case 7: // TimePoint Date Typ G
            for (int i = 0; i < len; i++) {
              date[i] = buffer[index + i];
            }
            if ((date[1] & 0x0F) > 12) break; // Time valid?

            int year = ((date[0] & 0xE0) >> 5) | ((date[1] & 0xF0) >> 1);
            int month = date[1] & 0x0F;
            int mday = date[0] & 0x1F;

            String yStr = year.toString().padLeft(2, '0');
            String mStr = month.toString().padLeft(2, '0');
            String dayStr = mday.toString().padLeft(2, '0');

            value = int.tryParse("20$yStr$mStr$dayStr") ?? 0;
            valueString = "20$yStr-$mStr-$dayStr";
            asciiValue = 2;
            break;
        }
      } while (switchAgain);

      index += len;

      double scaled = 0;
      int scalar = 0;
      if (def != 0) {
        scalar =
            vifDefs[def].scalar + vif - vifDefs[def].base + extensionScaler;
      }

      if (dataCodingType == 3) {
        scaled = valueFloat;
        if (vifarray[0] != 0xFF) {
          scaled *= pow(10, scalar);
          scaled += extensionAdditiveConstant;
        }
      } else if (vifarray[0] == 0xFF) {
        scaled = value.toDouble();
      } else {
        scaled = value.toDouble();
        scaled *= pow(10, scalar);
        scaled += extensionAdditiveConstant;
      }

      String rangeStr = "${startRecordIndex + offset}-${index - 1 + offset}";
      String vifStr = "0x${vif.toRadixString(16).toUpperCase()}";
      int codeInt = vifDefs[def].code.index;

      double? finalValueScaled = asciiValue != 1 ? scaled : null;
      String? finalValueString = asciiValue > 0 ? valueString : null;

      String? finalUnits;
      if (ifcustomVIF) {
        finalUnits = customVIF;
      } else if (vifDefs[def].code.units.isNotEmpty && !noUnit) {
        finalUnits = vifDefs[def].code.units;
      }

      String finalName =
          "${vifDefs[def].code.name}$stringNameExtension$stringFunctionField";
      String finalDisplayName = finalName;

      // Driver Override Logic
      if (driver != null) {
        MBusVifOverride? override = driver.vifRanges[rangeStr];
        if (override != null) {
          finalDisplayName = override.displayName ?? finalName;

          if (override.scale != null && finalValueScaled != null) {
            if (override.scale != 0) {
              finalValueScaled = finalValueScaled * override.scale!;
            }
          }
          if (override.units != null) {
            finalUnits = override.units;
          }
        }
      }

      int? finalTelegramFollow;
      if (index < size && buffer[index] == 0x1F) {
        finalTelegramFollow = 1;
      }

      root.add(
        MBusRecord(
          id: count,
          isInstantaneous: difFunctionField == 0,
          range: rangeStr,
          vif: vifStr,
          code: codeInt,
          valueScaled: finalValueScaled,
          valueString: finalValueString,
          units: finalUnits,
          name: finalName,
          displayName: finalDisplayName,
          subUnit: subUnit > 0 ? subUnit : null,
          storage: storageNumber > 0 ? storageNumber : null,
          tariff: tariff > 0 ? tariff : null,
          telegramFollow: finalTelegramFollow,
        ),
      );

      if (index < size && buffer[index] == 0x0F) {
        break;
      }
      if (finalTelegramFollow == 1) {
        break;
      }
    }
    return count;
  }

  int _findDefinition(int vif) {
    for (int i = 1; i < vifDefs.length; i++) {
      if (vif >= vifDefs[i].base && vif < (vifDefs[i].base + vifDefs[i].size)) {
        return i;
      }
    }
    return -1;
  }
}
