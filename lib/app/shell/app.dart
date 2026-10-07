import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:kollection/app/services/navigation_service.dart';
import 'package:kollection/app/theme/theme.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/widgets/app_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget {
  final SharedPreferences preferences;
  const App({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return _AppView(preferences: preferences);
  }
}

class _AppView extends StatelessWidget {
  final SharedPreferences preferences;

  const _AppView({required this.preferences});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        var settings = _AppSettings(
          theme: preferences.getString('theme') ?? 'system',
          font: preferences.getString('font') ?? 'Lato',
          fontSize: preferences.getDouble('font_size') ?? 16,
          color: preferences.getInt('colours'),
          systemColors: preferences.getBool('system_colours') ?? true,
          home: preferences.getString('home') ?? 'gallery',
        );
        final mode = ThemeMode.values.byName(settings.theme.isEmpty ? 'system' : settings.theme);
        var homeRoute = NavRoute.values.byName(settings.home);
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          scaffoldMessengerKey: AppSnackBar.messengerKey,

          theme: AppTheme.light(
            fontFamily: settings.font,
            fontSize: settings.fontSize,
            seedColor: settings.color,
            sysColours: settings.systemColors,
            dynamic: lightDynamic,
          ),

          darkTheme: AppTheme.dark(
            fontFamily: settings.font,
            fontSize: settings.fontSize,
            seedColor: settings.color,
            sysColours: settings.systemColors,
            dynamic: darkDynamic,
          ),

          themeMode: mode,

          home: homeRoute.page,

          onGenerateRoute: (routeSettings) {
            Widget page;
            final pageName = routeSettings.name == '/' ? homeRoute.route : routeSettings.name;
            final navRoute = NavRoute.fromRoute(pageName);
            page = navRoute.page;

            return PageRouteBuilder(
              settings: routeSettings,
              transitionDuration: const Duration(milliseconds: 220),
              reverseTransitionDuration: const Duration(milliseconds: 180),
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: child,
                );
              },
            );
          },

          supportedLocales: const [Locale('en')],
        );
      },
    );
  }
}

class _AppSettings {
  final String theme;
  final String font;
  final double fontSize;
  final int? color;
  final bool systemColors;
  final String home;

  const _AppSettings({
    required this.theme,
    required this.font,
    required this.fontSize,
    required this.color,
    required this.systemColors,
    required this.home,
  });

  @override
  bool operator ==(Object other) {
    return other is _AppSettings &&
        other.theme == theme &&
        other.font == font &&
        other.fontSize == fontSize &&
        other.color == color &&
        other.systemColors == systemColors &&
        other.home == home;
  }

  @override
  int get hashCode => Object.hash(theme, font, fontSize, color, systemColors, home);
}
