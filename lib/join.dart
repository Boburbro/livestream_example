import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Join extends StatefulWidget {
  const Join({super.key});

  @override
  State<Join> createState() => _JoinState();
}

class _JoinState extends State<Join> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://82.148.1.150:1935/live/bozormedia/playlist.m3u8'),
    );

    _videoController
        .initialize()
        .then((_) {
          setState(() {
            _isInitialized = true;
          });
          _chewieController = ChewieController(
            videoPlayerController: _videoController,
            autoPlay: true,
            looping: false,
            showControls: true,
          );
          debugPrint("Stream is playing");
        })
        .catchError((error) {
          debugPrint("Video Player Error: $error");
        });

    _videoController.addListener(() {
      if (_videoController.value.hasError) {
        debugPrint("Video Error: ${_videoController.value.errorDescription}");
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.pause();
    _videoController.dispose();
    _chewieController?.pause();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:
          _isInitialized && _videoController.value.size.width > 0
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
