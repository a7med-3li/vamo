import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// An animated banner that slides in to show error or success messages.
/// Adapts to both Dark and Light modes.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    this.message,
    this.isError = true,
    this.onDismiss,
  });

  final String? message;
  final bool isError;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = context.isDarkTheme;

    final bgColor = isError
        ? (isDark ? const Color(0xFF3B1111) : const Color(0xFFFEE2E2))
        : (isDark ? const Color(0xFF0F3B1D) : const Color(0xFFDCFCE7));

    final borderColor = isError
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
        : (isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC));

    final contentColor = isError
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
        : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey(message),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: contentColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message!,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  color: contentColor,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}