import 'package:flutter/material.dart';

class LoadingOverlay {
  static bool _shown = false;

  static Future<void> show(BuildContext context, {String message = 'Please wait…'}) async {
    if (_shown) return;
    _shown = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, a1, a2, child) {
        return Opacity(
          opacity: a1.value,
          child: _LoaderCard(message: message),
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );
  }

  static void hide(BuildContext context) {
    if (!_shown) return;
    _shown = false;
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _LoaderCard extends StatefulWidget {
  final String message;
  const _LoaderCard({required this.message});

  @override
  State<_LoaderCard> createState() => _LoaderCardState();
}

class _LoaderCardState extends State<_LoaderCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF1A1A1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 24)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing logo
            ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.06).animate(CurvedAnimation(
                parent: _c,
                curve: Curves.easeInOut,
              )),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Progress indicator
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Message + subtle dots
            _LoadingDots(text: widget.message),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  final String text;
  const _LoadingDots({required this.text});
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> {
  int _dots = 0;
  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return false;
      setState(() => _dots = (_dots + 1) % 4);
      return true; // loop
    });
  }

  @override
  Widget build(BuildContext context) {
    final dotStr = '.' * _dots;
    return Text(
      '${widget.text}$dotStr',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.8),
      ),
    );
  }
}
