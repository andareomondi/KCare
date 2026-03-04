import 'package:go_router/go_router.dart';
import 'package:kcare/screens/homepage/homePage.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/ ',
      name: 'home',
      builder: (context, state) {
        return MyHomePage(title: "Home Page");
      },
    ),
  ],
);
