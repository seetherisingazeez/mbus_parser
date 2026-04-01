import 'package:mbus_parser/mbus_parser.dart';

void main() {
  /// Simple Demonstration of parsing a Wireless M-Bus Data Frame
  ///
  /// This example decodes an unencrypted or encrypted packet.
  /// If it's AES Security Mode 5 encrypted, you must provide the symmetric `keyHex`.

  // Here is an encrypted Mode 5 Room Sensor payload
  final hexString =
      '4E44333033511100091B35237A12034025C74C59F0C0EBA4AFB28449DF412923EEC1EEEA876A12659C36569E9F0ED40C77235D413DF27D1C991CDF039CA236D0F4B43E827BF9765290C6C5F16631E59EAB8EC3BBEDF64841';
  final keyHex = 'DEC65EB1DFEE4C7514D9592021BBC0C8';

  // Example of using a Custom Driver to override VIF translations on specific ranges
  // Here, we rename the record at range '15-18' and change its scale/units.
  final customDriver = MBusDriver(
    vifRanges: {
      '15-18': MBusVifOverride(
        displayName: 'Outdoor Temperature',
        scale: 0.1,
        units: '°C',
      ),
    },
  );

  print('Parsing 86-byte Room Sensor payload...');
  // Automatically handles unpacking, decryption, truncation, overflows, and driver overrides!
  final result = PacketParser.parseHex(
    hexString,
    keyHex: keyHex,
    driver: customDriver,
  );

  if (result.hasError) {
    print('Failed to parse: \${result.error}');
    return;
  }

  print('');
  print('--- HEADER INFO ---');
  print('Manufacturer: \${result.header?.manufacturer}');
  print('Device ID: \${result.header?.id}');
  print('Device Type: \${result.header?.typeString} (\${result.header?.type})');
  print('Is Encrypted: \${result.header?.isEncrypted}');

  print('');
  for (final record in result.records) {
    final label = record.displayName;
    final value = record.valueScaled;
    final unit = record.units;

    print('- $label: $value $unit');
  }
}
