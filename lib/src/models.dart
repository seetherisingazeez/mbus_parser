class HeaderInfo {
  int cField = 0;
  int ciField = 0;
  String manufacturer = "";
  int deviceId = 0;
  int version = 0;
  int deviceType = 0;
  int signature = 0;
  bool isEncrypted = false;
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

class MBusVifOverride {
  final String? displayName;
  final double? scale;
  final String? units;

  const MBusVifOverride({this.displayName, this.scale, this.units});
}

class MBusDriver {
  /// Defines how certain values mapped exactly by their payload byte ranges should be modified
  /// For instance: `{'0-3': MBusVifOverride(displayName: 'Total Volume', scale: 10)}`
  final Map<String, MBusVifOverride> vifRanges;

  const MBusDriver({this.vifRanges = const {}});
}

class MBusRecord {
  final int id;
  final bool isInstantaneous;
  final String range;
  final String vif;
  final int code;
  final double? valueScaled;
  final String? valueString;
  final String? units;
  final String name;
  final String displayName;
  final int? subUnit;
  final int? storage;
  final int? tariff;
  final int? telegramFollow;

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

class ParsedResult {
  final HeaderInfo? header;
  final List<MBusRecord> records;
  final String? error;

  const ParsedResult({this.header, this.records = const [], this.error});

  bool get hasError => error != null;

  Map<String, dynamic> toJson() {
    return {
      if (header != null) 'header': header!.toJson(),
      'records': records.map((r) => r.toJson()).toList(),
      if (error != null) 'error': error,
    };
  }
}
