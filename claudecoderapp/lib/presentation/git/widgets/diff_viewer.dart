import 'package:flutter/material.dart';

class DiffViewer extends StatelessWidget {
  final String diff;

  const DiffViewer({super.key, required this.diff});

  @override
  Widget build(BuildContext context) {
    if (diff.isEmpty) {
      return const Center(
        child: Text('No changes to display'),
      );
    }

    final lines = diff.split('\n');

    return ListView.builder(
      itemCount: lines.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final line = lines[index];
        return DiffLine(line: line);
      },
    );
  }
}

class DiffLine extends StatelessWidget {
  final String line;

  const DiffLine({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? textColor;

    // Determine line type and colors based on prefix
    if (line.startsWith('+')) {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green[900];
    } else if (line.startsWith('-')) {
      backgroundColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red[900];
    } else if (line.startsWith('@@')) {
      backgroundColor = Colors.blue.withOpacity(0.2);
      textColor = Colors.blue[900];
    } else if (line.startsWith('diff') ||
               line.startsWith('index') ||
               line.startsWith('---') ||
               line.startsWith('+++')) {
      textColor = Colors.grey[600];
    }

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: textColor ?? Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
