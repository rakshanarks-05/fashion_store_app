import 'package:flutter/material.dart';

import '../../../product/presentation/theme/shop_tokens.dart';

/// Placeholder layout while category data loads (optional — match screen structure).
class AllCategoriesSkeleton extends StatefulWidget {
  const AllCategoriesSkeleton({super.key});

  @override
  State<AllCategoriesSkeleton> createState() => _AllCategoriesSkeletonState();
}

class _AllCategoriesSkeletonState extends State<AllCategoriesSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = 0.35 + _pulse.value * 0.25;
        final base = Color.lerp(ShopTokens.searchFill, Colors.white, t)!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            ShopTokens.screenHorizontal,
            8,
            ShopTokens.screenHorizontal,
            24,
          ),
          children: [
            _Bar(color: base, height: 28, width: 180),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _Bar(color: base, height: 44)),
                const SizedBox(width: 8),
                Expanded(child: _Bar(color: base, height: 44)),
                const SizedBox(width: 8),
                Expanded(child: _Bar(color: base, height: 44)),
              ],
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < 5; i++) ...[
              _Bar(color: base, height: 72, radius: 12),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.color,
    required this.height,
    this.width,
    this.radius = 8,
  });

  final Color color;
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
