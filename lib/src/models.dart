/// Contains the extracted M-Bus Link Layer header information.
/// Includes properties like manufacturer ID, device ID, device type, and whether the payload is encrypted.
class HeaderInfo {
  /// The Control Field (C-field) indicating the function of the message.
  int cField = 0;

  /// The Control Information Field (CI-field) indicating the structure of the data.
  int ciField = 0;

  /// The 3-letter manufacturer string decoded from the 2-byte manufacturer code.
  String manufacturer = "";

  /// The 4-byte identification number of the device.
  int deviceId = 0;

  /// The version or generation of the device.
  int version = 0;

  /// The device type according to the M-Bus specification (e.g. Water meter, Heat meter).
  int deviceType = 0;

  /// The signature or access number of the packet.
  int signature = 0;

  /// Indicates if the telegram utilizes AES encryption (Security Mode 5 or 7).
  bool isEncrypted = false;

  /// Indicates if a valid fixed length header was successfully parsed.
  bool isValid = false;

  Map<String, dynamic> toJson() {
    return {
      if (isValid) 'manufacturer': manufacturer,
      if (isValid)
        'id': deviceId.toRadixString(16).padLeft(8, '0').toUpperCase(),
      if (isValid) 'version': version,
      if (isValid) 'type': deviceType,
      if (isValid) 'type_string': _getDeviceTypeString(),
      if (isValid) 'c_field': cField.toRadixString(16).toUpperCase(),
      if (isValid) 'ci_field': ciField.toRadixString(16).toUpperCase(),
      if (isValid && signature != 0)
        'signature': signature.toRadixString(16).padLeft(4, '0').toUpperCase(),
      if (isValid) 'is_encrypted': isEncrypted,
    };
  }

  String _getDeviceTypeString() {
    switch (deviceType) {
      case 0x00:
        return "Other";
      case 0x01:
        return "Oil meter";
      case 0x02:
        return "Electricity meter";
      case 0x03:
        return "Gas meter";
      case 0x04:
        return "Heat meter";
      case 0x05:
        return "Steam meter";
      case 0x06:
        return "Warm Water (30°C - 90°C) meter";
      case 0x07:
        return "Water meter";
      case 0x08:
        return "Heat Cost Allocator";
      case 0x09:
        return "Compressed air meter";
      case 0x0A:
        return "Cooling load volume at outlet meter";
      case 0x0B:
        return "Cooling load volume at inlet meter";
      case 0x0C:
        return "Heat volume at inlet meter";
      case 0x0D:
        return "Heat / Cooling load meter";
      case 0x0E:
        return "Bus / System component";
      case 0x0F:
        return "Unknown";
      case 0x15:
        return "Hot water (>= 90°C) meter";
      case 0x16:
        return "Cold water meter";
      case 0x17:
        return "Hot / Cold water meter";
      case 0x18:
        return "Pressure meter";
      case 0x19:
        return "A/D converter";
      case 0x1A:
        return "Smoke detector";
      case 0x1B:
        return "Room sensor (e.g., temperature or humidity)";
      case 0x1C:
        return "Gas detector";
      case 0x20:
        return "Breaker (electricity)";
      case 0x21:
        return "Valve (gas or water)";
      case 0x25:
        return "Customer unit (display device)";
      case 0x28:
        return "Waste water";
      case 0x29:
        return "Garbage";
      case 0x2A:
        return "Carbon dioxide";
      case 0x36:
        return "Radio converter (system side)";
      case 0x37:
        return "Radio converter (meter side)";
      default:
        return "Reserved/Unknown";
    }
  }
}

/// A configuration object to override the parsed properties of a specific byte range.
class MBusVifOverride {
  /// The custom display name to replace the default VIF mapping.
  final String? displayName;

  /// The custom scale multiplier to be applied to the raw value.
  final double? scale;

  /// The custom unit metric (e.g. °C, Wh).
  final String? units;

  /// Creates a constraint override to manipulate data mapping for specific bytes.
  const MBusVifOverride({this.displayName, this.scale, this.units});
}

/// A custom driver mapping that allows users to explicitly override M-Bus standard
/// definitions based on the exact byte range position inside the binary payload.
class MBusDriver {
  /// Defines how certain values mapped exactly by their payload byte ranges should be modified.
  /// For instance: `{'0-3': MBusVifOverride(displayName: 'Total Volume', scale: 10)}`
  final Map<String, MBusVifOverride> vifRanges;

  /// Creates a driver mapping initialized with specific payload overrides.
  const MBusDriver({this.vifRanges = const {}});
}

/// A decoded Data Information Block (DIB) mapping to a physical metric or state.
class MBusRecord {
  /// The ordered ID index of the record as it appeared in the packet.
  final int id;

  /// Indicates whether this value is an instantaneous live value or a historical stored value.
  final bool isInstantaneous;

  /// The byte range in the payload that generated this record (ex: "15-18").
  final String range;

  /// The hex Value Information Field token representation.
  final String vif;

  /// The primary VIF numeric code mapping internally to the metric type.
  final int code;

  /// The computed mathematical value of this record after metric scaling is applied.
  final double? valueScaled;

  /// The string-based representation of the value (for dates, binary statuses, or errors).
  final String? valueString;

  /// The engineering unit of measurement (e.g., °C, kWh, m^3).
  final String? units;

  /// The raw internal descriptive name of the metric.
  final String name;

  /// A human-readable display name, which might include custom driver names if overridden.
  final String displayName;

  /// The sub-unit index if this is a duplicated or auxiliary component record.
  final int? subUnit;

  /// The storage number indicating historical record archiving depth.
  final int? storage;

  /// The tariff bracket index for this metric (often used in electricity meters).
  final int? tariff;

  /// Internal protocol telegram sequence index if the metric spans multiple packets.
  final int? telegramFollow;

  /// Creates a strongly typed M-Bus record.
  const MBusRecord({
    required this.id,
    required this.isInstantaneous,
    required this.range,
    required this.vif,
    required this.code,
    this.valueScaled,
    this.valueString,
    this.units,
    required this.name,
    required this.displayName,
    this.subUnit,
    this.storage,
    this.tariff,
    this.telegramFollow,
  });

  /// Converts this record to a map structure for JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_instantaneous': isInstantaneous,
      'range': range,
      'vif': vif,
      'code': code,
      if (valueScaled != null) 'value_scaled': valueScaled,
      if (valueString != null) 'value_string': valueString,
      if (units != null) 'units': units,
      'name': name,
      'display_name': displayName,
      if (subUnit != null) 'subUnit': subUnit,
      if (storage != null) 'storage': storage,
      if (tariff != null) 'tariff': tariff,
      if (telegramFollow != null) 'telegramFollow': telegramFollow,
    };
  }
}

/// A wrapper containing the final results after a buffer is fully processed and unpacked.
class ParsedResult {
  /// The decoded link layer header metadata (Manufacturer, IDs, Flags). Null if headers were stripped.
  final HeaderInfo? header;

  /// A list of strongly-typed M-Bus records that successfully decoded.
  final List<MBusRecord> records;

  /// Contains any decoding warnings or errors encountered. Null on perfectly valid parses.
  final String? error;

  /// Constructs the resulting object from the main [PacketParser].
  const ParsedResult({this.header, this.records = const [], this.error});

  /// True if there was a critical failure during preprocessing or decryption.
  bool get hasError => error != null;

  /// Serializes the results and the encapsulated datasets dynamically into JSON.
  Map<String, dynamic> toJson() {
    return {
      if (header != null) 'header': header!.toJson(),
      'records': records.map((r) => r.toJson()).toList(),
      if (error != null) 'error': error,
    };
  }
}
