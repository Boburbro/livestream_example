import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadVideo extends StatefulWidget {
  const UploadVideo({super.key});

  @override
  State<UploadVideo> createState() => _UploadVideoState();
}

class _UploadVideoState extends State<UploadVideo> {
  bool _isStreaming = false;
  ApiVideoLiveStreamController? _controller;
  bool _isControllerInitialized = false;
  bool _isFrontCamera = true;

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      print('Kamera yoki mikrofon ruxsati berilmadi');
    }
  }

  Future<void> _initializeController() async {
    try {
      _controller = ApiVideoLiveStreamController(
        initialAudioConfig: AudioConfig(),
        initialVideoConfig: VideoConfig(
          bitrate: 1000000,
          fps: 30,
          resolution: Resolution.RESOLUTION_720,
        ),
        onConnectionSuccess: () {
          setState(() {
            _isStreaming = true;
          });
          print('Ulanish muvaffaqiyatli');
        },
        onConnectionFailed: (error) {
          setState(() {
            _isStreaming = false;
          });
          print('Ulanish xatosi: $error');
        },
        onError: (error) {
          print('Xato: $error');
        },
      );
      await _controller!.initialize();
      setState(() {
        _isControllerInitialized = true;
      });
    } catch (e) {
      print('Kontrolerni boshlashda xato: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) => _initializeController());
  }

  @override
  void dispose() {
    _controller?.stopStreaming();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleStreaming() async {
    if (_controller == null || !_isControllerInitialized) {
      print('Kontroler hali tayyor emas');
      return;
    }

    try {
      if (_isStreaming) {
        await _controller!.stopStreaming();
        setState(() {
          _isStreaming = false;
        });
      } else {
        await _controller!.startStreaming(
          streamKey: "ae393511-7deb-4c83-ac86-8acdf9097e10",
          url: "rtmp://broadcast.api.video:1935/s",
        );
      }
    } catch (e) {
      setState(() {
        _isStreaming = false;
      });
      print('Efirni boshlash/yakunlashda xato: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_controller == null || !_isControllerInitialized) {
      print('Kontroler hali tayyor emas');
      return;
    }

    try {
      await _controller!.switchCamera();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
      print('Kamera almashtirildi: ${_isFrontCamera ? "Oldi" : "Orqa"}');
    } catch (e) {
      print('Kamerani almashtirishda xato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Stream App')),
      body: Stack(
        children: [
          if (_isControllerInitialized && _controller != null)
            ApiVideoCameraPreview(controller: _controller!)
          else
            const SizedBox(
              height: 400,
              width: 400,
              child: Center(child: CircularProgressIndicator()),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _toggleStreaming,
                      child: Text(
                        _isStreaming ? 'Stop Streaming' : 'Start Streaming',
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _switchCamera,
                      child: Text(
                        _isFrontCamera ? 'Switch to Rear' : 'Switch to Front',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
