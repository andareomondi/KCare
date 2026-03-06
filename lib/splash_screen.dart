import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:kcare/screens/homepage/homePage.dart';
import 'package:lottie/lottie.dart';

class AnimatedSplashScreenWidget extends StatelessWidget {
  const AnimatedSplashScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(child: Lottie.asset('assets/animation_splash.json')),
      nextScreen: MyHomePage(title: 'K-Care Home Page'),
      splashTransition: SplashTransition.fadeTransition,
      splashIconSize: 600,
    );
  }
}
