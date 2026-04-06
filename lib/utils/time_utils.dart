// lib/utils/time_utils.dart
import 'package:flutter/material.dart';

class TimeUtils {
  static TimeOfDay? fromHourMinute(int? hour, int? minute) {
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Map<String, int?> toHourMinute(TimeOfDay? time) {
    return {'reminderHour': time?.hour, 'reminderMinute': time?.minute};
  }

  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
