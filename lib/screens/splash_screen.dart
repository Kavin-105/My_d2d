import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated app icon with multiple effects
              ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // App title with slide up animation
              SlideTransition(
                position: _slideUp,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Text(
                    "Your Day To Day",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle with slide up animation
              SlideTransition(
                position: _slideUp,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Text(
                    "Stay organized, stay productive",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Custom animated loading indicator
              _buildAnimatedLoader(),

              const SizedBox(height: 20),

              // Loading text with subtle animation
              FadeTransition(
                opacity: _controller.drive(
                  CurveTween(curve: const Interval(0.7, 1.0)),
                ),
                child: Text(
                  "Preparing your tasks...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoader() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating circle
          RotationTransition(
            turns: _controller.drive(
              CurveTween(curve: Curves.linear),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue.shade300,
                  width: 2,
                ),
              ),
            ),
          ),

          // Middle pulsing circle
          ScaleTransition(
            scale: _controller.drive(
              CurveTween(
                curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
              ).chain(
                CurveTween(
                  curve: const SawTooth(3),
                ),
              ),
            ),
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade400.withOpacity(0.7),
              ),
            ),
          ),

          // Inner dot
          ScaleTransition(
            scale: _controller.drive(
              CurveTween(
                curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
              ).chain(
                CurveTween(
                  curve: const SawTooth(3),
                ),
              ),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}