import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('Initializing video player with URL: ${widget.videoUrl}');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Добавляем настройки для улучшения совместимости
      _controller.setVolume(1.0);
      _controller.setLooping(false);

      // Add listener for initialization errors
      _controller.addListener(() {
        if (_controller.value.hasError && mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                _controller.value.errorDescription ?? 'Unknown error';
          });
          debugPrint('Video player error: $_errorMessage');
        }
      });

      // Initialize the controller
      await _controller
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _isPlaying = true;
                _controller.play();
              });
            }
          })
          .catchError((error) {
            debugPrint('Error initializing video: $error');
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.toString();
              });
            }
          });
    } catch (e) {
      debugPrint('Exception during video initialization: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  var random = Random();
  Future<void> _saveVideo() async {
    late String message;
    try {
      final Response response = await get(Uri.parse(widget.videoUrl));
      final dir = await getTemporaryDirectory();

      var filename = '${dir.path}/SaveVideo${random.nextInt(100)}.mp4';

      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Video', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          // Основной контент (видео)
          Center(
            child:
                _hasError
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Failed to load video:\n$_errorMessage',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _errorMessage = '';
                            });
                            _initializePlayer();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                    : !_isInitialized
                    ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading video...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )
                    : GestureDetector(
                      onTap: _toggleControls,
                      behavior: HitTestBehavior.opaque,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
          ),

          // Элементы управления внизу экрана (поверх видео)
          if (_isInitialized && !_hasError)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Прогресс-бар
                        ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, value, child) {
                            final position = value.position;
                            final duration = value.duration;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: position.inMilliseconds.toDouble(),
                                      min: 0.0,
                                      max: duration.inMilliseconds.toDouble(),
                                      onChanged: (value) {
                                        _controller.seekTo(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      },
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Кнопки управления
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Регулятор громкости
                              Row(
                                children: [
                                  const Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Slider(
                                      value: _volume,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (value) {
                                        setState(() {
                                          _volume = value;
                                          _controller.setVolume(_volume);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // Кнопка воспроизведения/паузы
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _togglePlayPause,
                              ),

                              // Кнопка полноэкранного режима
                              IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  _saveVideo();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }
}
