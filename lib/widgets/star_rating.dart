import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int rating; // 1–5, 0 means unrated
  final ValueChanged<int>? onChanged; // null = read-only
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(i + 1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? AppTheme.accentAmber : Colors.grey.shade300,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
