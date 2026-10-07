import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kollection/app/features/images/image_page.dart';
import 'package:kollection/app/models/image_file_model.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';

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
      body: GridView.builder(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final image = images[index];

          return FutureBuilder<Uint8List>(
            future: _getBytes(image),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(color: Colors.grey);
              }
              return Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  onTap: () async {
                    final imageFile = await _toImageFile(image);
                    if (!context.mounted) return;
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
                              child: ImagePage(image: imageFile),
                            ),
                          ),
                        );
                      },
                      transitionBuilder: (context, anim1, anim2, child) {
                        final offsetAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1);
                        return SlideTransition(position: offsetAnimation, child: child);
                      },
                    );
                  },
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
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

  Future<ImageFile> _toImageFile(Object image) async {
    if (image is File) {
      return ImageFile(name: path.basename(image.path), path: image.path, bytes: await image.readAsBytes());
    }

    if (image is AssetEntity) {
      final bytes = await image.getOriginBytes();

      return ImageFile(name: image.title ?? 'Image', path: image.id, bytes: bytes ?? Uint8List(0));
    }

    throw UnsupportedError('Unsupported image type: ${image.runtimeType}');
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

  Future<Uint8List> _getBytes(dynamic image) async {
    if (image is File) {
      return await image.readAsBytes();
    }

    if (image is AssetEntity) {
      final bytes = await image.getOriginBytes();
      return bytes ?? Uint8List(0);
    }

    return Uint8List(0);
  }
}
