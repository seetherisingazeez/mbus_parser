enum MBusCode {
  unknownVif,
  energyWh,
  energyJ,
  volumeM3,
  massKg,
  onTimeS,
  onTimeMin,
  onTimeH,
  onTimeDays,
  operatingTimeS,
  operatingTimeMin,
  operatingTimeH,
  operatingTimeDays,
  powerW,
  powerJH,
  volumeFlowM3H,
  volumeFlowM3Min,
  volumeFlowM3S,
  massFlowKgH,
  flowTemperatureC,
  returnTemperatureC,
  temperatureDiffK,
  externalTemperatureC,
  pressureBar,
  timePointDate,
  timePointDatetime,
  hca,
  avgDurationS,
  avgDurationMin,
  avgDurationH,
  avgDurationDays,
  actualDurationS,
  actualDurationMin,
  actualDurationH,
  actualDurationDays,
  fabricationNumber,
  enhancedIdentification,
  busAddress,
  credit,
  debit,
  accessNumber,
  medium,
  manufacturer,
  parameterSetId,
  modelVersion,
  hardwareVersion,
  firmwareVersion,
  softwareVersion,
  customerLocation,
  customer,
  errorFlags,
  errorMask,
  digitalOutput,
  digitalInput,
  baudrateBps,
  responseDelayTime,
  retry,
  sizeOfStorageBlock,
  storageIntervalMonth,
  durationSinceReadout,
  durationOfTariff,
  generic,
  volts,
  amperes,
  resetCounter,
  cumulationCounter,
  specialSupplierInfo,
  remainBatLifeDay,
  currentSelectedApl,
  subDevices,
  remainBatLifeMonth,
  carbonDioxidePpm,
  carbonMonoxidePpm,
  volatileOrgCompPpb,
  volatileOrgCompUgM3,
  particlesUnspecUgM3,
  particlesPm1UgM3,
  particlesPm25UgM3,
  particlesPm10UgM3,
  particlesUnspec1m3,
  particlesPm11m3,
  particlesPm251m3,
  particlesPm101m3,
  illuminanceLux,
  luminousIdensityCd,
  radiantFluxDens,
  windSpeedMS,
  rainfallLMm,
  formazinNephelometerU,
  potentialHydrogenPh,
  dismountsCounter,
  testButtonCounter,
  alarmCounter,
  alarmMuteCounter,
  obstacleDetectCounter,
  smokeEntriesCounter,
  smokeChamberDefects,
  selfTestCounter,
  sounderDefectCounter,
  decibelA,
  batteryPercentage,
  chamberPollutionLevel,
  distanceMm,
  moistureLevelPercent,
  pressureSensStatus,
  smokeAlarmStatus,
  coAlarmStatus,
  heatAlarmStatus,
  doorWindowSensStatus,
  reactiveEnergy,
  reactivePower,
  relativeHumidity,
  volumeFt3,
  volumeGal,
  volumeFlowGalM,
  volumeFlowGalH,
  apparentPower,
  flowTemperatureF,
  returnTemperatureF,
  temperatureDiffF,
  externalTemperatureF,
  temperatureLimitF,
  temperatureLimitC,
  maxPowerW,
  phaseVoltDeg,
  phaseCurrDeg,
  frequency,
  customizedVif,
  manufacturerSpecific,
}

extension MBusCodeExtension on MBusCode {
  String get units {
    switch (this) {
      case MBusCode.energyWh:
        return "Wh";
      case MBusCode.energyJ:
        return "J";
      case MBusCode.volumeM3:
        return "m³";
      case MBusCode.massKg:
        return "kg";
      case MBusCode.onTimeS:
      case MBusCode.operatingTimeS:
      case MBusCode.avgDurationS:
      case MBusCode.actualDurationS:
        return "s";
      case MBusCode.onTimeMin:
      case MBusCode.operatingTimeMin:
      case MBusCode.avgDurationMin:
      case MBusCode.actualDurationMin:
        return "min";
      case MBusCode.onTimeH:
      case MBusCode.operatingTimeH:
      case MBusCode.avgDurationH:
      case MBusCode.actualDurationH:
        return "h";
      case MBusCode.onTimeDays:
      case MBusCode.operatingTimeDays:
      case MBusCode.avgDurationDays:
      case MBusCode.actualDurationDays:
        return "d";
      case MBusCode.powerW:
      case MBusCode.maxPowerW:
        return "W";
      case MBusCode.powerJH:
        return "J/h";
      case MBusCode.volumeFlowM3H:
        return "m³/h";
      case MBusCode.volumeFlowM3Min:
        return "m³/min";
      case MBusCode.volumeFlowM3S:
        return "m³/s";
      case MBusCode.massFlowKgH:
        return "kg/h";
      case MBusCode.flowTemperatureC:
      case MBusCode.returnTemperatureC:
      case MBusCode.externalTemperatureC:
      case MBusCode.temperatureLimitC:
        return "°C";
      case MBusCode.temperatureDiffK:
        return "K";
      case MBusCode.pressureBar:
        return "bar";
      case MBusCode.timePointDate:
        return "YYYYMMDD";
      case MBusCode.timePointDatetime:
        return "YYYYMMDDhhmm";
      case MBusCode.baudrateBps:
        return "Baud";
      case MBusCode.responseDelayTime:
        return "Bit times";
      case MBusCode.retry:
        return "transmissions";
      case MBusCode.volts:
        return "V";
      case MBusCode.amperes:
        return "A";
      case MBusCode.durationSinceReadout:
      case MBusCode.durationOfTariff:
        return "h";
      case MBusCode.remainBatLifeDay:
        return "d";
      default:
        return "";
    }
  }

  String get name {
    return toString().split('.').last;
  }
}

enum MBusError {
  noError,
  bufferOverflow,
  unsupportedCoding,
  unsupportedRange,
  unsupportedVif,
  negativeValue,
}

class VifDefType {
  final MBusCode code;
  final int base;
  final int size;
  final int scalar;

  const VifDefType(this.code, this.base, this.size, this.scalar);
}

const List<VifDefType> vifDefs = [
  VifDefType(MBusCode.unknownVif, 0x7E, 1, 0),
  VifDefType(MBusCode.energyWh, 0x00, 8, -3),
  VifDefType(MBusCode.energyJ, 0x08, 8, 0),
  VifDefType(MBusCode.volumeM3, 0x10, 8, -6),
  VifDefType(MBusCode.massKg, 0x18, 8, -3),
  VifDefType(MBusCode.onTimeS, 0x20, 1, 0),
  VifDefType(MBusCode.onTimeMin, 0x21, 1, 0),
  VifDefType(MBusCode.onTimeH, 0x22, 1, 0),
  VifDefType(MBusCode.onTimeDays, 0x23, 1, 0),
  VifDefType(MBusCode.operatingTimeS, 0x24, 1, 0),
  VifDefType(MBusCode.operatingTimeMin, 0x25, 1, 0),
  VifDefType(MBusCode.operatingTimeH, 0x26, 1, 0),
  VifDefType(MBusCode.operatingTimeDays, 0x27, 1, 0),
  VifDefType(MBusCode.powerW, 0x28, 8, -3),
  VifDefType(MBusCode.powerJH, 0x30, 8, 0),
  VifDefType(MBusCode.volumeFlowM3H, 0x38, 8, -6),
  VifDefType(MBusCode.volumeFlowM3Min, 0x40, 8, -7),
  VifDefType(MBusCode.volumeFlowM3S, 0x48, 8, -9),
  VifDefType(MBusCode.massFlowKgH, 0x50, 8, -3),
  VifDefType(MBusCode.flowTemperatureC, 0x58, 4, -3),
  VifDefType(MBusCode.returnTemperatureC, 0x5C, 4, -3),
  VifDefType(MBusCode.temperatureDiffK, 0x60, 4, -3),
  VifDefType(MBusCode.externalTemperatureC, 0x64, 4, -3),
  VifDefType(MBusCode.pressureBar, 0x68, 4, -3),
  VifDefType(MBusCode.timePointDate, 0x6C, 1, 0),
  VifDefType(MBusCode.timePointDatetime, 0x6D, 1, 0),
  VifDefType(MBusCode.hca, 0x6E, 1, 0),
  VifDefType(MBusCode.avgDurationS, 0x70, 1, 0),
  VifDefType(MBusCode.avgDurationMin, 0x71, 1, 0),
  VifDefType(MBusCode.avgDurationH, 0x72, 1, 0),
  VifDefType(MBusCode.avgDurationDays, 0x73, 1, 0),
  VifDefType(MBusCode.actualDurationS, 0x74, 1, 0),
  VifDefType(MBusCode.actualDurationMin, 0x75, 1, 0),
  VifDefType(MBusCode.actualDurationH, 0x76, 1, 0),
  VifDefType(MBusCode.actualDurationDays, 0x77, 1, 0),
  VifDefType(MBusCode.fabricationNumber, 0x78, 1, 0),
  VifDefType(MBusCode.enhancedIdentification, 0x79, 1, 0),
  VifDefType(MBusCode.busAddress, 0x7A, 1, 0),
  VifDefType(MBusCode.volumeM3, 0x933A, 1, -3),
  VifDefType(MBusCode.volumeM3, 0x943A, 1, -2),
  VifDefType(MBusCode.credit, 0xFD00, 4, -3),
  VifDefType(MBusCode.debit, 0xFD04, 4, -3),
  VifDefType(MBusCode.accessNumber, 0xFD08, 1, 0),
  VifDefType(MBusCode.medium, 0xFD09, 1, 0),
  VifDefType(MBusCode.manufacturer, 0xFD0A, 1, 0),
  VifDefType(MBusCode.parameterSetId, 0xFD0B, 1, 0),
  VifDefType(MBusCode.modelVersion, 0xFD0C, 1, 0),
  VifDefType(MBusCode.hardwareVersion, 0xFD0D, 1, 0),
  VifDefType(MBusCode.firmwareVersion, 0xFD0E, 1, 0),
  VifDefType(MBusCode.softwareVersion, 0xFD0F, 1, 0),
  VifDefType(MBusCode.customerLocation, 0xFD10, 1, 0),
  VifDefType(MBusCode.customer, 0xFD11, 1, 0),
  VifDefType(MBusCode.errorFlags, 0xFD17, 1, 0),
  VifDefType(MBusCode.errorMask, 0xFD18, 1, 0),
  VifDefType(MBusCode.digitalOutput, 0xFD1A, 1, 0),
  VifDefType(MBusCode.digitalInput, 0xFD1B, 1, 0),
  VifDefType(MBusCode.baudrateBps, 0xFD1C, 1, 0),
  VifDefType(MBusCode.responseDelayTime, 0xFD1D, 1, 0),
  VifDefType(MBusCode.retry, 0xFD1E, 1, 0),
  VifDefType(MBusCode.sizeOfStorageBlock, 0xFD22, 1, 0),
  VifDefType(MBusCode.storageIntervalMonth, 0xFD28, 1, 0),
  VifDefType(MBusCode.durationSinceReadout, 0xFD2C, 4, 0),
  VifDefType(MBusCode.durationOfTariff, 0xFD31, 3, 0),
  VifDefType(MBusCode.generic, 0xFD3A, 1, 0),
  VifDefType(MBusCode.volts, 0xFD40, 16, -9),
  VifDefType(MBusCode.amperes, 0xFD50, 16, -12),
  VifDefType(MBusCode.resetCounter, 0xFD60, 1, 0),
  VifDefType(MBusCode.cumulationCounter, 0xFD61, 1, 0),
  VifDefType(MBusCode.specialSupplierInfo, 0xFD67, 1, 0),
  VifDefType(MBusCode.remainBatLifeDay, 0xFD74, 1, 0),
  VifDefType(MBusCode.currentSelectedApl, 0xFDFD00, 1, 0),
  VifDefType(MBusCode.subDevices, 0xFDFD01, 1, 0),
  VifDefType(MBusCode.remainBatLifeMonth, 0xFDFD02, 1, 0),
  VifDefType(MBusCode.carbonDioxidePpm, 0xFDFD10, 2, 0),
  VifDefType(MBusCode.carbonMonoxidePpm, 0xFDFD12, 2, 0),
  VifDefType(MBusCode.volatileOrgCompPpb, 0xFDFD14, 2, 0),
  VifDefType(MBusCode.volatileOrgCompUgM3, 0xFDFD16, 1, 0),
  VifDefType(MBusCode.particlesUnspecUgM3, 0xFDFD17, 1, 0),
  VifDefType(MBusCode.particlesPm1UgM3, 0xFDFD18, 1, 0),
  VifDefType(MBusCode.particlesPm25UgM3, 0xFDFD19, 1, 0),
  VifDefType(MBusCode.particlesPm10UgM3, 0xFDFD1A, 1, 0),
  VifDefType(MBusCode.particlesUnspec1m3, 0xFDFD1B, 1, 5),
  VifDefType(MBusCode.particlesPm11m3, 0xFDFD1C, 1, 5),
  VifDefType(MBusCode.particlesPm251m3, 0xFDFD1D, 1, 5),
  VifDefType(MBusCode.particlesPm101m3, 0xFDFD1E, 1, 5),
  VifDefType(MBusCode.illuminanceLux, 0xFDFD1F, 1, 0),
  VifDefType(MBusCode.luminousIdensityCd, 0xFDFD20, 1, 0),
  VifDefType(MBusCode.radiantFluxDens, 0xFDFD21, 1, 0),
  VifDefType(MBusCode.windSpeedMS, 0xFDFD22, 1, 0),
  VifDefType(MBusCode.rainfallLMm, 0xFDFD23, 1, 0),
  VifDefType(MBusCode.formazinNephelometerU, 0xFDFD25, 1, 0),
  VifDefType(MBusCode.potentialHydrogenPh, 0xFDFD27, 1, 0),
  VifDefType(MBusCode.dismountsCounter, 0xFDFD2C, 1, 0),
  VifDefType(MBusCode.testButtonCounter, 0xFDFD2D, 1, 0),
  VifDefType(MBusCode.alarmCounter, 0xFDFD2E, 1, 0),
  VifDefType(MBusCode.alarmMuteCounter, 0xFDFD2F, 1, 0),
  VifDefType(MBusCode.obstacleDetectCounter, 0xFDFD30, 1, 0),
  VifDefType(MBusCode.smokeEntriesCounter, 0xFDFD31, 1, 0),
  VifDefType(MBusCode.smokeChamberDefects, 0xFDFD32, 1, 0),
  VifDefType(MBusCode.selfTestCounter, 0xFDFD33, 1, 0),
  VifDefType(MBusCode.sounderDefectCounter, 0xFDFD34, 1, 0),
  VifDefType(MBusCode.decibelA, 0xFDFD36, 1, 0),
  VifDefType(MBusCode.batteryPercentage, 0xFDFD38, 1, 0),
  VifDefType(MBusCode.chamberPollutionLevel, 0xFDFD39, 1, 0),
  VifDefType(MBusCode.distanceMm, 0xFDFD3A, 2, 0),
  VifDefType(MBusCode.moistureLevelPercent, 0xFDFD3E, 1, 0),
  VifDefType(MBusCode.pressureSensStatus, 0xFDFD40, 1, 0),
  VifDefType(MBusCode.smokeAlarmStatus, 0xFDFD41, 1, 0),
  VifDefType(MBusCode.coAlarmStatus, 0xFDFD42, 1, 0),
  VifDefType(MBusCode.heatAlarmStatus, 0xFDFD43, 1, 0),
  VifDefType(MBusCode.doorWindowSensStatus, 0xFDFD44, 1, 0),
  VifDefType(MBusCode.energyWh, 0xFB00, 2, 5),
  VifDefType(MBusCode.reactiveEnergy, 0xFB02, 2, 0),
  VifDefType(MBusCode.energyJ, 0xFB08, 2, 8),
  VifDefType(MBusCode.volumeM3, 0xFB10, 2, 2),
  VifDefType(MBusCode.reactivePower, 0xFB14, 4, -3),
  VifDefType(MBusCode.massKg, 0xFB18, 2, 5),
  VifDefType(MBusCode.relativeHumidity, 0xFB1A, 2, -1),
  VifDefType(MBusCode.volumeFt3, 0xFB21, 1, -1),
  VifDefType(MBusCode.volumeGal, 0xFB22, 2, -1),
  VifDefType(MBusCode.volumeFlowGalM, 0xFB24, 1, -3),
  VifDefType(MBusCode.volumeFlowGalM, 0xFB25, 1, 0),
  VifDefType(MBusCode.volumeFlowGalH, 0xFB26, 1, 0),
  VifDefType(MBusCode.powerW, 0xFB28, 2, 5),
  VifDefType(MBusCode.phaseVoltDeg, 0xFB2A, 1, -1),
  VifDefType(MBusCode.phaseCurrDeg, 0xFB2B, 1, -1),
  VifDefType(MBusCode.frequency, 0xFB2C, 4, -3),
  VifDefType(MBusCode.powerJH, 0xFB30, 2, 8),
  VifDefType(MBusCode.apparentPower, 0xFB34, 4, -3),
  VifDefType(MBusCode.flowTemperatureF, 0xFB58, 4, -3),
  VifDefType(MBusCode.returnTemperatureF, 0xFB5C, 4, -3),
  VifDefType(MBusCode.temperatureDiffF, 0xFB60, 4, -3),
  VifDefType(MBusCode.externalTemperatureF, 0xFB64, 4, -3),
  VifDefType(MBusCode.temperatureLimitF, 0xFB70, 4, -3),
  VifDefType(MBusCode.temperatureLimitC, 0xFB74, 4, -3),
  VifDefType(MBusCode.maxPowerW, 0xFB78, 8, -3),
  VifDefType(MBusCode.customizedVif, 0xFC00, 254, 0),
  VifDefType(MBusCode.manufacturerSpecific, 0xFF00, 254, 0),
];
