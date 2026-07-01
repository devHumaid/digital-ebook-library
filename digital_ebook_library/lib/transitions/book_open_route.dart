import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A page transition that mimics opening a hardcover book: the incoming
/// screen swings open around a vertical spine on the left edge — starting
/// nearly edge-on like a closed cover — with a soft ambient shadow that
/// fades out as the "page" settles flat.
class BookOpenRoute<T> extends PageRouteBuilder<T> {
  BookOpenRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) {
                final t = curved.value.clamp(0.0, 1.0);
                // 0 -> nearly edge-on (closed cover), 1 -> flat open.
                final angle = (1 - t) * (math.pi * 0.49);
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0018) // perspective
                  ..rotateY(-angle);

                return Stack(
                  children: [
                    // Ambient shadow cast by the cover as it lifts off the page.
                    Opacity(
                      opacity: (1 - t) * 0.55,
                      child: Container(color: Colors.black),
                    ),
                    Transform(
                      alignment: Alignment.centerLeft,
                      transform: transform,
                      child: Opacity(
                        // Keep a floor so the page doesn't vanish mid-swing.
                        opacity: math.max(t, 0.15),
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
}