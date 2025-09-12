// lib/widgets/neumorphic_category_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

/// A reusable neumorphic-style circular icon that accepts either an emoji
/// (string) or an IconData. Use `baseColor` to control the main color.
/// Keeps a compact size suitable for ListTile.leading.
class NeumorphicCategoryIcon extends StatelessWidget {
  final String? emoji; // prefer category emoji from your Category model
  final IconData? icon; // fallback if you prefer icons
  final double size;
  final Color baseColor;
  final bool small; // slightly smaller variant

  const NeumorphicCategoryIcon({
    Key? key,
    this.emoji,
    this.icon,
    this.size = 40,
    this.baseColor = Colors.deepOrange,
    this.small = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double s = small ? (size * 0.78) : size;
    // choose foreground color that contrasts with baseColor
    final brightness = ThemeData.estimateBrightnessForColor(baseColor);
    final fg = brightness == Brightness.dark ? Colors.white : Colors.black87;

    return Neumorphic(
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.circle(),
        color: baseColor,
        depth: 4,
        intensity: 0.9,
        surfaceIntensity: 0.2,
        lightSource: LightSource.topLeft,
        shadowDarkColor: Colors.black54,
      ),
      child: SizedBox(
        height: s,
        width: s,
        child: Center(
          child: emoji != null
              ? Text(
                  emoji!,
                  style: TextStyle(fontSize: s * 0.5),
                )
              : icon != null
                  ? Icon(icon, size: s * 0.5, color: fg)
                  : Icon(Icons.category, size: s * 0.5, color: fg),
        ),
      ),
    );
  }
}
