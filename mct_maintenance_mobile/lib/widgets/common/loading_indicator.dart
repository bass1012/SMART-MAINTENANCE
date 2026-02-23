import 'package:flutter/material.dart';

class LoadingIndicator extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 14.0,
    this.color,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final progress = (_controller.value + delay) % 1.0;
                  final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
                  final opacity =
                      0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2));

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: dotColor.withOpacity(opacity),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    transform: Matrix4.identity()..scale(scale),
                  );
                },
              );
            }),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

// Variante de l'indicateur de chargement pour les boutons
class ButtonLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const ButtonLoadingIndicator({
    super.key,
    this.color,
    this.size = 8.0,
  });

  @override
  State<ButtonLoadingIndicator> createState() => _ButtonLoadingIndicatorState();
}

class _ButtonLoadingIndicatorState extends State<ButtonLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Theme.of(context).colorScheme.onPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
            final opacity = 0.3 + (0.7 * (1 - (progress - 0.5).abs() * 2));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          },
        );
      }),
    );
  }
}
