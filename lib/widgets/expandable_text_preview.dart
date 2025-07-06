import 'package:flutter/material.dart';
import 'large_text_page.dart'; // Make sure this file exists in the same folder or update the import

class ExpandableTextPreview extends StatelessWidget {
  final String title;      // e.g. "Overview"
  final String text;       // Full text to display
  final String heroTag;    // Unique tag for Hero animation

  const ExpandableTextPreview({
    required this.title,
    required this.text,
    required this.heroTag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => LargeTextPage(
              title: title,
              text: text,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Stack(
            children: [
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 30,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
