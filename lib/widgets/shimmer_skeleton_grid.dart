import 'package:flutter/material.dart';

class ShimmerProductSkeletonGrid extends StatefulWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childAspectRatio;

  const ShimmerProductSkeletonGrid({
    super.key,
    this.crossAxisCount = 3,
    this.itemCount = 6,
    this.childAspectRatio = 0.66,
  });

  @override
  State<ShimmerProductSkeletonGrid> createState() =>
      _ShimmerProductSkeletonGridState();
}

class _ShimmerProductSkeletonGridState extends State<ShimmerProductSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double slide = -1.0 + (_controller.value * 3.0);
        final gradient = LinearGradient(
          begin: Alignment(slide - 1.0, -0.3),
          end: Alignment(slide, 0.3),
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
          stops: const [0.1, 0.5, 0.9],
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: widget.itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 58,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
