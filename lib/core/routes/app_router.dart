import 'package:flutter/material.dart';
import '../../features/auth/screens/create_account_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/welcome/screen/welcome.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return _route(const WelcomeScreen());
      case AppRoutes.signIn:
        return _route(const SignInScreen());
      case AppRoutes.createAccount:
        return _route(const CreateAccountScreen());
      case AppRoutes.home:
        return _route(const HomeScreen());
      case AppRoutes.profile:
        return _route(const ProfileScreen());
      default:
        return _route(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
