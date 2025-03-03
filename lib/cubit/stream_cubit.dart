import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtmp_broadcaster/camera.dart';

part 'stream_state.dart';

class UploadVideoCubit extends Cubit<UploadVideoState> {
  CameraController? _controller;
  CameraController? get controller => _controller;

  UploadVideoCubit() : super(UploadVideoState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    emit(state.copyWith(isLoading: true));
    await _requestPermissions();
    await _initializeController();
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _requestPermissions() async {
    print('_requestPermissions');
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      emit(
        state.copyWith(errorMessage: 'Camera or microphone permission denied'),
      );
    }
  }

  Future<void> _initializeController() async {
    print("_initializeController");
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );
      try {
        await _controller!.initialize();
        emit(state.copyWith(isControllerInitialized: true));
      } catch (e) {
        emit(state.copyWith(errorMessage: 'Camera initialization failed: $e'));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isControllerInitialized: false,
          errorMessage: 'Failed to initialize camera: $e',
        ),
      );
    }
  }

  Future<void> toggleStreaming() async {
    if (_controller == null || !state.isControllerInitialized) {
      emit(state.copyWith(errorMessage: 'Camera controller is not ready'));
      return;
    }
    try {
      if (state.isStreaming) {
        await _controller!.stopVideoStreaming();
        emit(state.copyWith(isStreaming: false));
      } else {
        emit(state.copyWith(isLoading: true));
        await _controller!
            .startVideoStreaming("rtmp://82.148.1.150:1935/live/bozormedia")
            .catchError((e) {
              print("ERRORR: $e");
            });
        emit(state.copyWith(isStreaming: true, isLoading: false));
      }
    } catch (e) {
      if (e.toString().contains("403")) {
        emit(
          state.copyWith(
            isStreaming: false,
            isLoading: false,
            errorMessage: 'Cannot connect to server: Authentication required.',
          ),
        );
      } else if (e.toString().contains("failed")) {
        emit(
          state.copyWith(
            isStreaming: false,
            isLoading: false,
            errorMessage:
                'Cannot connect to server: Check your internet or server URL.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isStreaming: false,
            isLoading: false,
            errorMessage: 'Failed to start/stop streaming: $e',
          ),
        );
      }
    }
  }

  Future<void> switchCamera() async {
    if (_controller == null || !state.isControllerInitialized) {
      emit(state.copyWith(errorMessage: 'Camera controller is not ready'));
      return;
    }

    try {
      final cameras = await availableCameras();
      final newCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection != _controller!.description.lensDirection,
      );
      await _controller!.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();
      emit(state.copyWith(isFrontCamera: !state.isFrontCamera));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to switch camera: $e'));
    }
  }

  void setNullErrorMessage() => emit(state.copyWith(errorMessage: null));

  @override
  Future<void> close() {
    _controller?.stopVideoStreaming();
    _controller?.dispose();
    return super.close();
  }
}
