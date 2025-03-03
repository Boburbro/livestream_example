import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livestream_example/cubit/stream_cubit.dart';
import 'package:rtmp_broadcaster/camera.dart';
import 'widget/my_dialog.dart';

class UploadVideo extends StatelessWidget {
  const UploadVideo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UploadVideoCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Live Stream App')),
        body: BlocConsumer<UploadVideoCubit, UploadVideoState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              showErrorDialog(context, state.errorMessage!);
              context.read<UploadVideoCubit>().setNullErrorMessage();
            }
          },
          builder: (context, state) {
            final cubit = context.read<UploadVideoCubit>();

            return Stack(
              children: [
                if (state.isControllerInitialized && cubit.controller != null)
                  CameraPreview(cubit.controller!)
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
                            onPressed:
                                state.isLoading || state.errorMessage != null
                                    ? null
                                    : cubit
                                        .toggleStreaming,
                            child: Text(
                              state.isStreaming
                                  ? 'Stop Streaming'
                                  : 'Start Streaming',
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed:
                                state.isLoading || state.errorMessage != null
                                    ? null
                                    : cubit
                                        .switchCamera,
                            child: Text(
                              state.isFrontCamera
                                  ? 'Switch to Rear'
                                  : 'Switch to Front',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
