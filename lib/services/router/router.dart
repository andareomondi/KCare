import 'package:go_router/go_router.dart';
import 'package:kcare/screens/homepage/homePage.dart';
import 'package:kcare/splash_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) {
        return MyHomePage(title: "Home Page");
      },
    ),
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) {
        return const AnimatedSplashScreenWidget();
      },
    ),
  ],
);
