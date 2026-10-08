import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:kollection/app/widgets/image_list.dart';
import 'package:kollection/app/widgets/menus/sort_menu.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<StatefulWidget> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<dynamic> images = [];

  @override
  void initState() {
    loadMedia();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Gallery',
      sorting: _sortMenu(),
      grouping: _groupMenu(),
      body: ImageList(images: images),
    );
  }

  Widget _sortMenu() {
    return Selector<AppPreferences, (String, String)>(
      selector: (p0, p) => (p.prefs.getString('sortOrder') ?? 'asc', p.prefs.getString('sortBy') ?? 'title'),
      builder: (context, values, child) {
        var (sortOrder, sortBy) = values;
        return SortMenu(
          sortOrder: StringUtils.parseOrder(sortOrder),
          sortBy: StringUtils.parseSortBy(sortBy),
          setState: (by, order) {
            setState(() {
              // sortBy = by;
              // sortOrder = order;
            });
          },
        );
      },
    );
  }

  Widget _groupMenu() {
    return Selector<AppPreferences, String>(
      selector: (p0, p) => p.prefs.getString('groupBy') ?? 'day',
      builder: (context, groupBy, child) {
        return GroupMenu(
          groupBy: StringUtils.parseGroupBy(groupBy),
          setState: (by) {
            setState(() {
              // sortBy = by;
              // sortOrder = order;
            });
          },
        );
      },
    );
  }

  Future<bool> isValidImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      await codec.getNextFrame();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadMedia() async {
    List<dynamic> loadedImages = [];

    if (Platform.isAndroid) {
      loadedImages = await loadAndroidImages();
    } else if (Platform.isWindows || Platform.isLinux) {
      loadedImages = await loadDesktopImages();
    }

    if (!mounted) return;

    setState(() {
      images = loadedImages;
    });
  }

  Future<List<AssetEntity>> loadAndroidImages() async {
    final PermissionState permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      return [];
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image);

    final List<AssetEntity> images = [];

    for (final album in paths) {
      final assets = await album.getAssetListPaged(page: 0, size: await album.assetCountAsync);

      images.addAll(assets);
    }

    return images;
  }

  Future<List<File>> loadDesktopImages() async {
    final picturesDir = await getPicturesFolder();

    if (picturesDir == null || !await picturesDir.exists()) {
      return [];
    }

    const supportedExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'};

    final List<File> images = [];

    await for (final entity in picturesDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();

        if (supportedExtensions.contains(ext)) {
          images.add(entity);
        }
      }
    }

    return images;
  }

  Future<Directory?> getPicturesFolder() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return null;
      return Directory('$userProfile\\Pictures');
    }

    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home == null) return null;
      return Directory('$home/Pictures');
    }

    return null;
  }
}
