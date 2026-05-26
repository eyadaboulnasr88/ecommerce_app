import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/core/routes/app_routes.dart';

class FavoriteColors {
  static const Color primary = Color(0xFF1100FF);
  static const Color primaryLight = Color(0xFF4436FF);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFEF4444);
}

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  Future<void> _removeFromFavorites(String favoriteId) async {
    await _firestore.collection('favorites').doc(favoriteId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to cart')),
      );
      return;
    }

    // Check if product already in cart
    final existingCart = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: product['productId'])
        .get();

    if (existingCart.docs.isNotEmpty) {
      final cartDoc = existingCart.docs.first;
      final currentQuantity = cartDoc.data()['quantity'] ?? 1;
      await cartDoc.reference.update({
        'quantity': currentQuantity + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('carts').add({
        'userId': userId,
        'productId': product['productId'],
        'name': product['name'],
        'price': product['price'],
        'imageUrl': product['imageUrl'],
        'quantity': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: FavoriteColors.background,
        appBar: AppBar(
          title: Text('Favorites', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: FavoriteColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Please login to view your favorites',
                style: GoogleFonts.poppins(fontSize: 16, color: FavoriteColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.signIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FavoriteColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Sign In', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FavoriteColors.background,
      appBar: AppBar(
        title: Text('Favorites', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('favorites')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final favoriteItems = snapshot.data!.docs;

          if (favoriteItems.isEmpty) {
            return _buildEmptyFavorites();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favoriteItems.length,
            itemBuilder: (context, index) {
              final favoriteDoc = favoriteItems[index];
              final data = favoriteDoc.data() as Map<String, dynamic>;
              return _buildFavoriteCard(
                favoriteId: favoriteDoc.id,
                productId: data['productId'] ?? '',
                name: data['name'] ?? 'Product',
                price: (data['price'] ?? 0).toDouble(),
                imageUrl: data['imageUrl'] ?? '',
              );
            },
          );
        },
      ),
      bottomNavigationBar: const FavoriteBottomNavBar(),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: FavoriteColors.textLight),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: FavoriteColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your favorites',
            style: GoogleFonts.poppins(fontSize: 14, color: FavoriteColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: FavoriteColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Start Shopping', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard({
    required String favoriteId,
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FavoriteColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FavoriteColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product details for $name coming soon!')),
                    );
                  },
                  child: Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: FavoriteColors.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              ),
              // Heart Icon (Remove from favorites)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeFromFavorites(favoriteId),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 18,
                      color: FavoriteColors.accentPink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FavoriteColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: FavoriteColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _addToCart({
                        'productId': productId,
                        'name': name,
                        'price': price,
                        'imageUrl': imageUrl,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FavoriteColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteBottomNavBar extends StatelessWidget {
  const FavoriteBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: FavoriteColors.primary,
      unselectedItemColor: FavoriteColors.textSecondary,
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.search);
            break;
          case 2:
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.cart);
            break;
          case 4:
            Navigator.pushNamed(context, AppRoutes.profile);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}