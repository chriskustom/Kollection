import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kollection/app/features/images/image_page.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:kollection/db/models/features/album_model.dart';
import 'package:kollection/db/models/features/image_model.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:platform_detail/platform_detail.dart';

class AlbumPage extends StatefulWidget {
  final Album album;
  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.album.title)),
      body: GridView.builder(
        shrinkWrap: true,
        physics: ScrollPhysics(),
        itemCount: widget.album.images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 1, childAspectRatio: 1),
        itemBuilder: (context, index) {
          final images = widget.album.images;
          final file = images[index];
          return FutureBuilder<Uint8List>(
            future: _getBytes(file),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(color: Colors.grey); // placeholder
              }
              final fileName = file is AssetEntity
                  ? file.title!
                  : file is File
                  ? path.basename(file.path)
                  : ''; //TODO
              final image = ImageFile(name: fileName, path: widget.album.path, bytes: snapshot.data!);
              return Padding(
                padding: .all(2),
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
                              child: ImagePage(image: image),
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
                    clipBehavior: .antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
                    ),
                    child: Align(
                      alignment: AlignmentGeometry.bottomRight,
                      child: Padding(
                        padding: .only(left: 8, right: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Text(
                              fileName.truncate(10),
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                            Icon(Icons.image, color: Colors.white),
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

      floatingActionButton: FloatingActionButton(onPressed: () {}, tooltip: 'Increment', child: const Icon(Icons.add)),
    );
  }

  Future<Uint8List> _getBytes(dynamic image) async {
    if (PlatformDetail.isDesktop) {
      final File file = image;
      return await file.readAsBytes();
    }
    if (Platform.isAndroid) {
      final AssetEntity asset = image as AssetEntity;
      final bytes = await asset.getOriginBytes();
      return bytes ?? Uint8List(0);
    }

    return Uint8List(0);
  }
}
