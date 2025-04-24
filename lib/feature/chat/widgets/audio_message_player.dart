import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:message_app/common/models/message_model.dart';
import 'package:message_app/feature/chat/widgets/config.dart';

class AudioMessagePlayer extends StatefulWidget {
  final MessageModel message;

  const AudioMessagePlayer({super.key, required this.message});

  @override
  AudioMessagePlayerState createState() => AudioMessagePlayerState();
}

class AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _prepareAudio();
    _initAudioPlayerListeners();
  }

  Future<void> _prepareAudio() async {
    if (widget.message.fileUrl != null) {
      await _audioPlayer.setUrl(widget.message.fileUrl!);
    }
  }

  void _initAudioPlayerListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        if (playerState.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        } else {
          setState(() {
            _isPlaying = playerState.playing;
          });
        }
      }
    });
  }

  void playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    }
  }

  Future<void> _transcribeAudio() async {
    final apiKey = Config.deepgramApiKey;

    final url = Uri.parse('https://api.deepgram.com/v1/listen');
    final requestBody = {'url': widget.message.fileUrl};

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _transcript =
              data['results']['channels'][0]['alternatives'][0]['transcript'];
        });
      } else {
        log('Transcription failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      log('Exception occurred: $e');
    }
  }

  void transcribeSpeechToText() {
    if (widget.message.fileUrl != null) {
      _transcribeAudio();
    } else {
      log('Audio URL is null. Cannot transcribe.');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value:
                _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                    key: ValueKey<bool>(_isPlaying),
                  ),
                ),
                onPressed: playPauseAudio,
              ),
              IconButton(
                icon: Icon(Icons.subtitles, color: Colors.white, size: 28),
                onPressed: transcribeSpeechToText,
              ),
              Text(
                _formatDuration(_position.inSeconds),
                style: TextStyle(color: Colors.grey[300], fontSize: 12),
              ),
              Text(
                _formatDuration(_duration.inSeconds),
                style: TextStyle(color: Colors.grey[300], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_transcript.isNotEmpty)
            Text(
              _transcript,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
