import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../utils/debounce.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rtmp_broadcaster/camera.dart';

part 'stream_state.dart';

class UploadVideoCubit extends Cubit<UploadVideoState> {
  CameraController? _controller;
  CameraController? get controller => _controller;
  late final Debouncer _debouncer;

  UploadVideoCubit() : super(const UploadVideoState()) {
    _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
    _initialize();
  }

  Future<void> emitError(String errorMessage) async {
    if (state.errorMessage != null) return;
    if (_controller != null &&
        (state.isStreaming ||
            _controller!.value.isStreamingVideoRtmp == true)) {
      try {
        await _controller!.stopVideoStreaming();
      } catch (e) {
        AppLogger.error('Failed to stop streaming on error: $e');
      }
    }

    _debouncer.run(() {
      emit(
        state.copyWith(
          errorMessage: errorMessage,
          isStreaming: false,
          isLoading: false,
        ),
      );
    });
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
      await emitError('Camera or microphone permission denied');
    }
  }

  Future<void> _initializeController() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        await emitError('No cameras available');
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _controller!.initialize();

      _controller!.addListener(() async {
        if (state.errorMessage != null) return;

        if (_controller!.value.hasError) {
          AppLogger.error(
            'Camera error: ${_controller!.value.errorDescription}',
          );
          await emitError(
            'Camera error: ${_controller!.value.errorDescription}',
          );
        } else if (_controller!.value.event != null) {
          final event = _controller!.value.event as Map<dynamic, dynamic>;
          final eventType = event['eventType'] as String?;
          final errorDesc = event['errorDescription'] as String?;
          if (eventType == 'rtmp_retry' &&
              errorDesc == 'Fail to connect, time out') {
            AppLogger.error('Timeout detected, stopping stream...');
            await emitError(
              'Connection timed out: Failed to connect to server',
            );
          } else if (eventType == 'error' &&
              errorDesc?.contains('unauthenticated') == true) {
            AppLogger.error('Unauthenticated error detected');
            await emitError('Unauthenticated: Server rejected the stream');
          }
        }
      });

      emit(state.copyWith(isControllerInitialized: true));
    } catch (e) {
      AppLogger.error('Failed to initialize camera: $e');
      await emitError('Failed to initialize camera: $e');
    }
  }

  Future<void> toggleStreaming() async {
    if (_controller == null || !state.isControllerInitialized) {
      AppLogger.warning('Controller not ready for streaming');
      await emitError('Camera controller is not ready');
      return;
    }

    try {
      if (state.isStreaming) {
        await _controller!.stopVideoStreaming();
        emit(state.copyWith(isStreaming: false));
      } else {
        emit(state.copyWith(isLoading: true));
        await _controller!.startVideoStreaming(AppConstants.rtmp);
        await Future.delayed(const Duration(seconds: 1));
        if (state.errorMessage != null) {
          emit(state.copyWith(isLoading: false));
          return;
        }
        if (_controller!.value.isStreamingVideoRtmp ?? false) {
          emit(state.copyWith(isStreaming: true, isLoading: false));
        } else {
          AppLogger.warning('Streaming failed to start');
          await emitError(
            'Streaming failed: ${_controller!.value.errorDescription ?? "Check server or auth"}',
          );
        }
      }
    } on CameraException catch (e) {
      AppLogger.error('CameraException: ${e.code} - ${e.description}');
      await emitError('Camera error: ${e.description ?? e.code}');
    } catch (e) {
      AppLogger.error('Unknown error: $e');
      await emitError('Failed to start/stop streaming: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_controller == null || !state.isControllerInitialized) {
      AppLogger.warning('Controller not ready for switching');
      await emitError('Camera controller is not ready');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        AppLogger.warning('No additional cameras available');
        await emitError('No additional cameras available');
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
      await emitError('Failed to switch camera: $e');
    }
  }

  void setNullErrorMessage() {
    emit(state.copyWith(errorMessage: null));
  }

  @override
  Future<void> close() async {
    await _controller?.stopVideoStreaming();
    await _controller?.dispose();
    _debouncer.cancel();
    AppLogger.warning('UploadVideoCubit closed');
    super.close();
  }
}
