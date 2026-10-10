import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kollection/app/features/images/image_page.dart';
import 'package:kollection/app/models/image_file_model.dart';
import 'package:kollection/app/services/app_preferences.dart';
import 'package:kollection/app/utils/constants.dart';
import 'package:kollection/app/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:platform_detail/platform_detail.dart';
import 'package:provider/provider.dart';

class ImageList extends StatefulWidget {
  final List<dynamic> images;
  const ImageList({super.key, required this.images});

  @override
  State<ImageList> createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  int _crossAxisCount = 3;
  double _scale = 1.0;

  SortBy _sortBy = SortBy.date;
  SortOrder _sortOrder = SortOrder.desc;
  GroupBy _groupBy = GroupBy.day;

  List<dynamic> _sortedImages = [];

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
  }

  @override
  void didUpdateWidget(covariant ImageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.images != widget.images) {
      _sortImages();
    }
  }

  Future<void> _loadSortPreferences() async {
    final prefs = context.read<AppPreferences>();

    if (!mounted) return;

    setState(() {
      _sortBy = StringUtils.parseSortBy(prefs.prefs.getString('gallery_sortBy'));
      _sortOrder = StringUtils.parseOrder(prefs.prefs.getString('gallery_sortOrder'));
      _groupBy = StringUtils.parseGroupBy(prefs.prefs.getString('groupBy'));

      _sortImages();
    });
  }

  void _sortImages() {
    final images = List<dynamic>.from(widget.images);

    images.sort((a, b) {
      int result;

      if (_sortBy == SortBy.title) {
        final titleA = _getFileName(a).toLowerCase();
        final titleB = _getFileName(b).toLowerCase();

        result = titleA.compareTo(titleB);
      } else {
        final dateA = _getDate(a);
        final dateB = _getDate(b);

        result = dateA.compareTo(dateB);
      }

      return _sortOrder == SortOrder.asc ? result : -result;
    });

    _sortedImages = images;
  }

  String _getFileName(dynamic image) {
    if (image is AssetEntity) {
      return image.title ?? '';
    }

    if (image is File) {
      return path.basename(image.path);
    }

    return '';
  }

  DateTime _getDate(dynamic image) {
    if (image is AssetEntity) {
      return image.createDateTime;
    }

    if (image is File) {
      // Desktop fallback: filesystem modification date.
      return image.lastModifiedSync();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, List<dynamic>> _groupImages() {
    final groups = <String, List<dynamic>>{};

    for (final image in _sortedImages) {
      final date = _getDate(image);
      final key = _groupKey(date);

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(image);
    }

    return groups;
  }

  String _groupKey(DateTime date) {
    if (_groupBy == GroupBy.day) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _groupTitle(String key) {
    final parts = key.split('-');

    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    if (_groupBy == GroupBy.month) {
      final date = DateTime(year, month);

      return '${_monthName(date.month)} ${date.year}';
    }

    final day = int.parse(parts[2]);
    final date = DateTime(year, month, day);

    return _formatDay(date);
  }

  String _formatDay(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final imageDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(imageDay).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return '${_weekdayName(date.weekday)}, '
        '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return months[month - 1];
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return weekdays[weekday - 1];
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _scale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    _scale = details.scale;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_scale > 1.1) {
      // Pinch in -> fewer columns.
      setState(() {
        _crossAxisCount = (_crossAxisCount - 1).clamp(1, 6);
      });
    } else if (_scale < 0.9) {
      // Pinch out -> more columns.
      setState(() {
        _crossAxisCount = (_crossAxisCount + 1).clamp(1, 6);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppPreferences, (String, String, String)>(
      selector: (p0, p) =>
          (p.prefs.getString('gallery_sortOrder') ?? 'asc', p.prefs.getString('gallery_sortBy') ?? 'title', p.prefs.getString('groupBy') ?? 'day'),
      builder: (context, values, child) {
        var (sortOrder, sortBy, groupBy) = values;

        _sortBy = StringUtils.parseSortBy(sortBy);
        _sortOrder = StringUtils.parseOrder(sortOrder);
        _groupBy = StringUtils.parseGroupBy(groupBy);
        _sortImages();

        if (_sortedImages.isEmpty) {
          return const SizedBox.shrink();
        }
        final groups = _groupImages();
        return GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: CustomScrollView(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            slivers: [
              for (final entry in groups.entries) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(_groupTitle(entry.key), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),

                SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildImage(context, entry.value[index]);
                  }, childCount: entry.value.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 1,
                    childAspectRatio: 1,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context, dynamic file) {
    return FutureBuilder<Uint8List>(
      future: _getBytes(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Colors.grey);
        }

        final fileName = _getFileName(file);

        final filePath = file is File ? file.path : '';

        final image = ImageFile(name: fileName, path: filePath, bytes: snapshot.data!);

        return Padding(
          padding: const EdgeInsets.all(6),
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.image, color: Colors.white, size: 15),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
