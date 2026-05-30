import 'package:flutter/material.dart';
import 'package:ecommerce_app/features/home/screens/home_screen.dart';
import 'package:ecommerce_app/features/profile/screens/profile_screen.dart';
import 'package:ecommerce_app/features/cart/screens/cart_screen.dart';
import 'package:ecommerce_app/features/order/screens/confirmation_screen.dart';
import 'package:ecommerce_app/features/checkout/screens/checkout_screen.dart';
import 'package:ecommerce_app/features/favorite/screens/favorite_screen.dart';
import 'package:ecommerce_app/features/welcome/screens/welcome_screen.dart';
import 'package:ecommerce_app/features/auth/screens/sign_in_screen.dart';
import 'package:ecommerce_app/features/auth/screens/create_account_screen.dart';
import 'package:ecommerce_app/features/search/ui/search_view.dart';
import 'package:ecommerce_app/features/help_support_view.dart';
import 'package:ecommerce_app/features/product/screens/product_details_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String favorite = '/favorite';
  static const String signIn = '/sign-in';
  static const String createAccount = '/create-account';
  static const String checkout = '/checkout';
  static const String confirmation = '/confirmation';
  static const String helpSupport = '/help-support';
  static const String welcome = '/welcome';

  static Map<String, WidgetBuilder> routes = {
    welcome: (context) => const WelcomeScreen(),
    home: (context) => const HomeScreen(),
    profile: (context) => const ProfileScreen(),
    cart: (context) => const CartScreen(),
    confirmation: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ConfirmationScreen(orderId: args?['orderId'] as String?);
    },
    checkout: (context) => const CheckoutScreen(),
    favorite: (context) => const FavoriteScreen(),
    signIn: (context) => const SignInScreen(),
    createAccount: (context) => const CreateAccountScreen(),
    search: (context) => const SearchView(),
    helpSupport: (context) => const HelpSupportView(),
  };
}

// Temporary Placeholder Screen for incomplete screens
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1100FF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This screen is under construction',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1100FF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Homepage',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}