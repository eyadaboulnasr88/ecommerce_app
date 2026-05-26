import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF1100FF);
const Color backgroundColor = Color(0xFFF8F9FA);

// ── Model ──────────────────────────────────────────────────────────────────────

class FavouriteItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final String category;

  FavouriteItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.category,
  });

  factory FavouriteItem.fromMap(Map<String, dynamic> map) => FavouriteItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        rating: (map['rating'] ?? 0).toDouble(),
        category: map['category'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'rating': rating,
        'category': category,
        'savedAt': FieldValue.serverTimestamp(),
      };
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCategory = 'All';
  bool _isGridView = true;

  // Returns the Firestore reference for the current user's favourites
  CollectionReference<Map<String, dynamic>>? get _favRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('favourites');
  }

  // Remove a single item
  Future<void> _removeItem(String itemId) async {
    await _favRef?.doc(itemId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favourites',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              // NOTE: re-add logic would need the item data — wire as needed
            },
          ),
        ),
      );
    }
  }

  // Clear all favourites
  Future<void> _clearAll(List<FavouriteItem> items) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Clear Favourites',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Remove all ${items.length} items from your favourites?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text('Clear All',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && _favRef != null) {
      final batch = _firestore.batch();
      for (final item in items) {
        batch.delete(_favRef!.doc(item.id));
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Favourites',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Items you love',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  // Grid / List toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isGridView = !_isGridView),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content (Firestore stream) ──────────────────────────────────
            Expanded(
              child: uid == null
                  ? _buildNotLoggedIn()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('users')
                          .doc(uid)
                          .collection('favourites')
                          .orderBy('savedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: primaryColor),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildError();
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final allItems = docs
                            .map((d) => FavouriteItem.fromMap(d.data()))
                            .toList();

                        if (allItems.isEmpty) return _buildEmpty();

                        // Categories
                        final categories = [
                          'All',
                          ...{...allItems.map((i) => i.category)}
                              .where((c) => c.isNotEmpty)
                        ];

                        final filtered = _selectedCategory == 'All'
                            ? allItems
                            : allItems
                                .where((i) =>
                                    i.category == _selectedCategory)
                                .toList();

                        return Column(
                          children: [
                            // Count + Clear
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 16, 20, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${allItems.length} saved item${allItems.length == 1 ? '' : 's'}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade600),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _clearAll(allItems),
                                    child: Text('Clear all',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.red.shade400,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),

                            // Category chips
                            if (categories.length > 1)
                              _buildCategoryChips(categories),

                            // Grid or List
                            Expanded(
                              child: filtered.isEmpty
                                  ? _buildEmptyCategory()
                                  : _isGridView
                                      ? _buildGrid(filtered)
                                      : _buildList(filtered),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Chips ──────────────────────────────────────────────────────────

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      selected ? primaryColor : Colors.grey.shade200,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Grid View ───────────────────────────────────────────────────────────────

  Widget _buildGrid(List<FavouriteItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildGridCard(items[i]),
    );
  }

  Widget _buildGridCard(FavouriteItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Remove button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder())
                      : _imagePlaceholder(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.red, size: 16),
                  ),
                ),
              ),
              if (item.category.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.category,
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(item.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600)),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add to cart
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('Add to Cart',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── List View ───────────────────────────────────────────────────────────────

  Widget _buildList(List<FavouriteItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildListCard(items[i]),
    );
  }

  Widget _buildListCard(FavouriteItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _removeItem(item.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder())
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.category.isNotEmpty)
                    Text(item.category,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: primaryColor,
                            fontWeight: FontWeight.w600)),
                  Text(item.name,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(item.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Price + actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  // Remove
                  GestureDetector(
                    onTap: () => _removeItem(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.favorite,
                          color: Colors.red.shade400, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add to cart
                  GestureDetector(
                    onTap: () {
                      // TODO: Add to cart
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: primaryColor, size: 16),
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty / Error States ────────────────────────────────────────────────────

  Widget _buildEmpty() => _buildState(
        icon: Icons.favorite_border_rounded,
        iconColor: Colors.pink.shade200,
        iconBg: Colors.pink.shade50,
        title: 'No Favourites Yet',
        subtitle:
            'Tap the heart icon on any product\nto save it here for later.',
        buttonLabel: 'Browse Products',
        onTap: () => Navigator.pop(context),
      );

  Widget _buildEmptyCategory() => _buildState(
        icon: Icons.filter_list_off_rounded,
        iconColor: Colors.grey.shade400,
        iconBg: Colors.grey.shade100,
        title: 'No items in "$_selectedCategory"',
        subtitle: 'Try selecting a different category.',
        buttonLabel: 'Show All',
        onTap: () =>
            setState(() => _selectedCategory = 'All'),
      );

  Widget _buildNotLoggedIn() => _buildState(
        icon: Icons.lock_outline_rounded,
        iconColor: primaryColor,
        iconBg: primaryColor.withOpacity(0.1),
        title: 'Sign in to see Favourites',
        subtitle:
            'Create an account or sign in to\nsave and sync your favourite items.',
        buttonLabel: 'Sign In',
        onTap: () => Navigator.pop(context),
      );

  Widget _buildError() => _buildState(
        icon: Icons.wifi_off_rounded,
        iconColor: Colors.orange.shade400,
        iconBg: Colors.orange.shade50,
        title: 'Something went wrong',
        subtitle: 'Check your connection and try again.',
        buttonLabel: 'Retry',
        onTap: () => setState(() {}),
      );

  Widget _buildState({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                elevation: 0,
              ),
              child: Text(buttonLabel,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.image_outlined,
            color: Colors.grey.shade400, size: 32),
      );
}
