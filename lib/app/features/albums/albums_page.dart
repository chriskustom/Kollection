import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kollection/app/features/albums/album_page.dart';
import 'package:kollection/app/models/album_model.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/services/app_services.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:kollection/app/widgets/animated_fab.dart';
import 'package:kollection/app/widgets/app_snack_bar.dart';
import 'package:kollection/app/widgets/menus/sort_menu.dart';
import 'package:kollection/app/widgets/menus/triple_dot_menu.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<Album> albums = [];
  final ScrollController scroll = ScrollController();
  SortBy _sortBy = SortBy.title;
  SortOrder _sortOrder = SortOrder.asc;
  bool showHidden = false;
  @override
  void initState() {
    loadMedia();
    super.initState();
  }

  void _sortAlbums() {
    albums = albums.where((a) => showHidden || !a.title.startsWith('.')).toList()
      ..sort((a, b) {
        int result;

        if (_sortBy == SortBy.title) {
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        } else {
          final dateA = _getAlbumDate(a);
          final dateB = _getAlbumDate(b);
          result = dateA.compareTo(dateB);
        }

        return _sortOrder == SortOrder.asc ? result : -result;
      });
  }

  DateTime _getAlbumDate(Album album) {
    if (album.images.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final dates = album.images.map(_getImageDate).toList();

    if (_sortOrder == SortOrder.desc) {
      // Newest image in the album.
      return dates.reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Oldest image in the album.
    return dates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime _getImageDate(dynamic image) {
    if (image is AssetEntity) {
      return image.createDateTime;
    }

    if (image is File) {
      return image.lastModifiedSync();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Icon _buildCheckbox(bool? state) {
    if (state == true) {
      return const Icon(Icons.check_box, color: Colors.blueAccent);
    } else {
      return const Icon(Icons.check_box_outline_blank, color: Colors.blueGrey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppPreferences, (String, String)>(
      selector: (p0, p) => (p.prefs.getString('albums_sortOrder') ?? 'asc', p.prefs.getString('albums_sortBy') ?? 'title'),
      builder: (context, values, child) {
        var (sortOrder, sortBy) = values;

        _sortBy = StringUtils.parseSortBy(sortBy);
        _sortOrder = StringUtils.parseOrder(sortOrder);
        _sortAlbums();
        return AppShell(
          title: 'Albums',
          actions: [
            MenuItem(
              title: 'Show Hidden',
              icon: _buildCheckbox(showHidden),
              onTap: () {
                setState(() {
                  showHidden = !showHidden;
                  loadMedia();
                });
              },
            ),
          ],
          sorting: _sortMenu(),
          body: GridView.builder(
            controller: scroll,
            shrinkWrap: true,
            itemCount: albums.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 1, childAspectRatio: 1),
            itemBuilder: (context, index) {
              final album = albums[index];

              return FutureBuilder<Uint8List>(
                future: _getBytes(album.images.firstOrNull),
                builder: (context, snapshot) {
                  final bytes = snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data! : Uint8List(0);

                  return Padding(
                    padding: .all(6),
                    child: InkWell(
                      onTap: () async {
                        await _openAlbum(album);
                      },
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: bytes.isNotEmpty
                              ? DecorationImage(
                                  image: MemoryImage(bytes),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Color.fromARGB(50, 0, 0, 0), BlendMode.darken),
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            bytes.isEmpty ? Center(child: Icon(Icons.image, size: 48, color: Colors.grey)) : SizedBox.shrink(),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: .spaceBetween,
                                  mainAxisSize: .min,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        album.title,
                                        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Text(
                                      '${album.images.length}',
                                      style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: AnimatedFab(
            onPressed: () async {
              await _createAlbum();
            },
            label: Text('New'),
            icon: Icon(Icons.add),
            scroll: scroll,
          ),
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
    List<Album> albums = [];

    if (Platform.isAndroid) {
      albums = await loadAndroidAlbums();
    } else if (Platform.isWindows || Platform.isLinux) {
      albums = await loadDesktopAlbums();
    }

    if (!mounted) return;

    this.albums = albums;
    _sortAlbums();

    setState(() {});
  }

  Future<List<Album>> loadAndroidAlbums() async {
    final List<Album> albums = [];

    final PermissionState permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) return albums;

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image, hasAll: true);

    for (final path in paths) {
      final assets = await path.getAssetListPaged(page: 0, size: await path.assetCountAsync);

      albums.add(
        Album(
          title: path.name,
          path: path.id,
          images: assets, // These are AssetEntity objects
        ),
      );
    }

    return albums;
  }

  Future<List<Album>> loadDesktopAlbums() async {
    final List<Album> albums = [];

    final picturesDir = await getPicturesFolder();
    if (picturesDir == null || !await picturesDir.exists()) {
      return albums;
    }

    const supportedExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'};

    final Map<String, List<File>> albumMap = {};

    // Add the Pictures directory itself.
    albumMap[picturesDir.path] = [];

    // Discover every directory, including empty directories.
    await for (final entity in picturesDir.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        albumMap.putIfAbsent(entity.path, () => []);
      } else if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();

        if (supportedExtensions.contains(ext)) {
          final parentDir = path.dirname(entity.path);
          albumMap.putIfAbsent(parentDir, () => []);
          albumMap[parentDir]!.add(entity);
        }
      }
    }

    for (final entry in albumMap.entries) {
      albums.add(
        Album(
          title: entry.key == picturesDir.path ? path.basename(picturesDir.path) : path.basename(entry.key),
          path: entry.key,
          images: entry.value,
        ),
      );
    }

    return albums;
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

  Future<Uint8List> _getBytes(Object? image) async {
    if (image is File) {
      return await image.readAsBytes();
    }

    if (image is AssetEntity) {
      return await image.getOriginBytes() ?? Uint8List(0);
    }

    return Uint8List(0);
  }

  Widget _sortMenu() {
    return Selector<AppPreferences, (String, String)>(
      selector: (p0, p) => (p.prefs.getString('albums_sortOrder') ?? 'asc', p.prefs.getString('albums_sortBy') ?? 'title'),
      builder: (context, values, child) {
        var (sortOrder, sortBy) = values;
        return SortMenu(
          route: .albums,
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

  Future<void> _createAlbum() async {
    var folderName = await showInputDialog(null);
    if (folderName != null) {
      final Directory? externalDir = await getPicturesFolder();
      if (externalDir != null) {
        final Directory newDir = Directory('${externalDir.path}/$folderName');
        if (!await newDir.exists()) {
          await newDir.create(recursive: true);
          var album = Album(title: folderName, images: [], path: newDir.path);
          loadMedia();
          await _openAlbum(album);
        } else {
          AppSnackBar.error('Folder already exists!');
        }
      }
    }
  }

  Future<String?> showInputDialog(String? folderName) async {
    bool isEdit = folderName != null;
    final TextEditingController controller = TextEditingController(text: isEdit ? folderName : '');
    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('New album name'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: 'Name...'),
              ),
              actions: [
                TextButton(onPressed: AppHaptics.selectWithHaptics(context, () => Navigator.pop(context)), child: Text('Cancel')),
                ElevatedButton(
                  onPressed: AppHaptics.selectWithHaptics(context, () {
                    Navigator.pop(context, controller.text);
                  }),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAlbum(Album album) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "Right Sheet",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              child: AlbumPage(album: album /*  */),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
