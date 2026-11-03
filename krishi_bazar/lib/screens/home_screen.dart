
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/market_price.dart';
import '../services/ai_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../utils/bengali_formatter.dart';
import '../widgets/price_card.dart';
import 'admin_screen.dart';
import 'price_comparison_screen.dart';
import 'scan_screen.dart';
import 'vegetable_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _search = '';
  String _selectedDistrict = 'সকল জেলা';
  String _sortBy = 'latest';

  final TextEditingController _searchController =
  TextEditingController();

  late final MarketService _service;

  @override
  void initState() {
    super.initState();

    FirebaseFirestore? db;
    try {
      db = FirebaseFirestore.instance;
    } catch (_) {
      db = null;
    }

    _service = MarketService(firestore: db);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onVegetableRecognized(String vegetableName) {
    setState(() {
      _search = vegetableName;
      _searchController.text = vegetableName;
      _tab = 0;
    });
  }

  /// Tap on a PriceCard → open VegetableDetailScreen with basic info
  void _openDetailFromPrice(MarketPrice price) {
    final result = VegetableResult(
      isVegetable: true,
      vegetableNameBengali: price.vegetableName,
      vegetableNameEnglish: price.vegetableId,
      confidence: 'Firebase ডেটা',
      detailsBengali: '',
      // Scientific name / nutrition / season: will be blank until user scans an image.
      // They are shown only when available.
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VegetableDetailScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.eco_rounded,
              color: AppTheme.green,
              size: 30,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কৃষি বাজার',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                  ),
                ),
                Text(
                  'সবজির দাম, হাতের মুঠোয়',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'অ্যাডমিন',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.admin_panel_settings_outlined,
            ),
          ),
        ],
      ),
      body: _tab == 1
          ? ScanScreen(
        onSelectVegetableForPrice: _onVegetableRecognized,
      )
          : _tab == 2
          ? PriceComparisonScreen(stream: _service.watchPrices())
          : _tab == 3
          ? const _InfoScreen()
          : _homeBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) {
          setState(() => _tab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'সবজি চিনুন',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_rounded),
            selectedIcon: Icon(Icons.compare_arrows_rounded),
            label: 'দাম তুলনা',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'আমাদের কথা',
          ),
        ],
      ),
    );
  }

  Widget _homeBody() {
    return StreamBuilder<List<MarketPrice>>(
      stream: _service.watchPrices(),
      builder: (context, snapshot) {
        final prices =
            snapshot.data ?? MarketService.demoPrices;

        final districts = <String>{
          'সকল জেলা',
          ...prices.map((p) => p.district),
        };

        final filtered = prices.where((p) {
          final query = _search.trim().toLowerCase();

          final matchesSearch =
              p.vegetableName.toLowerCase().contains(query) ||
                  p.marketName.toLowerCase().contains(query) ||
                  p.vegetableId.toLowerCase().contains(query);

          final matchesDistrict =
              _selectedDistrict == 'সকল জেলা' ||
                  p.district == _selectedDistrict;

          return matchesSearch && matchesDistrict;
        }).toList();

        if (_sortBy == 'latest') {
          filtered.sort(
                (a, b) => b.updatedAt.compareTo(a.updatedAt),
          );
        } else if (_sortBy == 'price_asc') {
          filtered.sort(
                (a, b) => a.retailPrice.compareTo(b.retailPrice),
          );
        } else if (_sortBy == 'price_desc') {
          filtered.sort(
                (a, b) => b.retailPrice.compareTo(a.retailPrice),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF176B45),
                      Color(0xFF2D9463),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'আজকের বাজারদর জানুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'বিভিন্ন বাজারের পাইকারি ও খুচরা দাম এক জায়গায়।',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.green,
                      ),
                      onPressed: () {
                        setState(() => _tab = 1);
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('ছবি দিয়ে সবজি চিনুন'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _search = value);
                },
                decoration: InputDecoration(
                  hintText: 'সবজি বা বাজারের নাম লিখুন...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 12),

              // District filter
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: districts.map((district) {
                    final isSelected =
                        _selectedDistrict == district;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(district),
                        selected: isSelected,
                        selectedColor: AppTheme.lightGreen,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.green
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDistrict = district;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Price list heading and sorting menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'বাজারদরের তালিকা '
                          '(${BengaliFormatter.toBengaliDigits(filtered.length)}টি)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    initialValue: _sortBy,
                    icon: const Icon(
                      Icons.sort_rounded,
                      color: AppTheme.green,
                    ),
                    tooltip: 'সর্ট করুন',
                    onSelected: (value) {
                      setState(() => _sortBy = value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'latest',
                        child: Text('সর্বশেষ আপডেট'),
                      ),
                      const PopupMenuItem(
                        value: 'price_asc',
                        child: Text('দাম: কম থেকে বেশি'),
                      ),
                      const PopupMenuItem(
                        value: 'price_desc',
                        child: Text('দাম: বেশি থেকে কম'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (snapshot.hasError)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'ডেটা লোড করা যায়নি। '
                        'Firebase সেটআপ ও Internet পরীক্ষা করুন।',
                  ),
                ),

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 52,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _search.isNotEmpty
                              ? '"$_search" সম্পর্কিত কোনো বাজারদর পাওয়া যায়নি।'
                              : 'এই ফিল্টারে কোনো বাজারদর পাওয়া যায়নি।',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map(
                      (price) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PriceCard(
                      price: price,
                      onTap: () => _openDetailFromPrice(price),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              const Text(
                'নোট: Firebase সেটআপের আগে দেখানো দামগুলো নমুনা '
                    '(demo) তথ্য। এগুলোকে বর্তমান বাস্তব বাজারদর মনে করবেন না।',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoScreen extends StatelessWidget {
  const _InfoScreen();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Icon(
          Icons.eco_rounded,
          color: AppTheme.green,
          size: 70,
        ),
        const SizedBox(height: 12),
        const Text(
          'কৃষি বাজার সম্পর্কে',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'কৃষি বাজার একটি কৃত্রিম বুদ্ধিমত্তা (AI) চালিত মোবাইল অ্যাপ। '
              'ছবি তুললেই সবজির নাম, বৈজ্ঞানিক নাম, পুষ্টিগুণ ও চাষের মৌসুম '
              'শনাক্ত করা যায় এবং Firebase থেকে লাইভ বাজারদর দেখা যায়।',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.7),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌿 সুবিধাসমূহ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                _FeatureRow(icon: Icons.camera_alt_outlined, text: 'ছবি দিয়ে সবজি শনাক্তকরণ'),
                _FeatureRow(icon: Icons.science_outlined, text: 'বৈজ্ঞানিক নাম প্রদর্শন'),
                _FeatureRow(icon: Icons.restaurant_menu_rounded, text: 'পুষ্টিগুণ বিশ্লেষণ'),
                _FeatureRow(icon: Icons.calendar_month_rounded, text: 'বাংলাদেশে চাষের মৌসুম'),
                _FeatureRow(icon: Icons.storefront_rounded, text: 'Firebase থেকে লাইভ বাজারদর'),
                _FeatureRow(icon: Icons.compare_arrows_rounded, text: 'বিভিন্ন বাজারের দাম তুলনা'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'বাজারদর পরিবর্তনশীল। তথ্যের উৎস ও আপডেটের সময় যাচাই করুন। '
                  'ডেমোতে দেখানো নমুনা দাম বাস্তব বাজারদরের নিশ্চয়তা নয়।',
              style: TextStyle(height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.green, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
