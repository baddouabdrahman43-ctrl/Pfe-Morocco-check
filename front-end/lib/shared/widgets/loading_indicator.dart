import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullscreen;

  const LoadingIndicator({super.key, this.message, this.fullscreen = false});

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[const SizedBox(height: 12), Text(message!)],
        ],
      ),
    );

    if (!fullscreen) {
      return content;
    }

    return ColoredBox(color: Colors.black54, child: content);
  }
}
