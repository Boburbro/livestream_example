import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livestream_example/utils/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtmp_broadcaster/camera.dart';

part 'stream_state.dart';

class UploadVideoCubit extends Cubit<UploadVideoState> {
  CameraController? _controller;
  CameraController? get controller => _controller;

  UploadVideoCubit() : super(const UploadVideoState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    emit(state.copyWith(isLoading: true));
    await _requestPermissions();
    await _initializeController();
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      emit(
        state.copyWith(errorMessage: 'Camera or microphone permission denied'),
      );
    }
  }

  Future<void> _initializeController() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(
          state.copyWith(
            isControllerInitialized: false,
            errorMessage: 'No cameras available',
          ),
        );
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();

      _controller!.addListener(() async {
        if (_controller!.value.hasError) {
          AppLogger.error(
            'Camera error: ${_controller!.value.errorDescription}',
          );
          emit(
            state.copyWith(
              errorMessage:
                  'Camera error: ${_controller!.value.errorDescription}',
              isStreaming: false,
            ),
          );
        } else if (_controller!.value.event != null) {
          final event = _controller!.value.event as Map<dynamic, dynamic>;
          final eventType = event['eventType'] as String?;
          final errorDesc = event['errorDescription'] as String?;
          if (eventType == 'rtmp_retry' &&
              errorDesc == 'Fail to connect, time out') {
            AppLogger.error('Timeout detected, stopping stream...');
            await _controller!.stopVideoStreaming();
            emit(
              state.copyWith(
                isStreaming: false,
                errorMessage:
                    'Connection timed out: Failed to connect to server',
              ),
            );
          } else if (eventType == 'error' &&
              errorDesc?.contains('unauthenticated') == true) {
            AppLogger.error('Unauthenticated error detected');
            emit(
              state.copyWith(
                errorMessage: 'Unauthenticated: Server rejected the stream',
                isStreaming: false,
              ),
            );
          }
        }
      });

      emit(state.copyWith(isControllerInitialized: true));
    } catch (e) {
      AppLogger.error('Failed to initialize camera: $e');
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
      AppLogger.warning('Controller not ready for streaming');
      emit(state.copyWith(errorMessage: 'Camera controller is not ready'));
      return;
    }

    try {
      if (state.isStreaming) {
        await _controller!.stopVideoStreaming();
        emit(state.copyWith(isStreaming: false));
      } else {
        emit(state.copyWith(isLoading: true));
        await _controller!.startVideoStreaming(
          "rtmp://82.148.1.150:1935/live/bozormedia",
        );
        await Future.delayed(const Duration(seconds: 1));
        if (_controller!.value.isStreamingVideoRtmp ?? false) {
          emit(state.copyWith(isStreaming: true, isLoading: false));
        } else {
          AppLogger.warning('Streaming failed to start');
          emit(
            state.copyWith(
              isStreaming: false,
              isLoading: false,
              errorMessage:
                  'Streaming failed: ${_controller!.value.errorDescription ?? "Check server or auth"}',
            ),
          );
        }
      }
    } on CameraException catch (e) {
      AppLogger.error('CameraException: ${e.code} - ${e.description}');
      emit(
        state.copyWith(
          isStreaming: false,
          isLoading: false,
          errorMessage: 'Camera error: ${e.description ?? e.code}',
        ),
      );
    } catch (e) {
      AppLogger.error('Unknown error: $e');
      emit(
        state.copyWith(
          isStreaming: false,
          isLoading: false,
          errorMessage: 'Failed to start/stop streaming: $e',
        ),
      );
    }
  }

  Future<void> switchCamera() async {
    if (_controller == null || !state.isControllerInitialized) {
      AppLogger.warning('Controller not ready for switching');
      emit(state.copyWith(errorMessage: 'Camera controller is not ready'));
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        AppLogger.warning('No additional cameras available');
        emit(state.copyWith(errorMessage: 'No additional cameras available'));
        return;
      }

      final newCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection != _controller!.description.lensDirection,
        orElse: () => cameras[0],
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
      AppLogger.error('Failed to switch camera: $e');
      emit(state.copyWith(errorMessage: 'Failed to switch camera: $e'));
    }
  }

  void setNullErrorMessage() {
    emit(state.copyWith(errorMessage: null));
  }

  @override
  Future<void> close() async {
    await _controller?.stopVideoStreaming();
    await _controller?.dispose();
    AppLogger.warning('UploadVideoCubit closed');
    super.close();
  }
}
