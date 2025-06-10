import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:http/http.dart';
import 'package:message_app/feature/chat/widgets/build_image_action_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerPage extends StatefulWidget {
  final String imageUrl;
  final List<String>? allImages;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.imageUrl,
    this.allImages,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  bool _isToolbarVisible = true;
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMultipleImages =
        widget.allImages != null && widget.allImages!.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isToolbarVisible = !_isToolbarVisible;
          });
        },
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy < -300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            hasMultipleImages
                ? PageView.builder(
                  controller: _pageController,
                  itemCount: widget.allImages!.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return PhotoView(
                      imageProvider: CachedNetworkImageProvider(
                        widget.allImages![index],
                      ),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      loadingBuilder:
                          (context, event) => Center(
                            child: CircularProgressIndicator(
                              value:
                                  event == null
                                      ? 0
                                      : event.cumulativeBytesLoaded /
                                          (event.expectedTotalBytes ?? 1),
                            ),
                          ),
                      customSize: MediaQuery.of(context).size,
                      enableRotation: true,
                      filterQuality: FilterQuality.high,
                    );
                  },
                )
                : PhotoView(
                  imageProvider: CachedNetworkImageProvider(widget.imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  loadingBuilder:
                      (context, event) => Center(
                        child: CircularProgressIndicator(
                          value:
                              event == null
                                  ? 0
                                  : event.cumulativeBytesLoaded /
                                      (event.expectedTotalBytes ?? 1),
                        ),
                      ),
                  customSize: MediaQuery.of(context).size,
                  enableRotation: true,
                  filterQuality: FilterQuality.high,
                ),
            AnimatedOpacity(
              opacity: _isToolbarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Container(
                  height: 56,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        hasMultipleImages
                            ? '${'image'.tr} ${_currentIndex + 1}/${widget.allImages!.length}'
                            : 'image_viewer'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _isToolbarVisible ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                color: Colors.black.withValues(alpha: 0.4),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: AnimatedOpacity(
                          opacity: _isToolbarVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Positioned(
                            bottom: 90,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                'swipe_up_to_close'.tr,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildActionButton(
                            icon: Icons.save_alt,
                            label: 'save'.tr,
                            onTap: _saveImage,
                          ),
                          buildActionButton(
                            icon: Icons.info_outline,
                            label: 'info'.tr,
                            onTap: () => _showImageInfo(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasMultipleImages && _isToolbarVisible)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    const Spacer(),
                    if (_currentIndex < widget.allImages!.length - 1)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  var random = Random();
  Future<void> _saveImage() async {
    late String message;
    try {
      final Response response = await get(Uri.parse(widget.imageUrl));
      final dir = await getTemporaryDirectory();

      var filename = '${dir.path}/SaveImage${random.nextInt(100)}.png';

      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'image_saved_to_disk'.tr;
      }
    } catch (e) {
      if (mounted) {
        message = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Color(0xFFe91e63),
          ),
        );
      }
    }
  }

  void _showImageInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'image_information.tr',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'URL: ${widget.imageUrl}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: _getImageSize(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'loading_image_details'.tr,
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Text(
                        'could_not_load_image_details'.tr,
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    final size = snapshot.data as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'size'.tr}${size['width']} x ${size['height']} px',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'file_size'}${(size['fileSize'] / 1024).toStringAsFixed(2)} KB',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'close'.tr,
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<Map<String, dynamic>> _getImageSize() async {
    try {
      final response = await get(Uri.parse(widget.imageUrl));
      final imageBytes = response.bodyBytes;

      final image = await decodeImageFromList(imageBytes);

      return {
        'width': image.width,
        'height': image.height,
        'fileSize': imageBytes.length,
      };
    } catch (e) {
      developer.log('Error getting image size: $e');
      return {'width': 'Unknown', 'height': 'Unknown', 'fileSize': 0};
    }
  }
}
