import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnifiedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showMic;
  final VoidCallback? onMicPressed;

  const UnifiedAppBar({
    super.key,
    this.showMic = true,
    this.onMicPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<UnifiedAppBar> createState() => _UnifiedAppBarState();
}

class _UnifiedAppBarState extends State<UnifiedAppBar> {
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted) {
        setState(() => isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: theme.colorScheme.background,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/'),
              child: Image.asset(
                'assets/logo.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),

            // Search field
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Search movies, shows, people...',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: (query) {
                          // Add search logic if needed
                        },
                      ),
                    ),
                    if (isSearching || _searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => isSearching = false);
                        },
                        child: const Icon(Icons.close, size: 20),
                      ),
                  ],
                ),
              ),
            ),

            // Mic button
            if (widget.showMic) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.mic, size: 28),
                onPressed: widget.onMicPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
