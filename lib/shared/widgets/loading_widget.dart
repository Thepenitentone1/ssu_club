import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final String? message;

  const LoadingWidget({
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/Animation_load.json',
              width: width ?? 120,
              height: height ?? 120,
              fit: BoxFit.contain,
              repeat: true,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Convenience widget for full screen loading
class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LoadingWidget(
        message: message,
        backgroundColor: const Color(0xFFF8FAFC),
      ),
    );
  }
}

// Small loading widget for buttons and small areas
class SmallLoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const SmallLoadingWidget({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/Animation_load.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
} 