import 'package:flutter/material.dart';

class LargeTextPage extends StatelessWidget {
  final String title;
  final String text;
  final String heroTag;

  const LargeTextPage({
    required this.title,
    required this.text,
    required this.heroTag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const BackButton(),
      ),
      body: Hero(
        tag: heroTag,
        child: Material( // Needed to preserve text styling inside Hero
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              text,
              style: textStyle,
              textAlign: TextAlign.justify,
            ),
          ),
        ),
      ),
    );
  }
}
