import 'package:flutter/material.dart';
import 'package:kollection/app/models/album_model.dart';
import 'package:kollection/app/shell/app_shell.dart';
import 'package:kollection/app/widgets/image_list.dart';

class AlbumPage extends StatefulWidget {
  final Album album;
  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: widget.album.title,
      body: ImageList(images: widget.album.images),
    );
  }
}
