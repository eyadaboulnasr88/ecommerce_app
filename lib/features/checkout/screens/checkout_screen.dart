import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/core/routes/app_routes.dart';

class CheckoutColors {
  static const Color primary = Color(0xFF1100FF);
  static const Color primaryLight = Color(0xFF4436FF);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color success = Color(0xFF10B981);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFEF4444);
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Order notes
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isProcessing = false;

  String get userId => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (userId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _fullNameController.text = data?['name'] ?? '';
        _phoneController.text = data?['phone'] ?? '';
        _addressController.text = data?['address'] ?? '';
        _cityController.text = data?['city'] ?? '';
      }
    } catch (_) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    // Validate form
    if (_fullNameController.text.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    if (_addressController.text.isEmpty) {
      _showError('Please enter your address');
      return;
    }
    if (_cityController.text.isEmpty) {
      _showError('Please enter your city');
      return;
    }

    if (userId.isEmpty) {
      _showError('Please login to place order');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get cart items
      final cartSnapshot = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .get();

      if (cartSnapshot.docs.isEmpty) {
        _showError('Your cart is empty');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Calculate totals
      double subtotal = 0;
      List<Map<String, dynamic>> orderItems = [];

      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        final price = (data['price'] ?? 0).toDouble();
        final quantity = (data['quantity'] ?? 1).toInt();
        final itemTotal = price * quantity;
        subtotal += itemTotal;

        orderItems.add({
          'productId': data['productId'] ?? '',
          'name': data['name'] ?? 'Product',
          'price': price,
          'quantity': quantity,
          'imageUrl': data['imageUrl'] ?? '',
          'total': itemTotal,
        });
      }

      final shipping = subtotal > 50 ? 0 : 5.99;
      final total = subtotal + shipping;

      // Create order
      final orderData = {
        'userId': userId,
        'userName': _fullNameController.text,
        'phone': _phoneController.text,
        'shippingAddress': '${_addressController.text}, ${_cityController.text}, ${_postalCodeController.text}',
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'notes': _notesController.text,
        'items': orderItems,
        'subtotal': subtotal,
        'shipping': shipping,
        'total': total,
        'paymentMethod': 'Cash on Delivery',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save order to Firestore
      final orderRef = await _firestore.collection('orders').add(orderData);
      final orderId = orderRef.id;

      // Update order with orderId
      await orderRef.update({'orderId': orderId});

      // Clear cart
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.confirmation,
          arguments: {'orderId': orderId},
        );
      }
    } catch (e) {
      _showError('Failed to place order: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CheckoutColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: CheckoutColors.background,
        appBar: AppBar(
          title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: CheckoutColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Please login to checkout',
                style: GoogleFonts.poppins(fontSize: 16, color: CheckoutColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.signIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CheckoutColors.primary,
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
      backgroundColor: CheckoutColors.background,
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart Summary Section
                  const CartSummarySection(),
                  const SizedBox(height: 16),

                  // Shipping Information
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shipping Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CheckoutColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          hint: 'Enter your street address',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'City',
                                icon: Icons.location_city,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _postalCodeController,
                                label: 'Postal Code',
                                hint: 'Postal code',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Notes
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Notes (Optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CheckoutColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add any special instructions for delivery...',
                            hintStyle: GoogleFonts.poppins(color: CheckoutColors.textLight),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: CheckoutColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: CheckoutColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: CheckoutColors.primary, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CheckoutColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: CheckoutColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.money, color: CheckoutColors.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Cash on Delivery',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.check_circle, color: CheckoutColors.success, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: CheckoutColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CheckoutColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CheckoutColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: CheckoutColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('carts')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final cartItems = snapshot.data!.docs;
            double subtotal = 0;
            for (var item in cartItems) {
              final data = item.data() as Map<String, dynamic>;
              subtotal += (data['price'] ?? 0) * (data['quantity'] ?? 1);
            }

            final shipping = subtotal > 50 ? 0 : 5.99;
            final total = subtotal + shipping;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: GoogleFonts.poppins(color: CheckoutColors.textSecondary),
                    ),
                    Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shipping',
                      style: GoogleFonts.poppins(color: CheckoutColors.textSecondary),
                    ),
                    Text(
                      shipping == 0 ? 'Free' : '\$${shipping.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Divider(height: 24, color: CheckoutColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CheckoutColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CheckoutColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Place Order',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==================== CART SUMMARY SECTION ====================
class CartSummarySection extends StatelessWidget {
  const CartSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CheckoutColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('carts')
                .where('userId', isEqualTo: userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cartItems = snapshot.data!.docs;

              if (cartItems.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 50, color: CheckoutColors.textLight),
                      const SizedBox(height: 8),
                      Text(
                        'Your cart is empty',
                        style: GoogleFonts.poppins(color: CheckoutColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length > 3 ? 3 : cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final data = item.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image_not_supported, size: 25, color: Colors.grey[400]),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Product',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Qty: ${data['quantity'] ?? 1}',
                                    style: GoogleFonts.poppins(fontSize: 12, color: CheckoutColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${((data['price'] ?? 0) * (data['quantity'] ?? 1)).toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (cartItems.isNotEmpty)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                      child: Text(
                        'View all items →',
                        style: GoogleFonts.poppins(color: CheckoutColors.primary),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}