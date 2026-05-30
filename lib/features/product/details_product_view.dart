import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/services/cart_service.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';

class DetailsProductView extends StatelessWidget {
  final dynamic product;

  const DetailsProductView({
    super.key,
    required this.product,
  });

  Future<void> addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    try {
      await CartService().addToCart(
        productId: product.id,
        name: product.title,
        price: product.price,
        imageUrl: product.image,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    }
  }

  Future<void> addToFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    try {
      final favRef = FirebaseFirestore.instance.collection('favorites');
      final existing = await favRef
          .where('userId', isEqualTo: user.uid)
          .where('productId', isEqualTo: product.id)
          .get();

      if (!context.mounted) return;

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in favorites')),
        );
        return;
      }

      await favRef.add({
        'userId': user.uid,
        'productId': product.id,
        'name': product.title,
        'price': product.price,
        'imageUrl': product.image,
        'description': product.description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        actions: [
          IconButton(
            onPressed: () => addToFavorite(context),
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.red,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// PRODUCT IMAGE
            Container(
              width: double.infinity,
              height: 320,
              padding: const EdgeInsets.all(20),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),

                child: Image.network(
                  product.image,
                  fit: BoxFit.contain,

                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                      ),
                    );
                  },
                ),
              ),
            ),

            /// DETAILS
            Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  Text(
                    product.title,

                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// PRICE
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',

                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF1100FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// DESCRIPTION TITLE
                  const Text(
                    'Description',

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  Text(
                    product.description,

                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// ADD TO CART BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(
                      onPressed: () => addToCart(context),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Add To Cart',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}