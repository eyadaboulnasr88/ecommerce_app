import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  Future<void> addToCart({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    int quantity = 1,
  }) async {
    if (userId.isEmpty) return;

    final existingCart = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .get();

    if (existingCart.docs.isNotEmpty) {
      final cartDoc = existingCart.docs.first;
      final currentQuantity = cartDoc.data()['quantity'] ?? 1;
      await cartDoc.reference.update({
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('carts').add({
        'userId': userId,
        'productId': productId,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFromCart(String cartId) async {
    await _firestore.collection('carts').doc(cartId).delete();
  }

  Future<void> updateQuantity(String cartId, int quantity) async {
    if (quantity < 1) {
      await removeFromCart(cartId);
      return;
    }
    await _firestore.collection('carts').doc(cartId).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getCartItems() {
    return _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<double> getCartTotal() async {
    final cartItems = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .get();

    double total = 0;
    for (var item in cartItems.docs) {
      final data = item.data();
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }

  Future<void> clearCart() async {
    final cartItems = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in cartItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<int> getCartItemCount() async {
    final cartItems = await _firestore
        .collection('carts')
        .where('userId', isEqualTo: userId)
        .get();
    return cartItems.docs.length;
  }
}