import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/core/routes/app_routes.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';

class ConfirmationScreen extends StatefulWidget {
  final String? orderId;
  const ConfirmationScreen({super.key, this.orderId});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? orderData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      if (widget.orderId != null) {
        final doc = await _firestore.collection('orders').doc(widget.orderId).get();
        if (doc.exists) {
          if (mounted) {
            setState(() {
              orderData = doc.data();
              isLoading = false;
            });
          }
          return;
        }
      }

      // Fallback: get the most recent order for this user
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final query = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty && mounted) {
          setState(() {
            orderData = query.docs.first.data();
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load order details: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Confirmation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderData == null
              ? _buildErrorState()
              : _buildSuccessState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Order not found',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find your order details',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue Shopping', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final order = orderData!;
    final items = order['items'] as List? ?? [];
    final total = (order['total'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 50, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          Text(
            'Order Placed Successfully!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your purchase',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Order Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                    Text(
                      widget.orderId ?? order['orderId'] ?? 'N/A',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Method', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                    Text('Cash on Delivery', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Date', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                    Text(
                      _formatDate(order['createdAt']),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order Items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...items.map((item) => _buildOrderItem(item)),
                const Divider(height: 24, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Delivery Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery Address', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(order['shippingAddress'] ?? 'No address provided', style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 8),
                Text('Phone: ${order['phone'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Continue Shopping Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Continue Shopping', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['imageUrl'] ?? '',
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
                Text(item['name'] ?? 'Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                Text('Quantity: ${item['quantity'] ?? 1}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '\$${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    }
    if (dt == null) return 'Just now';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}