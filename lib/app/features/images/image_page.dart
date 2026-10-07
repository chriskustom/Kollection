import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kollection/db/models/features/image_model.dart';
import 'package:path/path.dart' as path;

class ImagePage extends StatefulWidget {
  final ImageFile image;

  const ImagePage({super.key, required this.image});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  static const double _minScale = 0.1;
  static const double _maxScale = 5.0;

  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _reset() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomAt(Offset localPosition, double factor) {
    final matrix = _transformationController.value;

    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(_minScale, _maxScale);

    final scaleFactor = newScale / currentScale;

    final translationToPointer = Matrix4.translationValues(localPosition.dx, localPosition.dy, 0);

    final translationFromPointer = Matrix4.translationValues(-localPosition.dx, -localPosition.dy, 0);

    final scaleMatrix = Matrix4.diagonal3Values(scaleFactor, scaleFactor, 1);

    _transformationController.value = translationToPointer * scaleMatrix * translationFromPointer * matrix;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    final delta = event.scrollDelta.dy;

    if (delta == 0) {
      return;
    }

    final factor = delta > 0 ? 0.9 : 1.1;

    _zoomAt(event.localPosition, factor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(path.basenameWithoutExtension(widget.image.name)),
        actions: [IconButton(tooltip: 'Reset', onPressed: _reset, icon: const Icon(Icons.refresh))],
      ),
      body: Listener(
        onPointerSignal: _handlePointerSignal,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: _minScale,
          maxScale: _maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          panEnabled: true,
          scaleEnabled: true,
          clipBehavior: Clip.none,
          constrained: true,
          child: Center(
            child: Image.memory(widget.image.bytes, fit: BoxFit.contain, filterQuality: FilterQuality.high),
          ),
        ),
      ),
    );
  }
}
