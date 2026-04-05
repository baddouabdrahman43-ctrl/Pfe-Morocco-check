import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel(
    'com.moroccocheck.app/device_info',
  );

  Future<Map<String, dynamic>> getCheckinDeviceInfo() async {
    final baseInfo = <String, dynamic>{
      'app_platform': defaultTargetPlatform.name,
    };

    if (kIsWeb) {
      return baseInfo;
    }

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final rawInfo = await _channel.invokeMapMethod<String, dynamic>(
            'getAndroidDeviceInfo',
          );

          return <String, dynamic>{
            ...baseInfo,
            ...?rawInfo,
          };
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return baseInfo;
      }
    } catch (_) {
      return baseInfo;
    }
  }
}
