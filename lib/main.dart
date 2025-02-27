import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:livestream_example/join.dart';
import 'package:livestream_example/upload_video.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (ctx) => const UploadVideo()),
                );
              },
              child: const Text("Upload"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (ctx) => const Join()),
                );
              },
              child: const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}
