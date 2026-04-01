# MBus Parser

A robust, pure-Dart library for parsing [M-Bus (EN 13757-3)](https://en.wikipedia.org/wiki/Meter-Bus) and [Wireless M-Bus (EN 13757-4)](https://en.wikipedia.org/wiki/Wireless_M-Bus) telegrams.

This package allows you to decode payloads from smart meters (electricity, gas, water, heat), sensors (temperature, humidity), and other industrial devices using the M-Bus protocol. It natively supports unpacking nested Data Information Blocks (DIBs), decoding Manufacturer IDs, scaled unit conversions, and built-in AES-128-CBC decryption.

## Features

- **Protocol Support**: Decodes Wired M-Bus (EN 13757-3) and Wireless M-Bus (EN 13757-4) formats.
- **AES Decryption**: Built-in support for AES Mode 5 decryption. Simply pass the 16-byte hex symmetric key.
- **Robust Error Handling**: Lenient architecture that gracefully survives truncated frames, missing padding, and unknown VIF/DIF extensions.
- **Detailed Decoded output**: Automatically applies unit scaling and human-readable string descriptions for instantaneous values, errors, dates, etc.
- **No Native Dependencies**: Pure Dart. This can be run anywhere Dart can run (iOS, Android, Web, Mac, Linux, Windows).
- **M-Bus Value Information Fields (VIF) & Data Information Fields (DIF)**: Handles advanced secondary addressing and multidimensional historical records.

## Usage

### Simple Unencrypted Parsing

Simply import the package and use the `PacketParser.parseHex` function to extract the records.

```dart
import 'package:mbus_parser/mbus_parser.dart';

void main() {
  // A raw unencrypted M-Bus hex telegram from a standard meter
  final hexString = '5e443330851416000a2a7a0d0000252f2f026537084265320882...';

  final result = PacketParser.parseHex(hexString);

  if (result.hasError) {
    print('Failed to parse: \${result.error}');
    return;
  }

  print('Manufacturer: \${result.header.manufacturer}');
  print('Device ID: \${result.header.id}');

  for (final record in result.records) {
    print('\${record.name}: \${record.valueScaled} \${record.units}');
  }
}
```

### Decrypting AES Mode 5 Payloads

Many Wireless M-Bus smart meters encrypt their payloads using AES-128 CBC (Security Mode 5). Simply pass the designated `keyHex` to automatically trigger decryption at the Application Layer.

```dart
import 'package:mbus_parser/mbus_parser.dart';

void main() {
  // Encrypted Wireless M-Bus Frame
  final hexString = '4E44333033511100091B35237A12034025C74C59F0C0EBA4AFB28449DF412923EE...';
  
  // 16-byte AES-128 unique device key
  final keyHex = 'DEC65EB1DFEE4C7514D9592021BBC0C8';

  final result = PacketParser.parseHex(hexString, keyHex: keyHex);

  if (!result.hasError) {
    print('Decrypted \${result.records.length} records successfully!');
    for(var rec in result.records) {
      // E.g. "externalTemperatureC: 23.84 °C"
      print('\${rec.name}: \${rec.valueScaled} \${rec.units}');
    }
  }
}
```

## Supported VIFs (Value Information Fields)
The decoder supports all standard primary VIFs such as:
- Energy (Wh, J)
- Volume ($m^3$, liters)
- Mass (kg)
- Power (W, J/h)
- Volume Flow ($m^3$/h, liters/h)
- Temperature (°C)
- Pressure (bar)
- Time Point (Dates & Times)
- Operating Times (days, hours)
- Voltage (V) & Current (A)

*This project is heavily inspired by existing C/C++ M-Bus protocol decoders but re-written from scratch for memory safety, concurrency, and cross-platform use.*
