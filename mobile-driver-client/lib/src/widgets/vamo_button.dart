import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Themed primary button with loading state support.
class VamoButton extends StatelessWidget {
  const VamoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? VamoTheme.primary;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: effectiveColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        ),
        child: _buildChild(effectiveColor),
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      ),
      child: _buildChild(Colors.white),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.5,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}