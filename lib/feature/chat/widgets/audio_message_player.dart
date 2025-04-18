import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:message_app/common/models/message_model.dart';

class AudioMessagePlayer extends StatefulWidget {
  final MessageModel message;

  const AudioMessagePlayer({super.key, required this.message});

  @override
  _AudioMessagePlayerState createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
          // Reset the play/pause button and position when audio completes
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
        // If the audio has completed, seek to the beginning before playing
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
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
            offset: Offset(0, 3),
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
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
