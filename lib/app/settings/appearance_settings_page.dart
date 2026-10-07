import 'package:flutter/material.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:kollection/app/widgets/colour_picker.dart';
import 'package:provider/provider.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  final AppSetting category = .appearance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: Selector<AppPreferences, bool>(
        selector: (_, prefs) => prefs.prefs.getBool('system_colours') ?? false,
        builder: (context, sysColours, child) {
          return ListView(
            children: [
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 8),
                child: Text('Look', style: Theme.of(context).textTheme.labelMedium),
              ),
              SizedBox(height: 8),
              _themeItem(),
              _useSystemColours(),
              if (!sysColours) _colorScheme(),
              SizedBox(height: 8),
              Divider(),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 8),
                child: Text('Feel', style: Theme.of(context).textTheme.labelMedium),
              ),
              SizedBox(height: 8),
              _enableHaptics(),
            ],
          );
        },
      ),
    );
  }

  Padding _themeItem() {
    const String key = 'theme';
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? 'system',
        builder: (ctx, theme, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.contrast_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text('Theme'),
            subtitle: DropdownButton<String>(
              value: theme,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              onChanged: (value) {
                context.read<AppPreferences>().update((p) => p.setString(key, value!));
              },
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _colorScheme() {
    const String key = 'color';
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? Color.fromARGB(255, 209, 1, 199).toARGB32().toString(),
        builder: (ctx, dbColor, _) {
          final colorScheme = Theme.of(ctx).colorScheme.primary;
          return Column(
            children: [
              ListTile(
                leading: Transform.scale(
                  scale: iconScale,
                  child: Icon(Icons.color_lens_rounded, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text('Colour scheme'),
              ),
              Padding(
                padding: .symmetric(horizontal: 16),
                child: ColorBarPicker(
                  primaryColor: colorScheme,
                  initialColor: dbColor,
                  onChanged: (color) {
                    context.read<AppPreferences>().update((p) => p.setString(key, color.toARGB32().toString()));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Padding _useSystemColours() {
    const String key = 'system_colours';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<AppPreferences, bool>(
        selector: (_, repo) => repo.prefs.getBool(key) ?? false,
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.settings_system_daydream, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Use system colours')),
            trailing: Transform.scale(
              scale: switchScale,
              child: Switch.adaptive(
                value: isEnabled,
                onChanged: (value) {
                  context.read<AppPreferences>().update((p) => p.setBool(key, value));
                },
              ),
            ),
            onTap: () {
              context.read<AppPreferences>().update((p) => p.setBool(key, !isEnabled));
            },
          );
        },
      ),
    );
  }

  Padding _enableHaptics() {
    const String key = 'haptics';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<AppPreferences, bool>(
        selector: (_, repo) => repo.prefs.getBool(key) ?? false,
        builder: (context, isEnabled, _) {
          return ListTile(
            leading: Transform.scale(
              scale: iconScale,
              child: Icon(Icons.vibration_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Padding(padding: EdgeInsets.only(left: 8), child: Text('Enable haptic feedback')),
            trailing: Transform.scale(
              scale: switchScale,
              child: Switch.adaptive(
                value: isEnabled,
                onChanged: (value) {
                  context.read<AppPreferences>().update((p) => p.setBool(key, value));
                },
              ),
            ),
            onTap: () {
              context.read<AppPreferences>().update((p) => p.setBool(key, !isEnabled));
            },
          );
        },
      ),
    );
  }
}
