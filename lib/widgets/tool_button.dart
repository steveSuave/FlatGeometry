import 'package:flutter/material.dart';
import 'dart:math' as math;

class ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final EdgeInsets padding;

  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    // Add these lines for responsive measurements
    final size = MediaQuery.of(context).size;
    final minDimension = math.min(size.width, size.height);

    // Calculate responsive sizes
    final iconSize = minDimension * 0.05;
    final borderWidth = minDimension * 0.004;
    final borderRadius = minDimension * 0.015;
    final innerPadding = minDimension * 0.008;
    final verticalSpacing = minDimension * 0.008;

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: padding,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration:
                    isSelected
                        ? BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: borderWidth, // Responsive border width
                          ),
                          borderRadius: BorderRadius.circular(
                            borderRadius,
                          ), // Responsive border radius
                        )
                        : null,
                padding:
                    isSelected
                        ? EdgeInsets.all(innerPadding)
                        : EdgeInsets.zero, // Responsive padding
                child: Icon(
                  icon,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  size: iconSize, // Responsive icon size
                ),
              ),
              SizedBox(height: verticalSpacing), // Responsive spacing
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
