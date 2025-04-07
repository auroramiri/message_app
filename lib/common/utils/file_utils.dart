import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<String?> generateThumbnailFileFromUrl(String videoUrl) async {
  final tempDir = await getTemporaryDirectory();
  final uniqueFileName = 'thumbnail_${Random().nextInt(1000000)}.webp';
  final thumbnailPath = '${tempDir.path}/$uniqueFileName';

  try {
    final thumbnailFile = await VideoThumbnail.thumbnailFile(
      video: videoUrl,
      thumbnailPath: thumbnailPath,
      imageFormat: ImageFormat.WEBP,
      maxHeight: 512,
      quality: 100,
      timeMs: 2000,
    );
    return thumbnailFile;
  } catch (e) {
    return null;
  }
}

String getFileExtension(String fileName) {
  try {
    return ".${fileName.split('.').last}";
  } catch (e) {
    return '';
  }
}

String getFileNameWithoutExtension(String fileName) {
  try {
    return fileName.split('.').first;
  } catch (e) {
    return fileName;
  }
}

String formatFileSize(double bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

Future<void> saveFile(
  BuildContext context,
  String fileUrl,
  String fileName,
) async {
  String message;
  try {
    final dio = Dio();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';

    await dio.download(fileUrl, filePath);

    final params = SaveFileDialogParams(sourceFilePath: filePath);
    final finalPath = await FlutterFileDialog.saveFile(params: params);

    message = finalPath != null ? 'File saved to disk' : 'Download cancelled';
  } catch (e) {
    developer.log('Error saving file: $e');
    message = e.toString();
  }

  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
