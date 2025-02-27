import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Join extends StatefulWidget {
  const Join({super.key});

  @override
  State<Join> createState() => _JoinState();
}

class _JoinState extends State<Join> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://live.api.video/li7Zeq44iqnGr5dzJe3BE4Hq.m3u8'),
    );

    _videoController
        .initialize()
        .then((_) {
          setState(() {
            _isInitialized = true;
          });
          _videoController.play();
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
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body:
          _isInitialized && _videoController.value.size.width > 0
              ? SizedBox(
                width: _videoController.value.size.width * 0.5,
                height: _videoController.value.size.height * 0.5,
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
