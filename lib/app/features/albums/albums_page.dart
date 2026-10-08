import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kollection/app/features/albums/album_page.dart';
import 'package:kollection/app/models/album_model.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<StatefulWidget> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<Album> albumImages = [];

  @override
  void initState() {
    loadMedia();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Albums',
      body: GridView.builder(
        shrinkWrap: true,
        physics: ScrollPhysics(),
        itemCount: albumImages.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final album = albumImages[index];

          return FutureBuilder<Uint8List>(
            future: _getBytes(album.images.first),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(color: Colors.grey);
              }
              final bytes = snapshot.data!;

              return Padding(
                padding: .all(6),
                child: InkWell(
                  onTap: () {
                    showGeneralDialog(
                      context: context,
                      barrierLabel: "Right Sheet",
                      barrierDismissible: true,
                      barrierColor: Colors.black54,
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, anim1, anim2) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Material(
                            color: Colors.white,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: double.infinity,
                              child: AlbumPage(album: album /*  */),
                            ),
                          ),
                        );
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(anim1);
                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                    );
                  },
                  child: Container(
                    clipBehavior: .antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: MemoryImage(bytes),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Color.fromARGB(50, 0, 0, 0), BlendMode.darken),
                      ),
                    ),
                    child: Align(
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
                  ),
                ),
              );
            },
          );
        },
      ),
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

    setState(() {
      albumImages = albums;
    });
  }

  Future<List<Album>> loadAndroidAlbums() async {
    final List<Album> albums = [];

    final PermissionState permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) return albums;

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(type: RequestType.image);

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

    await for (final entity in picturesDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (supportedExtensions.contains(ext)) {
          final parentDir = path.dirname(entity.path);
          albumMap.putIfAbsent(parentDir, () => []);
          albumMap[parentDir]!.add(entity);
        }
      }
    }

    albumMap.forEach((dirPath, files) {
      albums.add(Album(title: path.basename(dirPath), path: dirPath, images: files));
    });

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

  Future<Uint8List> _getBytes(Object image) async {
    if (image is File) {
      return await image.readAsBytes();
    }

    if (image is AssetEntity) {
      return await image.getOriginBytes() ?? Uint8List(0);
    }

    return Uint8List(0);
  }
}
