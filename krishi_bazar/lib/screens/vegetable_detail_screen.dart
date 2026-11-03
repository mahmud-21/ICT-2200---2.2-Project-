import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/market_price.dart';
import '../services/ai_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../utils/bengali_formatter.dart';

/// Full detail screen for a detected/selected vegetable.
///
/// Shows:
///   • Scanned Vegetable Photo
///   • Bengali & English name
///   • Scientific name
///   • Nutrition info
///   • Bangladesh growing season + best month
///   • Uses and culinary/medicinal benefits
///   • Live Firebase market prices (only if available; never fabricated)
class VegetableDetailScreen extends StatefulWidget {
  final VegetableResult result;
  final Uint8List? imageBytes;
  final String? imageBase64;

  const VegetableDetailScreen({
    super.key,
    required this.result,
    this.imageBytes,
    this.imageBase64,
  });

  @override
  State<VegetableDetailScreen> createState() => _VegetableDetailScreenState();
}

class _VegetableDetailScreenState extends State<VegetableDetailScreen> {
  late final MarketService _marketService;
  Uint8List? _resolvedImageBytes;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore? db;
    try {
      db = FirebaseFirestore.instance;
    } catch (_) {
      db = null;
    }
    _marketService = MarketService(firestore: db);

    if (widget.imageBytes != null) {
      _resolvedImageBytes = widget.imageBytes;
    } else if (widget.imageBase64 != null && widget.imageBase64!.isNotEmpty) {
      try {
        _resolvedImageBytes = base64Decode(widget.imageBase64!);
      } catch (_) {}
    }
  }

  /// Filters market prices that match this vegetable:
  /// Matches Bengali name, English name, vegetableId, localName, and regional synonyms.
  List<MarketPrice> _filterPrices(List<MarketPrice> all) {
    final bnName = widget.result.vegetableNameBengali.trim().toLowerCase();
    final enName = widget.result.vegetableNameEnglish.trim().toLowerCase();
    final regName = widget.result.regionalNamesBengali.trim().toLowerCase();

    // Synonyms and regional naming mapping
    final synonyms = <String>{bnName, enName};
    if (bnName.contains('লাউ') || enName.contains('gourd') || regName.contains('কদু')) {
      synonyms.addAll(['লাউ', 'কদু', 'bottle_gourd', 'gourd']);
    }
    if (bnName.contains('আলু') || enName.contains('potato')) {
      synonyms.addAll(['আলু', 'potato', 'কার্ডিনাল', 'ডায়মন্ড', 'লাল আলু']);
    }
    if (bnName.contains('বেগুন') || enName.contains('eggplant') || enName.contains('brinjal')) {
      synonyms.addAll(['বেগুন', 'eggplant', 'brinjal', 'তাল বেগুন', 'গোল বেগুন', 'লম্বা বেগুন']);
    }
    if (bnName.contains('কুমড়া') || enName.contains('pumpkin')) {
      synonyms.addAll(['মিষ্টি কুমড়া', 'মিঠা কদু', 'pumpkin']);
    }
    if (bnName.contains('মরিচ') || enName.contains('chili') || enName.contains('pepper')) {
      synonyms.addAll(['কাঁচামরিচ', 'মরিচ', 'ঝাল', 'chili']);
    }
    if (bnName.contains('টমেটো') || enName.contains('tomato')) {
      synonyms.addAll(['টমেটো', 'tomato']);
    }
    if (bnName.contains('পেঁয়াজ') || enName.contains('onion')) {
      synonyms.addAll(['পেঁয়াজ', 'onion']);
    }

    return all.where((p) {
      final pName = p.vegetableName.trim().toLowerCase();
      final pLocal = p.localName.trim().toLowerCase();
      final pId = p.vegetableId.trim().toLowerCase();

      for (final s in synonyms) {
        if (s.isEmpty) continue;
        if (pName.contains(s) || s.contains(pName) ||
            pLocal.contains(s) || s.contains(pLocal) ||
            pId.contains(s) || s.contains(pId)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final hasImage = _resolvedImageBytes != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: hasImage ? 260 : 200,
            pinned: true,
            backgroundColor: AppTheme.green,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.memory(
                      _resolvedImageBytes!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF176B45), Color(0xFF2D9463)],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: hasImage ? 0.35 : 0.0),
                          Colors.black.withValues(alpha: hasImage ? 0.85 : 0.4),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!hasImage)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 36),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          r.vegetableNameBengali,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                        Text(
                          r.vegetableNameEnglish,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body content ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Confidence badge + scientific name row
                Row(
                  children: [
                    _badge(
                      icon: Icons.verified_rounded,
                      label: 'নিশ্চয়তা: ${r.confidence}',
                      color: AppTheme.green,
                    ),
                    const SizedBox(width: 8),
                    if (r.scientificName.isNotEmpty)
                      Expanded(
                        child: _badge(
                          icon: Icons.science_outlined,
                          label: r.scientificName,
                          color: Colors.indigo,
                          italic: true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── General description ──────────────────────────────────────
                if (r.detailsBengali.isNotEmpty) ...[
                  _sectionHeader(Icons.info_outline_rounded, 'পরিচয় ও বিবরণ'),
                  const SizedBox(height: 8),
                  _infoCard(
                    child: Text(
                      r.detailsBengali,
                      style: const TextStyle(height: 1.6, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Nutrition ────────────────────────────────────────────────
                if (r.nutritionBengali.isNotEmpty) ...[
                  _sectionHeader(Icons.restaurant_menu_rounded, 'পুষ্টিগুণ ও স্বাস্থ্য উপকারিতা'),
                  const SizedBox(height: 8),
                  _infoCard(
                    accentColor: Colors.orange,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lunch_dining_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.nutritionBengali,
                            style: const TextStyle(height: 1.6, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Uses and Benefits ────────────────────────────────────────
                if (r.usesBengali.isNotEmpty) ...[
                  _sectionHeader(Icons.soup_kitchen_rounded, 'ব্যবহার ও রন্ধনপ্রণালী'),
                  const SizedBox(height: 8),
                  _infoCard(
                    accentColor: Colors.deepPurple,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, color: Colors.deepPurple, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.usesBengali,
                            style: const TextStyle(height: 1.6, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Regional & Alternative Names in Markets ────────────────
                if (r.regionalNamesBengali.isNotEmpty) ...[
                  _sectionHeader(Icons.label_outline_rounded, 'বিভিন্ন বাজারে আঞ্চলিক ও বিকল্প নাম'),
                  const SizedBox(height: 8),
                  _infoCard(
                    accentColor: Colors.indigo,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.store_mall_directory_outlined, color: Colors.indigo, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.regionalNamesBengali,
                            style: const TextStyle(height: 1.6, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ── Growing season (Bangladesh) ──────────────────────────────
                if (r.growingSeasonBengali.isNotEmpty || r.bestMonthBengali.isNotEmpty) ...[
                  _sectionHeader(Icons.calendar_month_rounded, 'বাংলাদেশে চাষের সময় ও মৌসুম'),
                  const SizedBox(height: 8),
                  _infoCard(
                    accentColor: Colors.teal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.growingSeasonBengali.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.date_range_rounded, color: Colors.teal, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'উপযুক্ত চাষের মৌসুম',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      r.growingSeasonBengali,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (r.growingSeasonBengali.isNotEmpty && r.bestMonthBengali.isNotEmpty)
                          const Divider(height: 20),
                        if (r.bestMonthBengali.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'সেরা বপন / চারা রোপণের মাস',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      r.bestMonthBengali,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Market prices & Comparison across markets ───────────────
                _sectionHeader(Icons.compare_arrows_rounded, 'বিভিন্ন বাজারে নাম, দাম ও মজুত তুলনা'),
                const SizedBox(height: 8),

                StreamBuilder<List<MarketPrice>>(
                  stream: _marketService.watchPrices(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final all = snapshot.data ?? [];
                    final matched = _filterPrices(all);

                    if (matched.isEmpty) {
                      return _noPriceCard();
                    }

                    // Sort by retail price ascending so cheapest market comes first
                    matched.sort((a, b) => a.retailPrice.compareTo(b.retailPrice));

                    return _buildComparisonSection(matched);
                  },
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: AppTheme.green, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
        ],
      );

  Widget _infoCard({required Widget child, Color accentColor = AppTheme.green}) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
    bool italic = false,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _noPriceCard() => Card(
        elevation: 0,
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.amber.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.result.vegetableNameBengali}-এর বাজারদর পাওয়া যায়নি',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'এই সবজির দাম এখনো ডেটাবেজে যোগ করা হয়নি। অ্যাডমিন প্যানেল থেকে দাম যোগ করুন।',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildComparisonSection(List<MarketPrice> list) {
    final minPrice = list.first.retailPrice;
    final minMarket = list.first.marketName;
    final maxPrice = list.last.retailPrice;
    final maxMarket = list.last.marketName;
    final savings = maxPrice - minPrice;

    final inStockCount = list.where((p) => p.availability == 'সহজলভ্য').length;
    final limitedCount = list.where((p) => p.availability == 'সীমিত মজুত').length;
    final outOfStockCount = list.where((p) => p.availability == 'অনুপলব্ধ').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary Comparison Card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${BengaliFormatter.toBengaliDigits(list.length)}টি বাজারে তুলনামূলক বাজারদর ও মজুত',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সর্বনিম্ন দাম',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            BengaliFormatter.formatPrice(minPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            minMarket,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সর্বোচ্চ সাশ্রয়',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            savings > 0 ? '৳${savings.toInt()} / ${list.first.unit}' : 'একই দাম',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            savings > 0 ? '$maxMarket-এর তুলনায়' : 'সকল বাজারে',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (inStockCount > 0)
                    _stockPill('সহজলভ্য: $inStockCount টি বাজার', Colors.greenAccent),
                  if (limitedCount > 0)
                    _stockPill('সীমিত মজুত: $limitedCount টি বাজার', Colors.amberAccent),
                  if (outOfStockCount > 0)
                    _stockPill('অনুপলব্ধ: $outOfStockCount টি বাজার', Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Individual Market Cards ──────────────────────────────────────────
        ...list.map((p) {
          final isBestPrice = p.retailPrice == minPrice;
          final diff = (p.retailPrice - minPrice).toInt();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isBestPrice ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isBestPrice ? AppTheme.green : Colors.grey.shade200,
                width: isBestPrice ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Market Title & Stock Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: AppTheme.green, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            p.marketName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${p.district})',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      _availabilityBadge(p.availability),
                    ],
                  ),

                  // Different Name in this market
                  if (p.localName.isNotEmpty && p.localName.trim() != p.vegetableName.trim()) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.label_important_outline, size: 14, color: Colors.indigo),
                          const SizedBox(width: 6),
                          Text(
                            'এই বাজারে প্রচলিত নাম: "${p.localName}"',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Prices Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('খুচরা মূল্য', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(
                            '${BengaliFormatter.formatPrice(p.retailPrice)} / ${p.unit}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('পাইকারি মূল্য', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(
                            '${BengaliFormatter.formatPrice(p.wholesalePrice)} / ${p.unit}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (isBestPrice)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.emoji_events_rounded, color: Colors.green, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'সেরা দাম',
                                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else if (diff > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+৳$diff পার্থক্য',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _stockPill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );

  Widget _availabilityBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'সীমিত মজুত':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        icon = Icons.hourglass_top_rounded;
        break;
      case 'অনুপলব্ধ':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        break;
      case 'সহজলভ্য':
      default:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
