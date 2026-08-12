import 'package:flutter/material.dart';

/// Widget de chargement squelette (Skeleton Loader) conforme à DESIGN.md
/// Remplaçant avantageusement les CircularProgressIndicator bruts.
class SkeletonLoaderWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoaderWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.margin,
  });

  /// Skeleton pour une carte d'intervention
  static Widget interventionCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoaderWidget(width: 120, height: 16, borderRadius: 4),
              SkeletonLoaderWidget(width: 70, height: 22, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonLoaderWidget(width: 200, height: 18, borderRadius: 4),
          const SizedBox(height: 8),
          const SkeletonLoaderWidget(width: double.infinity, height: 14, borderRadius: 4),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLoaderWidget(width: 90, height: 14, borderRadius: 4),
              SkeletonLoaderWidget(width: 80, height: 32, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }

  /// Skeleton pour une liste d'interventions/souscriptions
  static Widget listSkeleton({int count = 4}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => interventionCardSkeleton(),
    );
  }

  @override
  State<SkeletonLoaderWidget> createState() => _SkeletonLoaderWidgetState();
}

class _SkeletonLoaderWidgetState extends State<SkeletonLoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Color.fromRGBO(226, 232, 240, _animation.value), // Slate-200 Shimmer
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
