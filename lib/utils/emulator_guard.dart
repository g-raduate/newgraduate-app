import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class EmulatorGuard {
  static Future<bool> isEmulator() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        final isEmu = (info.isPhysicalDevice == false) ||
            info.fingerprint.contains('generic') ||
            info.model.contains('google_sdk') ||
            info.manufacturer.contains('Genymotion') ||
            info.brand.contains('generic') ||
            info.product.contains('sdk') ||
            info.hardware.contains('goldfish') ||
            info.hardware.contains('ranchu');
        return isEmu;
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        final name = info.name.toLowerCase();
        final isSim = name.contains('simulator') || name.contains('xcode');
        return isSim || (info.isPhysicalDevice == false);
      }
    } catch (_) {}
    return false;
  }
}
