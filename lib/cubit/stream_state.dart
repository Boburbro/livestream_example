part of "stream_cubit.dart";

class UploadVideoState extends Equatable {
  final bool isLoading;
  final bool isStreaming;
  final bool isControllerInitialized;
  final bool isFrontCamera;
  final String? errorMessage;

  const UploadVideoState({
    this.isLoading = false,
    this.isStreaming = false,
    this.isControllerInitialized = false,
    this.isFrontCamera = false,
    this.errorMessage,
  });

  UploadVideoState copyWith({
    bool? isLoading,
    bool? isStreaming,
    bool? isControllerInitialized,
    bool? isFrontCamera,
    String? errorMessage,
  }) {
    return UploadVideoState(
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      isControllerInitialized:
          isControllerInitialized ?? this.isControllerInitialized,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isStreaming,
    isControllerInitialized,
    isFrontCamera,
    errorMessage,
  ];
}
