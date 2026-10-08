import 'package:flutter/material.dart';
import 'package:kollection/app/services/app_services.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/sort_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({
    super.key,
    required this.sortOrder,
    required this.sortBy,
    required this.setState,
    this.options = sortOptions,
  });
  final List<SortOption> options;
  final SortOrder sortOrder;
  final SortBy sortBy;
  final Function(SortBy, SortOrder) setState;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      onOpened: () => AppHaptics.selection(context),
      onSelected: (option) async {
        AppHaptics.selection(context);
        var prefs = await SharedPreferences.getInstance();
        prefs.setString('sortBy', option.sortBy.name);
        prefs.setString('sortOrder', option.order.name);

        setState(option.sortBy, option.order);
      },
      itemBuilder: (context) => options.map((option) {
        final isSelected = option.sortBy == sortBy && option.order == sortOrder;
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(option.label)),
              if (isSelected) const Icon(Icons.check, size: 18, color: Colors.blue),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class GroupMenu extends StatelessWidget {
  const GroupMenu({super.key, required this.groupBy, required this.setState, this.options = groupOptions});
  final List<GroupOption> options;
  final GroupBy groupBy;
  final Function(GroupBy) setState;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GroupOption>(
      icon: const Icon(Icons.group),
      onOpened: () => AppHaptics.selection(context),
      onSelected: (option) async {
        AppHaptics.selection(context);
        var prefs = await SharedPreferences.getInstance();
        prefs.setString('groupBy', option.groupBy.name);

        setState(option.groupBy);
      },
      itemBuilder: (context) => options.map((option) {
        final isSelected = option.groupBy == groupBy;
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(option.label)),
              if (isSelected) const Icon(Icons.check, size: 18, color: Colors.blue),
            ],
          ),
        );
      }).toList(),
    );
  }
}
