import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeedProducts {
  static final _firestore = FirebaseFirestore.instance;

static final List<Map<String, dynamic>> _products = [
    // ==========================================
    // CATEGORY: Men's footwear (5 Items)
    // ==========================================
    {
      "title": "Nike Air Max Running Shoes",
      "price": 140.00,
      "image": "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&q=80",
      "description": "Lightweight, breathable mesh running shoes with premium impact cushioning and responsive sole traction for daily athletic performance.",
      "category": "Men's footwear",
      "rating": 4.5,
    },
    {
      "title": "Classic White Urban Sneakers",
      "price": 85.00,
      "image": "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&q=80",
      "description": "Minimalist aesthetic low-top sneakers crafted with premium synthetic leather and a durable rubber cupsole for everyday casual wear.",
      "category": "Men's footwear",
      "rating": 4.3,
    },
    {
      "title": "Waterproof Rugged Leather Boots",
      "price": 165.00,
      "image": "https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=600&q=80",
      "description": "Heavy-duty, weather-resistant outdoor boots featuring reinforced seam-sealed construction and deep lugged soles for maximum terrain grip.",
      "category": "Men's footwear",
      "rating": 4.7,
    },
    {
      "title": "Sport Performance Trainer Shoes",
      "price": 110.00,
      "image": "https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=600&q=80",
      "description": "High-impact cross-training shoes engineered with a stabilizing heel counter and dynamic knit upper for intense workout routines.",
      "category": "Men's footwear",
      "rating": 4.4,
    },
    {
      "title": "Premium Suede Casual Loafers",
      "price": 95.00,
      "image": "https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=600&q=80",
      "description": "Sophisticated slip-on loafers crafted from soft genuine suede leather, featuring a cushioned footbed for seamless smart-casual styling.",
      "category": "Men's footwear",
      "rating": 4.2,
    },

    // ==========================================
    // CATEGORY: Men's outfit (5 Items)
    // ==========================================
    {
      "title": "Mens Casual Slim Fit Denim Jacket",
      "price": 78.00,
      "image": "https://images.unsplash.com/photo-1611312449412-6cefac5dc3e4?w=600&q=80",
      "description": "Classic vintage-wash button-up denim jacket made from high-quality stretch cotton blend with functional utility chest pockets.",
      "category": "Men's outfit",
      "rating": 4.2,
    },
    {
      "title": "Premium Essentials Black Tee",
      "price": 28.00,
      "image": "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&q=80",
      "description": "Ultra-soft, heavyweight combed cotton crewneck t-shirt designed for a relaxed, breathable fit that retains its shape wash after wash.",
      "category": "Men's outfit",
      "rating": 4.4,
    },
    {
      "title": "Classic Plaid Flannel Shirt",
      "price": 45.00,
      "image": "https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600&q=80",
      "description": "Warm, brushed cotton flannel button-down shirt featuring a relaxed traditional fit, adjustable cuffs, and dual chest utility pockets.",
      "category": "Men's outfit",
      "rating": 4.5,
    },
    {
      "title": "Urban Fleece Pullover Hoodie",
      "price": 55.00,
      "image": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=600&q=80",
      "description": "Premium cotton-blend streetwear hoodie with a soft brushed fleece interior, adjustable drawstring hood, and kangaroo front pocket.",
      "category": "Men's outfit",
      "rating": 4.6,
    },
    {
      "title": "Slim Fit Stretch Chino Pants",
      "price": 49.99,
      "image": "https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600&q=80",
      "description": "Versatile lightweight chino pants woven with a touch of elastane for optimal mobility, clean tailored design suitable for work or weekend.",
      "category": "Men's outfit",
      "rating": 4.1,
    },

    // ==========================================
    // CATEGORY: Woman's outfit (5 Items)
    // ==========================================
    {
      "title": "Summer Floral A-Line Dress",
      "price": 59.99,
      "image": "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&q=80",
      "description": "Lightweight, flowing sleeveless summer dress with a vibrant floral pattern, fitted waist, and a breezy pleated dynamic silhouette.",
      "category": "Woman's outfit",
      "rating": 4.7,
    },
    {
      "title": "Cozy Knit Oversized Sweater",
      "price": 64.00,
      "image": "https://images.unsplash.com/photo-1614975058789-41316d0e2e9c?w=600&q=80",
      "description": "Exceptionally soft, chunky-knit crewneck sweater styled with dropped shoulders and ribbed cuffs for a perfect relaxed winter aesthetic.",
      "category": "Woman's outfit",
      "rating": 4.6,
    },
    {
      "title": "Classic Leather Biker Jacket",
      "price": 120.00,
      "image": "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&q=80",
      "description": "Edgy tailored asymmetrical zip biker jacket crafted from premium faux-leather with polished metallic hardware accents.",
      "category": "Woman's outfit",
      "rating": 4.8,
    },
    {
      "title": "High-Waisted Tailored Trousers",
      "price": 52.00,
      "image": "https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600&q=80",
      "description": "Elegant high-rise wide-leg trousers featuring front pleat detailing, side slip pockets, and a clean concealed hook-and-eye closure.",
      "category": "Woman's outfit",
      "rating": 4.3,
    },
    {
      "title": "Minimalist Linen Blend Blouse",
      "price": 38.00,
      "image": "https://images.unsplash.com/photo-1548624149-f7b316629918?w=600&q=80",
      "description": "Breathable, loose-fit structural blouse made from premium eco-friendly linen blend fabric, featuring a relaxed V-neck cut.",
      "category": "Woman's outfit",
      "rating": 4.4,
    },

    // ==========================================
    // CATEGORY: Accessories (5 Items)
    // ==========================================
    {
      "title": "Vintage Canvas Travel Backpack",
      "price": 89.00,
      "image": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&q=80",
      "description": "Durable water-resistant canvas rucksack featuring genuine leather strap accents, a padded 15-inch laptop sleeve, and quick-access side pockets.",
      "category": "Accessories",
      "rating": 4.6,
    },
    {
      "title": "Classic Aviator Sunglasses",
      "price": 35.00,
      "image": "https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=600&q=80",
      "description": "Timeless metal-framed aviator sunglasses engineered with polarized impact-resistant lenses providing complete UV400 optical protection.",
      "category": "Accessories",
      "rating": 4.4,
    },
    {
      "title": "Minimalist Matte Wristwatch",
      "price": 115.00,
      "image": "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&q=80",
      "description": "Sleek architectural timepiece featuring a genuine black leather strap, quartz crystal analog movement, and a matte dark casing finish.",
      "category": "Accessories",
      "rating": 4.5,
    },
    {
      "title": "Premium Full Grain Leather Wallet",
      "price": 42.00,
      "image": "https://images.unsplash.com/photo-1627123424574-724758594e93?w=600&q=80",
      "description": "Slim bifold wallet artisanally constructed from genuine vegetable-tanned leather, equipped with integrated advanced RFID blocking technology.",
      "category": "Accessories",
      "rating": 4.7,
    },
    {
      "title": "Insulated Stainless Steel Bottle",
      "price": 26.00,
      "image": "https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=600&q=80",
      "description": "Double-walled vacuum insulated thermal flask capable of keeping beverages ice-cold for up to 24 hours or steaming hot for up to 12 hours.",
      "category": "Accessories",
      "rating": 4.8,
    },
  ];

  /// Call this once from your app to seed Firestore.
  /// After seeding, remove the call — running it twice creates duplicates.
  static Future<void> seed() async {
    final batch = _firestore.batch();
    for (final product in _products) {
      final ref = _firestore.collection('products').doc();
      batch.set(ref, product);
    }
    await batch.commit();
    debugPrint('Seeded ${_products.length} products.');
  }
}
