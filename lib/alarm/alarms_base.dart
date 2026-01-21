import 'package:flutter/material.dart';
import 'package:thingsboard_app/thingsboard_client.dart';

final alarmSeverityColors = <AlarmSeverity, Color>{
  AlarmSeverity.CRITICAL: const Color(0xFFD12730),
  AlarmSeverity.MAJOR: const Color(0xFFF66716),
  AlarmSeverity.MINOR: const Color(0xFFF2DA05),
  AlarmSeverity.WARNING: const Color(0xFFFAA405),
  AlarmSeverity.INDETERMINATE: Colors.black.withOpacity(0.38),
};

const alarmSeverityTranslations = <AlarmSeverity, String>{
  AlarmSeverity.CRITICAL: 'Crítico',
  AlarmSeverity.MAJOR: 'Severo',
  AlarmSeverity.MINOR: 'Menor',
  AlarmSeverity.WARNING: 'Aviso',
  AlarmSeverity.INDETERMINATE: 'Indeterminado',
  /*
  AlarmSeverity.CRITICAL: 'Critical',
  AlarmSeverity.MAJOR: 'Major',
  AlarmSeverity.MINOR: 'Minor',
  AlarmSeverity.WARNING: 'Warning',
  AlarmSeverity.INDETERMINATE: 'Indeterminate',
   */
};

const alarmStatusTranslations = <AlarmStatus, String>{
  AlarmStatus.ACTIVE_ACK: 'Activa Reconocida',
  AlarmStatus.ACTIVE_UNACK: 'Activa Sin Reconocer',
  AlarmStatus.CLEARED_ACK: 'Despachada Reconocida',
  AlarmStatus.CLEARED_UNACK: 'Despachada Sin Reconocer',
  /*
  AlarmStatus.ACTIVE_ACK: 'Active Acknowledged',
  AlarmStatus.ACTIVE_UNACK: 'Active Unacknowledged',
  AlarmStatus.CLEARED_ACK: 'Cleared Acknowledged',
  AlarmStatus.CLEARED_UNACK: 'Cleared Unacknowledged',
   */
};
