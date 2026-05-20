import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF1100FF);
const Color backgroundColor = Color(0xFFF8F9FA);

// ── Data Models ────────────────────────────────────────────────────────────────

class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
      };
}

// ── Checkout Screen ────────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  int _selectedPayment = 0; // 0=Card, 1=Cash, 2=Wallet
  int _currentStep = 0;     // 0=Delivery, 1=Payment, 2=Review
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? user.displayName ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _cityController.text = data['city'] ?? '';
          _zipController.text = data['zip'] ?? '';
        });
      }
    } catch (_) {}
  }

  // ── Totals ─────────────────────────────────────────────────────────────────

  double get _subtotal =>
      widget.cartItems.fold(0, (sum, i) => sum + i.price * i.quantity);
  double get _shipping => _subtotal > 100 ? 0 : 9.99;
  double get _tax => _subtotal * 0.08;
  double get _total => _subtotal + _shipping + _tax;

  // ── Place Order ────────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      final orderId =
          _firestore.collection('orders').doc().id;

      final orderData = {
        'orderId': orderId,
        'userId': user?.uid ?? 'guest',
        'customerName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'deliveryAddress': {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'zip': _zipController.text.trim(),
        },
        'items': widget.cartItems.map((i) => i.toMap()).toList(),
        'subtotal': _subtotal,
        'shipping': _shipping,
        'tax': _tax,
        'total': _total,
        'paymentMethod': ['Credit/Debit Card', 'Cash on Delivery',
            'Digital Wallet'][_selectedPayment],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save order to Firestore
      await _firestore.collection('orders').doc(orderId).set(orderData);

      // If user is logged in, also save to their subcollection
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .set(orderData);

        // Save address for next time
        await _firestore.collection('users').doc(user.uid).update({
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'zip': _zipController.text.trim(),
        });
      }

      if (mounted) {
        _showSuccessDialog(orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check_circle, color: Colors.green, size: 44),
              ),
              const SizedBox(height: 18),
              Text('Order Placed!',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your order #${orderId.substring(0, 8).toUpperCase()} has been placed successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to shop
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Continue Shopping',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Checkout',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('${widget.cartItems.length} items in cart',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),

            // Step Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: _buildStepIndicator(),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _currentStep == 0
                        ? _buildDeliveryStep()
                        : _currentStep == 1
                            ? _buildPaymentStep()
                            : _buildReviewStep(),
                  ),
                ),
              ),
            ),

            // Bottom Action
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Step Indicator ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final steps = ['Delivery', 'Payment', 'Review'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < _currentStep
                  ? primaryColor
                  : Colors.grey.shade300,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex == _currentStep;
        final isDone = stepIndex < _currentStep;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? primaryColor
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${stepIndex + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? primaryColor : Colors.grey.shade500,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Step 1: Delivery ───────────────────────────────────────────────────────

  Widget _buildDeliveryStep() {
    return Column(
      key: const ValueKey('delivery'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Contact Information',
          icon: Icons.person_outline,
          children: [
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            _buildTextField(
                controller: _nameController,
                hint: 'John Doe',
                icon: Icons.person_outline,
                validator: (v) =>
                    v!.isEmpty ? 'Name is required' : null),
            const SizedBox(height: 16),
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            _buildTextField(
                controller: _emailController,
                hint: 'john@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v!.isEmpty ? 'Email is required' : null),
            const SizedBox(height: 16),
            _buildLabel('Phone Number'),
            const SizedBox(height: 8),
            _buildTextField(
                controller: _phoneController,
                hint: '+1 234 567 890',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.isEmpty ? 'Phone is required' : null),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Delivery Address',
          icon: Icons.location_on_outlined,
          children: [
            _buildLabel('Street Address'),
            const SizedBox(height: 8),
            _buildTextField(
                controller: _addressController,
                hint: '123 Main Street',
                icon: Icons.home_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Address is required' : null),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('City'),
                    const SizedBox(height: 8),
                    _buildTextField(
                        controller: _cityController,
                        hint: 'New York',
                        icon: Icons.location_city_outlined,
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('ZIP Code'),
                    const SizedBox(height: 8),
                    _buildTextField(
                        controller: _zipController,
                        hint: '10001',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v!.isEmpty ? 'Required' : null),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  // ── Step 2: Payment ────────────────────────────────────────────────────────

  Widget _buildPaymentStep() {
    final methods = [
      {'icon': Icons.credit_card, 'title': 'Credit / Debit Card', 'sub': 'Visa, Mastercard, Amex'},
      {'icon': Icons.money, 'title': 'Cash on Delivery', 'sub': 'Pay when you receive'},
      {'icon': Icons.account_balance_wallet_outlined, 'title': 'Digital Wallet', 'sub': 'Apple Pay, Google Pay'},
    ];

    return Column(
      key: const ValueKey('payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Payment Method',
          icon: Icons.payment,
          children: List.generate(
            methods.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPayment = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedPayment == i
                        ? primaryColor.withOpacity(0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedPayment == i
                          ? primaryColor
                          : Colors.grey.shade200,
                      width: _selectedPayment == i ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _selectedPayment == i
                              ? primaryColor.withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          methods[i]['icon'] as IconData,
                          color: _selectedPayment == i
                              ? primaryColor
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(methods[i]['title'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPayment == i
                                        ? primaryColor
                                        : Colors.grey.shade800)),
                            Text(methods[i]['sub'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedPayment == i
                                ? primaryColor
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          color: _selectedPayment == i
                              ? primaryColor
                              : Colors.transparent,
                        ),
                        child: _selectedPayment == i
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 12)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Review ─────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Items
        _buildSectionCard(
          title: 'Order Items',
          icon: Icons.shopping_bag_outlined,
          children: widget.cartItems
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey.shade100,
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.image_outlined,
                                        color: Colors.grey.shade400))
                                : Icon(Icons.image_outlined,
                                    color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('Qty: ${item.quantity}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Text(
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),

        // Delivery Summary
        _buildSectionCard(
          title: 'Delivery To',
          icon: Icons.location_on_outlined,
          children: [
            _reviewRow(Icons.person_outline, _nameController.text),
            const SizedBox(height: 6),
            _reviewRow(Icons.location_on_outlined,
                '${_addressController.text}, ${_cityController.text} ${_zipController.text}'),
            const SizedBox(height: 6),
            _reviewRow(Icons.phone_outlined, _phoneController.text),
          ],
        ),
        const SizedBox(height: 16),

        // Price Summary
        _buildSectionCard(
          title: 'Price Summary',
          icon: Icons.receipt_long_outlined,
          children: [
            _priceRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _priceRow(
                'Shipping',
                _shipping == 0
                    ? 'FREE'
                    : '\$${_shipping.toStringAsFixed(2)}',
                valueColor: _shipping == 0 ? Colors.green : null),
            const SizedBox(height: 8),
            _priceRow('Tax (8%)', '\$${_tax.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _priceRow('Total', '\$${_total.toStringAsFixed(2)}',
                isBold: true, valueColor: primaryColor),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14,
                color: isBold ? Colors.grey.shade800 : Colors.grey.shade600,
                fontWeight:
                    isBold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.grey.shade800)),
      ],
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => setState(() => _currentStep--),
              child: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    color: Colors.grey.shade700, size: 18),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentStep < 2) {
                          if (_currentStep == 0 &&
                              !_formKey.currentState!.validate()) return;
                          setState(() => _currentStep++);
                        } else {
                          _placeOrder();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _currentStep < 2
                            ? 'Continue  →'
                            : 'Place Order  \$${_total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}