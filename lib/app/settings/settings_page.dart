import 'package:flutter/material.dart';
import 'package:kollection/app/services/app_services.dart';
import 'package:kollection/app/settings/appearance_settings_page.dart';
import 'package:kollection/app/settings/formats_settings_page.dart';
import 'package:kollection/app/settings/tabs_settings_page.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/fade_route.dart';
import 'package:kollection/app/utils/utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, Widget> pages = {
    AppSetting.appearance.name: AppearanceSettings(),
    AppSetting.formats.name: FormatsSettingsPage(),
    AppSetting.tabs.name: TabsSettingsPage(),
  };

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Settings',
      showSearch: false,
      showNavBar: false,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: pages.entries.length,
              itemBuilder: (ctx, idx) {
                final category = pages.keys.elementAt(idx);
                final page = pages[category]!;
                return ListTile(
                  leading: Transform.scale(
                    scale: iconScale,
                    child: Icon(AppSetting.values.byName(category).icon, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(category.toTitleCase),
                  onTap: AppHaptics.tapWithHaptics(context, () async => await Navigator.push<AppSetting>(context, FadeRoute<AppSetting>(page: page))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
