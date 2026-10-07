import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:provider/provider.dart';

class FormatsSettingsPage extends StatefulWidget {
  const FormatsSettingsPage({super.key});

  @override
  State<FormatsSettingsPage> createState() => _FormatsSettingsPageState();
}

class _FormatsSettingsPageState extends State<FormatsSettingsPage> {
  final AppSetting category = .formats;
  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: category.name.toTitleCase,
      showSearch: false,
      showNavBar: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [_shortDateFormat(context), _longDateFormat(context), startOfWeek(context), getFont(context), fontSize(context)],
      ),
    );
  }

  Padding startOfWeek(BuildContext context) {
    const String key = 'start_of_week';
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? 'monday',
        builder: (context, dow, _) {
          return ListTile(
            leading: const Icon(Icons.calendar_view_week_rounded),
            title: Text('First day of the week'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              items: [DropdownMenuItem(value: 'monday', child: Text('Monday')), DropdownMenuItem(value: 'sunday', child: Text('Sunday'))].toList(),
              value: dow,
              onChanged: (value) {
                if (value == null) return;
                context.read<AppPreferences>().update((p) => p.setString(key, value));
              },
            ),
          );
        },
      ),
    );
  }

  Padding fontSize(BuildContext context) {
    const String key = 'font_size';
    return Padding(
      padding: EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? '16',
        builder: (context, fontSize, _) {
          return ListTile(
            leading: const Icon(Icons.format_size_rounded),
            title: Text('Font size'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              items: fontSizes(),
              value: fontSize,
              onChanged: (value) {
                if (value == null) return;
                context.read<AppPreferences>().update((p) => p.setString(key, value));
              },
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> fontSizes() {
    return List.generate(10, (index) {
      final size = 8 + index * 2;
      return DropdownMenuItem(value: size.toString(), child: Text(size.toString()));
    });
  }

  Padding getFont(BuildContext context) {
    const String key = 'font';

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? 'Lato',
        builder: (context, font, _) {
          return ListTile(
            leading: const Icon(Icons.font_download_rounded),
            title: const Text('Global font'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              value: fonts.contains(font) ? font : fonts.first,
              items: fonts
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f, style: TextStyle(fontFamily: f)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                context.read<AppPreferences>().update((p) => p.setString(key, value));
              },
            ),
          );
        },
      ),
    );
  }

  Padding _shortDateFormat(BuildContext ctx) {
    const String key = 'short_date_format';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? 'd/M/yy',
        builder: (context, savedFormat, _) {
          final safeFormat = shortdateFormats.contains(savedFormat) ? savedFormat : null;
          return ListTile(
            leading: const Icon(Icons.today_rounded),
            title: const Text('Short date format'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              items: buildDateFormatEntries(shortdateFormats),
              value: safeFormat,
              onChanged: (value) {
                if (value == null) return;
                context.read<AppPreferences>().update((p) => p.setString(key, value));
              },
            ),
          );
        },
      ),
    );
  }

  Padding _longDateFormat(BuildContext ctx) {
    const String key = 'long_date_format';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Selector<AppPreferences, String>(
        selector: (_, repo) => repo.prefs.getString(key) ?? 'EEE, dd.MM.yyyy H:mm a',
        builder: (context, savedFormat, _) {
          final safeFormat = longdateFormats.contains(savedFormat) ? savedFormat : null;
          return ListTile(
            leading: const Icon(Icons.date_range_rounded),
            title: const Text('Long date format'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              padding: EdgeInsets.zero,
              items: buildDateFormatEntries(longdateFormats),
              value: safeFormat,
              onChanged: (value) {
                if (value == null) return;
                context.read<AppPreferences>().update((p) => p.setString(key, value));
              },
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> buildDateFormatEntries(List<String> formats) {
    final now = DateTime.now();

    return formats.map((format) {
      return DropdownMenuItem<String>(value: format, child: Text('$format — ${DateFormat(format).format(now)}'));
    }).toList();
  }
}
