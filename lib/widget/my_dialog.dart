import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String message) async {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}
