import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class AnimatedSplashScreenWidget extends StatefulWidget {
  const AnimatedSplashScreenWidget({super.key});

  @override
  State<AnimatedSplashScreenWidget> createState() =>
      _AnimatedSplashScreenWidgetState();
}

class _AnimatedSplashScreenWidgetState
    extends State<AnimatedSplashScreenWidget> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    FlutterNativeSplash.remove();
    await Future.delayed(const Duration(seconds: 10));

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 600,
          height: 600,
          child: Lottie.asset(
            'assets/animation_splash.json',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
