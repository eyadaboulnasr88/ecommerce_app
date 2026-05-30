import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/features/home/screens/home_screen.dart';
import 'package:ecommerce_app/services/cart_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final CartService _cartService = CartService();
  bool _isAddingToCart = false;

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    return double.tryParse(price.toString()) ?? 0.0;
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items to cart')),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      await _cartService.addToCart(
        productId: widget.product['id']?.toString() ??
            widget.product['title']?.toString() ??
            '',
        name: widget.product['title'] ?? widget.product['name'] ?? 'Product',
        price: _parsePrice(widget.product['price']),
        imageUrl: widget.product['image'] ?? widget.product['imageUrl'] ?? '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${widget.product['title'] ?? 'Item'} added to cart!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to cart. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.product['title'] ?? 'Product Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[100],
              child: Image.network(
                widget.product['image'] ?? '',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.broken_image,
                      size: 80, color: Colors.grey[400]),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product['title'] ?? 'Product Name',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index <
                                  (widget.product['rating'] ?? 4.5).floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 18,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.product['rating']?.toString() ?? '4.5'})',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Text(
                    '\$${_parsePrice(widget.product['price']).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product['category'] ?? 'Uncategorized',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'] ??
                        'No description available for this product.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAddingToCart ? null : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isAddingToCart
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Add to Cart',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
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
      ),
    );
  }
}
