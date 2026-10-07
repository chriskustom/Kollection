import 'package:flutter/material.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:provider/provider.dart';

class TabsSettingsPage extends StatefulWidget {
  const TabsSettingsPage({super.key});

  @override
  State<TabsSettingsPage> createState() => _TabsSettingsPageState();
}

class _TabsSettingsPageState extends State<TabsSettingsPage> {
  final AppSetting category = .tabs;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(title: category.name.toTitleCase, showSearch: false, showNavBar: false, body: __pageOrder());
  }

  Padding __pageOrder() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Selector<AppPreferences, List<String>>(
        selector: (_, prefs) => prefs.prefs.getStringList('tabs') ?? [],
        builder: (ctx, tabString, _) {
          final tabs = tabString;
          return ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: tabs.length,
            itemBuilder: (_, index) {
              final tab = tabs[index];
              return ListTile(
                key: ValueKey(tab),
                leading: Transform.scale(
                  scale: iconScale,
                  child: Icon(
                    NavRoute.values.byName(tab.toLowerCase()).icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Padding(padding: const EdgeInsets.only(left: 8), child: Text(tab.toTitleCase)),
                trailing: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
              );
            },
            onReorderItem: (oldIndex, newIndex) {
              final reordered = List<String>.from(tabs);
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              context.read<AppPreferences>().update((p) => p.setStringList('tabs', reordered));
            },
          );
        },
      ),
    );
  }
}
