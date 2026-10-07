import 'dart:typed_data';

class ImageFile {
  final String name;
  final String path;
  final Uint8List bytes;

  ImageFile({required this.name, required this.path, required this.bytes});
}
