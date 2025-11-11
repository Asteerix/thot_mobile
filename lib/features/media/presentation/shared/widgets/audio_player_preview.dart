import 'package:thot/core/themes/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
class AudioPlayerPreview extends StatefulWidget {
  final File audioFile;
  final double height;
  const AudioPlayerPreview({
    super.key,
    required this.audioFile,
    this.height = 100,
  });
  @override
  State<AudioPlayerPreview> createState() => _AudioPlayerPreviewState();
}
class _AudioPlayerPreviewState extends State<AudioPlayerPreview> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }
  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setFilePath(widget.audioFile.path);
      _duration = _audioPlayer.duration ?? Duration.zero;
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
    } catch (e) {
      print('Error initializing audio player: $e');
    }
  }
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 48,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
              ),
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.white,
                overlayColor: Colors.blue.withOpacity(0.2),
              ),
              child: Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}