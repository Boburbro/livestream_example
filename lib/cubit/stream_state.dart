part of 'stream_cubit.dart';

class UploadVideoState extends Equatable {
  final bool isStreaming;
  final bool isControllerInitialized;
  final bool isFrontCamera;
  final bool isLoading;
  final String? errorMessage;

  const UploadVideoState({
    this.isStreaming = false,
    this.isControllerInitialized = false,
    this.isFrontCamera = true,
    this.isLoading = false,
    this.errorMessage,
  });

  UploadVideoState copyWith({
    bool? isStreaming,
    bool? isControllerInitialized,
    bool? isFrontCamera,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UploadVideoState(
      isStreaming: isStreaming ?? this.isStreaming,
      isControllerInitialized:
          isControllerInitialized ?? this.isControllerInitialized,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isStreaming,
    isControllerInitialized,
    isFrontCamera,
    isLoading,
  ];
}
