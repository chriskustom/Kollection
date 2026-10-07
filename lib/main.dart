import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/shell/app.dart';
import 'package:platform_detail/platform_detail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:window_manager/window_manager.dart';

MethodChannel androidChannel = const MethodChannel("com.kustom.kollection/android");
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (PlatformDetail.isDesktop) {
    await windowManager.ensureInitialized();
    windowManager.setMinimumSize(Size(360, 640));
    windowManager.setMaximumSize(Size(414, 896));
  }

  tz.initializeTimeZones();
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppPreferences(prefs: prefs))],
      child: App(preferences: prefs),
    ),
  );
}
