import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/core/routes/app_routes.dart';
import 'package:ecommerce_app/services/cart_service.dart';
import 'package:ecommerce_app/features/product/screens/product_details_screen.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/widgets/app_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  double minPrice = 0;
  double maxPrice = 1000;
  bool showFilters = false;

  final List<String> categories = [
    'All',
    "Men's outfit",
    "Woman's outfit",
    "Men's footwear",
  ];

  final CartService _cartService = CartService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Set<String> _favoriteIds = {};
  StreamSubscription? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _favoritesSubscription = FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _favoriteIds = snapshot.docs
                .map((d) => (d.data()['productId'] ?? '') as String)
                .toSet();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to cart')),
      );
      return;
    }

    final price = _parsePrice(product['price']);
    
    await _cartService.addToCart(
      productId: product['id'] ?? DateTime.now().toString(),
      name: product['title'] ?? product['name'] ?? 'Product',
      price: price,
      imageUrl: product['image'] ?? product['imageUrl'] ?? '',
      quantity: 1,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _addToFavorites(Map<String, dynamic> product) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to favorites')),
      );
      return;
    }

    final userId = _auth.currentUser!.uid;
    final favoriteRef = FirebaseFirestore.instance.collection('favorites');
    final price = _parsePrice(product['price']);

    final existing = await favoriteRef
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: product['id'] ?? product['title'])
        .get();

    if (existing.docs.isEmpty) {
      await favoriteRef.add({
        'userId': userId,
        'productId': product['id'] ?? product['title'],
        'name': product['title'] ?? product['name'] ?? 'Product',
        'price': price,
        'imageUrl': product['image'] ?? product['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites!')),
      );
    } else {
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites!')),
      );
    }
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Greeting and Cart/Profile Icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_auth.currentUser?.displayName ?? 'Guest'}!',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Find your favorite products',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Filter Chip Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Filter Button as Chip
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, size: 16, color: showFilters ? Colors.white : AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Filter', style: TextStyle(color: showFilters ? Colors.white : AppColors.primary)),
                      ],
                    ),
                    selected: showFilters,
                    onSelected: (val) => setState(() => showFilters = val),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedCategory == category ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            // Filter Panel (Slide down)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: showFilters ? 120 : 0,
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Price Range Slider
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Min Price', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '\$0',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        minPrice = double.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Max Price', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '\$1000',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        maxPrice = double.tryParse(value) ?? 1000;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedCategory != 'All' || minPrice > 0 || maxPrice < 1000)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = 'All';
                                minPrice = 0;
                                maxPrice = 1000;
                              });
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: AppColors.accentPink),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended for You',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
                    child: Text(
                      'See All',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Products Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No products available'),
                    );
                  }

                  var products = snapshot.data!.docs;

                  // Apply filters
                  products = products.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = (data['category'] ?? '').toString();
                    final price = _parsePrice(data['price']);
                    
                    bool categoryMatch = selectedCategory == 'All' || category == selectedCategory;
                    
                    if (!categoryMatch && selectedCategory != 'All') {
                      categoryMatch = category.toLowerCase() == selectedCategory.toLowerCase() ||
                          category.toLowerCase().contains(selectedCategory.toLowerCase());
                    }
                    
                    bool priceMatch = price >= minPrice && price <= maxPrice;
                    
                    return categoryMatch && priceMatch;
                  }).toList();

                  if (products.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_off, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No products match your filters'),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 315,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final data = products[index].data() as Map<String, dynamic>;
                      final productName = data['title'] ?? data['name'] ?? 'Product';
                      final productPrice = _parsePrice(data['price']);
                      final productImage = data['image'] ?? data['imageUrl'] ?? '';
                      final productRating = data['rating'] ?? 4.5;
                      final productCategory = data['category'] ?? '';
                      final productDescription = data['description'] ?? 'No description available';

                      return GestureDetector(
                        onTap: () => _navigateToProductDetails({
                          'id': products[index].id,
                          'title': productName,
                          'price': productPrice,
                          'image': productImage,
                          'rating': productRating,
                          'category': productCategory,
                          'description': productDescription,
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      productImage,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 140,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                    // Favorite Button
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _addToFavorites({
                                          'id': products[index].id,
                                          'title': productName,
                                          'price': productPrice,
                                          'image': productImage,
                                          'category': productCategory,
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _favoriteIds.contains(products[index].id)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 16,
                                            color: AppColors.accentPink,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Discount Badge (optional)
                                    if (productPrice > 100)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentPink,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '-${(20 / (productPrice + 20) * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Product Info
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) {
                                          final full = productRating.floor();
                                          final half = (productRating - full) >= 0.5;
                                          final IconData icon = i < full
                                              ? Icons.star
                                              : (i == full && half ? Icons.star_half : Icons.star_border);
                                          final Color color = i < full || (i == full && half)
                                              ? Colors.amber
                                              : Colors.grey[400]!;
                                          return Icon(icon, size: 14, color: color);
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          productRating.toStringAsFixed(1),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '\$${productPrice.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (productPrice > 100)
                                          Text(
                                            '\$${(productPrice + 20).toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              decoration: TextDecoration.lineThrough,
                                              color: AppColors.textLight,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _addToCart({
                                          'id': products[index].id,
                                          'title': productName,
                                          'price': productPrice,
                                          'image': productImage,
                                          'category': productCategory,
                                        }),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}