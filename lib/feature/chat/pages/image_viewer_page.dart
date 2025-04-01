import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerPage extends StatefulWidget {
  final String imageUrl;

  const ImageViewerPage({super.key, required this.imageUrl});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  bool _isToolbarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isToolbarVisible = !_isToolbarVisible;
          });
        },
        onVerticalDragEnd: (details) {
          // If the user swipes up with enough velocity, close the viewer
          if (details.velocity.pixelsPerSecond.dy < -300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            // Photo view widget for zooming and panning
            PhotoView(
              imageProvider: CachedNetworkImageProvider(widget.imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
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
              // Enable rotation
              customSize: MediaQuery.of(context).size,
              enableRotation: true,
            ),

            // Top toolbar with close button
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
                        'Image Viewer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the layout
                    ],
                  ),
                ),
              ),
            ),

            // Bottom toolbar with actions
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _isToolbarVisible ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                color: Colors.black.withValues(alpha: 0.4),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.save_alt,
                        label: 'Save',
                        onTap: _saveImage,
                      ),
                      _buildActionButton(
                        icon: Icons.content_copy,
                        label: 'Copy URL',
                        onTap: () => _copyImageUrl(context),
                      ),
                      _buildActionButton(
                        icon: Icons.info_outline,
                        label: 'Info',
                        onTap: () => _showImageInfo(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Swipe up indicator
            AnimatedOpacity(
              opacity: _isToolbarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                bottom: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Swipe up to close',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoading
              ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  var random = Random();
  Future<void> _saveImage() async {
    late String message;
    try {
      // Download image
      final Response response = await get(Uri.parse(widget.imageUrl));

      // Get temporary directory
      final dir = await getTemporaryDirectory();

      // Create an image name
      var filename = '${dir.path}/SaveImage${random.nextInt(100)}.png';

      // Save to filesystem
      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

      // Ask the user to save it
      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Image saved to disk';
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

  void _copyImageUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.imageUrl));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image URL copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
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
                  'Image Information',
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
                      return const Text(
                        'Loading image details...',
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text(
                        'Could not load image details',
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    final size = snapshot.data as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Size: ${size['width']} x ${size['height']} px',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'File size: ${(size['fileSize'] / 1024).toStringAsFixed(2)} KB',
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
                    child: const Text(
                      'Close',
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
