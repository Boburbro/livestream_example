import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'utils/app_logger.dart';
import 'package:video_player/video_player.dart';

class Join extends StatefulWidget {
  const Join({super.key});

  @override
  State<Join> createState() => _JoinState();
}

class _JoinState extends State<Join> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(AppConstants.m3u8),
    );

    try {
      await _videoController.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        isLive: true,
        zoomAndPan: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Video Playback Error: $errorMessage',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );

      _videoController.addListener(_videoListener);
      AppLogger.warning('Video player initialized successfully');
    } catch (error) {
      AppLogger.error('Video Player Initialization Error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize video: $error';
      });
    }
  }

  void _videoListener() {
    if (_videoController.value.hasError) {
      final errorDesc =
          _videoController.value.errorDescription ?? 'Unknown error';
      AppLogger.error('Video Playback Error: $errorDesc');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Video Playback Error: $errorDesc';
      });
    }
    if (_videoController.value.isPlaying && _errorMessage != null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.pause();
    _chewieController?.pause();
    _chewieController?.dispose();
    _videoController.dispose();
    AppLogger.warning('Join screen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Stream')),
      body: Column(
        children: [
          Expanded(child: _buildVideoPlayer()),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isInitialized = false;
                });
                _initializeVideoPlayer();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_errorMessage != null) {
      return const Center(
        child: Text(
          'Error occurred while loading video',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    if (!_isInitialized || _videoController.value.size.width <= 0) {
      return const Center(child: CircularProgressIndicator());
    }

    return Chewie(controller: _chewieController!);
  }
}
