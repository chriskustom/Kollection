import 'package:flutter/material.dart';
import 'package:kollection/app/features/albums/albums_page.dart';
import 'package:kollection/app/features/gallery/gallery_page.dart';
import 'package:kollection/app/utils/sort_option.dart';

enum Period { day, week, month, year }

enum GraphSort { dateDesc, dateAsc, name }

enum ThreeDialogOptions { save, dismiss, stay }

enum NavRoute {
  gallery('/gallery', Icons.image_rounded, 'Gallery', GalleryPage()),
  albums('/albums', Icons.photo_album_rounded, 'Albums', AlbumsPage());

  const NavRoute(this.route, this.icon, this.label, this.page);
  final String route;
  final IconData icon;
  final String label;
  final Widget page;

  static NavRoute fromRoute(String? route) {
    if (route == null) return NavRoute.gallery;
    return NavRoute.values.firstWhere(
      (e) => e.route == route || route.startsWith(e.route),
      orElse: () => NavRoute.gallery,
    );
  }

  bool matches(String? route) => route != null && route.startsWith(this.route);

  static List<String> get allRoutes => NavRoute.values.map((e) => e.route).toList();

  @override
  String toString() => route;
}

enum AppSetting {
  appearance('appearance', Icons.color_lens_rounded),
  backup('backup', Icons.storage_rounded),
  tabs('tabs', Icons.tab_rounded),
  formats('formats', Icons.text_format_rounded);

  const AppSetting(this.name, this.icon);
  final String name;
  final IconData icon;
}

const double switchScale = 0.85;
const double iconScale = 0.85;

enum SortBy { title, date }

enum SortOrder { asc, desc }

enum GroupBy { day, month }

const sortOptions = [
  SortOption(SortBy.title, SortOrder.asc, 'Title (A–Z)', Icons.sort_by_alpha),
  SortOption(SortBy.title, SortOrder.desc, 'Title (Z–A)', Icons.sort_by_alpha),
  SortOption(SortBy.date, SortOrder.desc, 'Date (Newest)', Icons.schedule),
  SortOption(SortBy.date, SortOrder.asc, 'Date (Oldest)', Icons.schedule),
];
const groupOptions = [
  GroupOption(GroupBy.day, 'Group by day', Icons.calendar_today),
  GroupOption(GroupBy.month, 'Group by month', Icons.calendar_month),
];
const Map<String, Icon> homePageMenu = {'Settings': Icon(Icons.settings), 'About': Icon(Icons.info_outline)};

const double globalElevation = 5.0;

const List<String> emptyPhrases = [
  'Wow. So empty.',
  'Nothing here.',
  'Cue tumbleweeds',
  'Crickets chirping…',
  'Echo… echo…',
  'Bare as a winter tree.',
  'Zero. Zilch. Nada.',
  'Looks like nobody is home.',
  'The void stares back.',
  'Emptier than my inbox.',
  'Nothing to see here. Move along.',
  'Blank canvas.',
  'Just air and echoes.',
  'A hollow silence.',
  'Space… unoccupied.',
  'Deserted as a ghost town.',
  'Not a soul in sight.',
  'Silent as the grave.',
  'Just dust settling.',
  'Vacant and vast.',
  'Nobody showed up.',
  'All quiet on this front.',
  'An empty stage.',
  'No footprints here.',
  'Stillness everywhere.',
  'A whole lot of nothing.',
  'Quiet as midnight.',
  'Left on read by the universe.',
  'Only shadows remain.',
  'A lonely little corner.',
  'Nothing but whitespace.',
  'Unclaimed territory.',
  'Echo chamber of one.',
  'Abandoned by activity.',
  'A pause without play.',
  'Deader than dead air.',
  'Waiting for something… anything.',
  'A barren landscape.',
  'No signs of life.',
  'Just static.',
  'Silence you can hear.',
  'Not even a whisper.',
  'Cleared out completely.',
  'A vacancy sign flickering.',
  'Empty seats all around.',
  'Like a library at closing.',
  'Quiet as snowfall.',
  'Nothing but open space.',
  'A room without guests.',
  'Deserted and still.',
  'Just the sound of nothing.',
  'Swept clean.',
  'A lull without the storm.',
  'No movement detected.',
  'Just a vacant stare.',
  'All hush, no rush.',
  'The lights are on, but nobody’s here.',
  'A calm before anything.',
  'Pure, uninterrupted quiet.',
  'An untouched expanse.',
];

const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const longdateFormats = [
  'timeago',
  'dd/MM/yy',
  'dd/MM/yy h:mm a',
  'dd/MM/yy H:mm',
  'dd.MM.yyyy H:mm',
  'EEE h:mm a',
  'yyyy-MM-dd',
  'yyyy-MM-dd h:mm a',
  'yyyy-MM-dd H:mm',
  'yyyy.MM.dd',
  'yyyy.MM.dd h:mm a',
  'yyyy.MM.dd H:mm',
  'MMM d (EEE) h:mm a',
  'EEE, dd.MM.yyyy H:mm',
  'EEE, dd.MM.yyyy H:mm a',
];

const shortdateFormats = ['d/M/yy', 'M/d/yy', 'd-M-yy', 'M-d-yy', 'd.M.yy', 'M.d.yy', 'dd.MM.yy'];

const fonts = [
  'Arial',
  'Lato',
  'Lunasima',
  'Montserrat',
  'Noto Sans',
  'Open Sans',
  'Roboto',
  'Staatliches',
  'Times New Roman',
  'Wolland',
];
