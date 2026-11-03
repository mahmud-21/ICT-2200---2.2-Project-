import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/market_price.dart';

class MarketService {
  final FirebaseFirestore? _db;
  MarketService({FirebaseFirestore? firestore}) : _db = firestore;

  bool get _firebaseReady => _db != null;

  static final demoPrices = <MarketPrice>[
    // ── আলু (Potato) বিভিন্ন বাজারে বিভিন্ন নামে ও দামে ─────────────────────────────
    MarketPrice(
      id: 'demo_potato_1',
      vegetableId: 'potato',
      vegetableName: 'আলু',
      localName: 'দেশি সাদা আলু',
      marketName: 'সদর বাজার',
      district: 'ভোলা',
      wholesalePrice: 28,
      retailPrice: 35,
      updatedAt: DateTime(2026, 10, 31),
      source: 'বাজার পরিদর্শন',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_potato_2',
      vegetableId: 'potato',
      vegetableName: 'আলু',
      localName: 'কার্ডিনাল আলু',
      marketName: 'নতুন বাজার',
      district: 'ভোলা',
      wholesalePrice: 25,
      retailPrice: 32,
      updatedAt: DateTime(2026, 10, 31),
      source: 'পাইকারি আড়ত',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_potato_3',
      vegetableId: 'potato',
      vegetableName: 'আলু',
      localName: 'ডায়মন্ড লাল আলু',
      marketName: 'চকবাজার',
      district: 'ভোলা',
      wholesalePrice: 30,
      retailPrice: 38,
      updatedAt: DateTime(2026, 10, 31),
      source: 'পাইকারি আড়ত',
      availability: 'সীমিত মজুত',
    ),
    MarketPrice(
      id: 'demo_potato_4',
      vegetableId: 'potato',
      vegetableName: 'আলু',
      localName: 'বগুড়ার লাল আলু',
      marketName: 'কাওরান বাজার',
      district: 'ঢাকা',
      wholesalePrice: 32,
      retailPrice: 40,
      updatedAt: DateTime(2026, 10, 31),
      source: 'আড়তদার সমিতি',
      availability: 'সহজলভ্য',
    ),

    // ── লাউ / কদু (Bottle Gourd) বিভিন্ন বাজারে আঞ্চলিক নাম ────────────────────────
    MarketPrice(
      id: 'demo_gourd_1',
      vegetableId: 'bottle_gourd',
      vegetableName: 'লাউ',
      localName: 'লম্বা সবুজ লাউ',
      marketName: 'সদর বাজার',
      district: 'ভোলা',
      wholesalePrice: 40,
      retailPrice: 50,
      unit: 'টি',
      updatedAt: DateTime(2026, 10, 31),
      source: 'কৃষক বাজার',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_gourd_2',
      vegetableId: 'bottle_gourd',
      vegetableName: 'লাউ',
      localName: 'কদু (আঞ্চলিক নাম)',
      marketName: 'নতুন বাজার',
      district: 'ভোলা',
      wholesalePrice: 35,
      retailPrice: 45,
      unit: 'টি',
      updatedAt: DateTime(2026, 10, 31),
      source: 'পাইকারি আড়ত',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_gourd_3',
      vegetableId: 'bottle_gourd',
      vegetableName: 'লাউ',
      localName: 'গোল কদু',
      marketName: 'চকবাজার',
      district: 'ভোলা',
      wholesalePrice: 45,
      retailPrice: 55,
      unit: 'টি',
      updatedAt: DateTime(2026, 10, 31),
      source: 'বাজার প্রতিনিধি',
      availability: 'সীমিত মজুত',
    ),
    MarketPrice(
      id: 'demo_gourd_4',
      vegetableId: 'bottle_gourd',
      vegetableName: 'লাউ',
      localName: 'হাইব্রিড লাউ',
      marketName: 'মিরপুর ১ কাঁচাবাজার',
      district: 'ঢাকা',
      wholesalePrice: 50,
      retailPrice: 65,
      unit: 'টি',
      updatedAt: DateTime(2026, 10, 31),
      source: 'আড়তদার সমিতি',
      availability: 'অনুপলব্ধ',
    ),

    // ── বেগুন (Eggplant) বিভিন্ন বাজারে জাতভিত্তিক নাম ─────────────────────────────
    MarketPrice(
      id: 'demo_eggplant_1',
      vegetableId: 'eggplant',
      vegetableName: 'বেগুন',
      localName: 'গোল বেগুন',
      marketName: 'সদর বাজার',
      district: 'ভোলা',
      wholesalePrice: 45,
      retailPrice: 55,
      updatedAt: DateTime(2026, 10, 31),
      source: 'পাইকারি বাজার',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_eggplant_2',
      vegetableId: 'eggplant',
      vegetableName: 'বেগুন',
      localName: 'তাল বেগুন',
      marketName: 'নতুন বাজার',
      district: 'ভোলা',
      wholesalePrice: 55,
      retailPrice: 70,
      updatedAt: DateTime(2026, 10, 31),
      source: 'খুচরা দোকানদার',
      availability: 'সীমিত মজুত',
    ),
    MarketPrice(
      id: 'demo_eggplant_3',
      vegetableId: 'eggplant',
      vegetableName: 'বেগুন',
      localName: 'লম্বা কালো বেগুন',
      marketName: 'চকবাজার',
      district: 'ভোলা',
      wholesalePrice: 38,
      retailPrice: 48,
      updatedAt: DateTime(2026, 10, 31),
      source: 'আড়তদার সমিতি',
      availability: 'অনুপলব্ধ',
    ),

    // ── টমেটো (Tomato) ─────────────────────────────────────────────────────────────
    MarketPrice(
      id: 'demo_tomato_1',
      vegetableId: 'tomato',
      vegetableName: 'টমেটো',
      localName: 'হাইব্রিড পাকা টমেটো',
      marketName: 'সদর বাজার',
      district: 'ভোলা',
      wholesalePrice: 65,
      retailPrice: 80,
      updatedAt: DateTime(2026, 10, 31),
      source: 'পাইকারি আড়ত',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_tomato_2',
      vegetableId: 'tomato',
      vegetableName: 'টমেটো',
      localName: 'দেশি কাঁচা-পাকা টমেটো',
      marketName: 'নতুন বাজার',
      district: 'ভোলা',
      wholesalePrice: 75,
      retailPrice: 95,
      updatedAt: DateTime(2026, 10, 31),
      source: 'কৃষক প্রতিনিধি',
      availability: 'সীমিত মজুত',
    ),

    // ── মিষ্টি কুমড়া (Sweet Pumpkin / মিঠা কদু) ──────────────────────────────────
    MarketPrice(
      id: 'demo_pumpkin_1',
      vegetableId: 'pumpkin',
      vegetableName: 'মিষ্টি কুমড়া',
      localName: 'মিষ্টি কুমড়া',
      marketName: 'সদর বাজার',
      district: 'ভোলা',
      wholesalePrice: 30,
      retailPrice: 40,
      updatedAt: DateTime(2026, 10, 31),
      source: 'বাজার পরিদর্শন',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_pumpkin_2',
      vegetableId: 'pumpkin',
      vegetableName: 'মিষ্টি কুমড়া',
      localName: 'মিঠা কদু (আঞ্চলিক নাম)',
      marketName: 'নতুন বাজার',
      district: 'ভোলা',
      wholesalePrice: 28,
      retailPrice: 36,
      updatedAt: DateTime(2026, 10, 31),
      source: 'পাইকারি আড়ত',
      availability: 'সহজলভ্য',
    ),

    // ── পেঁয়াজ (Onion) ─────────────────────────────────────────────────────────────
    MarketPrice(
      id: 'demo_onion_1',
      vegetableId: 'onion',
      vegetableName: 'পেঁয়াজ',
      localName: 'দেশি পেঁয়াজ',
      marketName: 'সদর বাজার',
      district: 'ভোলা',
      wholesalePrice: 75,
      retailPrice: 90,
      updatedAt: DateTime(2026, 10, 31),
      source: 'আড়তদার সমিতি',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_onion_2',
      vegetableId: 'onion',
      vegetableName: 'পেঁয়াজ',
      localName: 'ভারতীয় নাসিক পেঁয়াজ',
      marketName: 'নতুন বাজার',
      district: 'ভোলা',
      wholesalePrice: 65,
      retailPrice: 78,
      updatedAt: DateTime(2026, 10, 31),
      source: 'আমদানিকারক',
      availability: 'সহজলভ্য',
    ),
    MarketPrice(
      id: 'demo_onion_3',
      vegetableId: 'onion',
      vegetableName: 'পেঁয়াজ',
      localName: 'লাল পেঁয়াজ',
      marketName: 'চকবাজার',
      district: 'ভোলা',
      wholesalePrice: 70,
      retailPrice: 85,
      updatedAt: DateTime(2026, 10, 31),
      source: 'খুচরা বিক্রেতা',
      availability: 'অনুপলব্ধ',
    ),
  ];

  Stream<List<MarketPrice>> watchPrices() {
    if (!_firebaseReady) return Stream.value(demoPrices);
    return _db!.collection('market_prices').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return demoPrices;
      }
      return snapshot.docs.map((d) => MarketPrice.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> savePrice(MarketPrice price) async {
    if (!_firebaseReady) {
      throw StateError('Firebase is not configured. Follow README.md first.');
    }
    final data = price.toMap();
    data['updatedAt'] = DateTime.now().toIso8601String();

    // If id is 'new', empty, or starts with 'demo', create a NEW document auto-generated by Firestore
    if (price.id == 'new' || price.id.isEmpty || price.id.startsWith('demo')) {
      await _db!.collection('market_prices').add(data);
    } else {
      await _db!.collection('market_prices').doc(price.id).set(data);
    }
  }

  Future<void> deletePrice(String id) async {
    if (!_firebaseReady) {
      throw StateError('Firebase is not configured. Follow README.md first.');
    }
    await _db!.collection('market_prices').doc(id).delete();
  }

  /// Seeds initial demo prices into Firebase Firestore collection
  Future<int> seedDemoData() async {
    final db = _db;
    if (db == null) {
      throw StateError('Firebase is not configured.');
    }
    final batch = db.batch();
    final collection = db.collection('market_prices');

    for (final price in demoPrices) {
      final docRef = collection.doc();
      final data = price.toMap();
      data['source'] = 'ফায়ারবেস তথ্য';
      data['updatedAt'] = DateTime.now().toIso8601String();
      batch.set(docRef, data);
    }

    await batch.commit();
    return demoPrices.length;
  }
}
