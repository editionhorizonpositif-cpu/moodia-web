import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Battery _battery = Battery();
  static final Connectivity _connectivity = Connectivity();

  static Future<Map<String, dynamic>> getDeviceMetadata() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final connectivityResult = await _connectivity.checkConnectivity();

    String deviceModel = 'Unknown';
    String osVersion = 'Unknown';
    String osName = 'Unknown';

    // Récupération des informations spécifiques à la plateforme
    if (Platform.isAndroid) {
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        osVersion = androidInfo.version.release;
        osName = 'Android';
      } catch (e) {
        if (kDebugMode) print('⚠️ Erreur deviceInfo Android: $e');
        deviceModel = 'Android Device';
        osVersion = 'Unknown';
        osName = 'Android';
      }
    } else if (Platform.isIOS) {
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
        osName = 'iOS';
      } catch (e) {
        if (kDebugMode) print('⚠️ Erreur deviceInfo iOS: $e');
        deviceModel = 'iOS Device';
        osVersion = 'Unknown';
        osName = 'iOS';
      }
    } else if (Platform.isWindows) {
      try {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceModel = windowsInfo.computerName;
        osVersion = windowsInfo.productName;
        osName = 'Windows';
      } catch (e) {
        deviceModel = 'Windows PC';
        osVersion = 'Windows';
        osName = 'Windows';
      }
    } else if (Platform.isMacOS) {
      try {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceModel = macInfo.model;
        osVersion = macInfo.osRelease;
        osName = 'macOS';
      } catch (e) {
        deviceModel = 'Mac';
        osVersion = 'macOS';
        osName = 'macOS';
      }
    } else if (Platform.isLinux) {
      try {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceModel = linuxInfo.name;
        osVersion = linuxInfo.version ?? 'Linux';
        osName = 'Linux';
      } catch (e) {
        deviceModel = 'Linux PC';
        osVersion = 'Linux';
        osName = 'Linux';
      }
    } else if (kIsWeb) {
      deviceModel = 'Web Browser';
      osVersion = 'Web';
      osName = 'Web';
    }

    // Niveau de batterie (uniquement sur mobile et certaines plateformes supportées)
    int batteryLevel = 0;
    if (!kIsWeb &&
        !Platform.isWindows &&
        !Platform.isLinux &&
        !Platform.isMacOS) {
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (e) {
        if (kDebugMode) print('⚠️ Batterie non disponible: $e');
      }
    }

    // Localisation (uniquement sur mobile)
    double lat = 0.0;
    double lng = 0.0;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Localisation non disponible: $e');
      }
    }

    return {
      'appVersion': packageInfo.version,
      'osVersion': osVersion,
      'osName': osName,
      'deviceModel': deviceModel,
      'networkType': connectivityResult.name,
      'batteryLevel': batteryLevel,
      'locationLat': lat,
      'locationLng': lng,
    };
  }
}
