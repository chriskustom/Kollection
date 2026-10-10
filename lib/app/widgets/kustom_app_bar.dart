import 'package:flutter/material.dart';
import 'package:kollection/app/services/app_services.dart';
import 'package:kollection/app/settings/settings_page.dart';
import 'package:kollection/app/theme/theme.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/fade_route.dart';
import 'package:kollection/app/widgets/about_dialog.dart';
import 'package:kollection/app/widgets/menus/triple_dot_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Object>? actions;
  final Widget? sorting;
  final Widget? grouping;
  final List<IconButton>? selectActions;
  final bool showSearch;

  const KustomAppBar({super.key, required this.title, this.actions, this.sorting, this.selectActions, this.showSearch = true, this.grouping});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<KustomAppBar> createState() => _KustomAppBarState();
}

class _KustomAppBarState extends State<KustomAppBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  String home = 'gallery';
  @override
  void initState() {
    super.initState();

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      home = prefs.getString('home') ?? 'gallery';
    });
  }

  Widget? _getLeading(String home) {
    var homeNav = NavRoute.values.byName(home);
    return ModalRoute.of(context)?.settings.name != homeNav.route && Navigator.canPop(context)
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: AppHaptics.selectWithHaptics(context, () {
              Navigator.maybePop(context);
            }),
          )
        : Icon(homeNav.icon);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: _getLeading(home),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Text(widget.title, key: const ValueKey("title"), style: Theme.of(context).textTheme.labelLarge, textScaler: TextScaler.linear(1.1)),
      ),
      actions: _buildMenu(context),
      flexibleSpace: Container(decoration: BoxDecoration(gradient: context.linearGradientLR)),
    );
  }

  List<Widget> _buildMenu(BuildContext context) {
    final items = widget.actions ?? [];
    final menuItems = <MenuItem>[];
    final others = [];

    for (final item in items) {
      if (item is MenuItem) {
        menuItems.add(item);
      } else {
        others.add(item);
      }
    }

    return [
      if (widget.selectActions != null) ...widget.selectActions!,
      if (widget.sorting != null && (widget.selectActions == null || widget.selectActions!.isEmpty)) widget.sorting!,
      if (widget.grouping != null && (widget.selectActions == null || widget.selectActions!.isEmpty)) widget.grouping!,
      if (others.isNotEmpty) ...others,
      TripleDotMenu(
        options: [
          ...menuItems,
          MenuItem(
            title: "Settings",
            icon: const Icon(Icons.settings),
            onTap: () => Navigator.push(context, FadeRoute<AppSetting>(page: const SettingsPage())),
          ),
          MenuItem(title: "About", icon: const Icon(Icons.info_outline), onTap: () => AboutAppDialog.showAbout(this)),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _animController.dispose();

    super.dispose();
  }
}
