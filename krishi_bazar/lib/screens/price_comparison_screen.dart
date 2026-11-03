import 'package:flutter/material.dart';

import '../models/market_price.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../utils/bengali_formatter.dart';

class PriceComparisonScreen extends StatefulWidget {
  final Stream<List<MarketPrice>> stream;

  const PriceComparisonScreen({super.key, required this.stream});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  String? _selectedVegetableKey;
  String _selectedDistrict = 'সকল জেলা';
  bool _showRetailPrice = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketPrice>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        final prices = snapshot.data ?? MarketService.demoPrices;
        final options = _buildOptions(prices);

        if (options.isEmpty) {
          return const Center(child: Text('তুলনা করার মতো বাজারদর নেই।'));
        }

        final selectedOption = options.firstWhere(
          (option) => option.key == _selectedVegetableKey,
          orElse: () => options.first,
        );
        final districts = <String>{
          'সকল জেলা',
          ...prices
              .where((price) =>
                  price.vegetableId == selectedOption.vegetableId &&
                  price.unit == selectedOption.unit)
              .map((price) => price.district),
        };
        final selectedDistrict = districts.contains(_selectedDistrict)
            ? _selectedDistrict
            : 'সকল জেলা';
        final comparisons = prices
            .where(
              (price) =>
                  price.vegetableId == selectedOption.vegetableId &&
                  price.unit == selectedOption.unit &&
                  (selectedDistrict == 'সকল জেলা' ||
                      price.district == selectedDistrict),
            )
            .toList()
          ..sort(
            (a, b) {
              final availability = (a.availability == 'অনুপলব্ধ' ? 1 : 0)
                  .compareTo(b.availability == 'অনুপলব্ধ' ? 1 : 0);
              return availability != 0
                  ? availability
                  : _priceFor(a).compareTo(_priceFor(b));
            },
          );
        final availablePrices = comparisons
            .where((price) => price.availability != 'অনুপলব্ধ')
            .toList();
        final cheapest = availablePrices.isEmpty
            ? null
            : availablePrices.reduce(
                (a, b) => _priceFor(a) <= _priceFor(b) ? a : b,
              );
        final priceValues = availablePrices.map(_priceFor).toList();
        final difference = priceValues.isEmpty
            ? null
            : priceValues.reduce((a, b) => a > b ? a : b) -
                priceValues.reduce((a, b) => a < b ? a : b);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const Text(
              'বাজারভেদে দামের তুলনা',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'একই সবজির বিভিন্ন বাজারের দাম পাশাপাশি দেখুন।',
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedOption.key),
              initialValue: selectedOption.key,
              decoration: const InputDecoration(
                labelText: 'সবজি নির্বাচন করুন',
                prefixIcon: Icon(Icons.eco_outlined),
              ),
              items: options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.key,
                      child: Text('${option.name} · প্রতি ${option.unit}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedVegetableKey = value;
                  _selectedDistrict = 'সকল জেলা';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedDistrict),
              initialValue: selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'জেলা',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: districts
                  .map(
                    (district) => DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDistrict = value);
                }
              },
            ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('খুচরা দাম')),
                ButtonSegment(value: false, label: Text('পাইকারি দাম')),
              ],
              selected: {_showRetailPrice},
              onSelectionChanged: (selection) {
                setState(() => _showRetailPrice = selection.first);
              },
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: 12),
              const Text(
                'সর্বশেষ বাজারদরের তথ্য লোড করা যায়নি।',
                style: TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 18),
            if (difference != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, color: AppTheme.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'বাজারভেদে সর্বোচ্চ পার্থক্য '
                        '৳${_formatPrice(difference)} প্রতি ${selectedOption.unit}',
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'বাজারের দাম (${BengaliFormatter.toBengaliDigits(comparisons.length)}টি)',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (comparisons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'এই সবজির জন্য নির্বাচিত জেলায় কোনো বাজারদর নেই।',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...comparisons.map(
                (price) => _MarketComparisonCard(
                  price: price,
                  amount: _priceFor(price),
                  isCheapest: cheapest?.id == price.id,
                  isRetail: _showRetailPrice,
                  unit: selectedOption.unit,
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'দাম তুলনার সময় একই একক ও নির্বাচিত দাম (খুচরা/পাইকারি) ব্যবহার করা হয়েছে। '
              'নমুনা তথ্য বাস্তব বাজারদর নাও হতে পারে।',
              style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
            ),
          ],
        );
      },
    );
  }

  List<_VegetableOption> _buildOptions(List<MarketPrice> prices) {
    final options = <String, _VegetableOption>{};
    for (final price in prices) {
      final key = '${price.vegetableId}\u0000${price.unit}';
      options.putIfAbsent(
        key,
        () => _VegetableOption(
          key: key,
          vegetableId: price.vegetableId,
          name: price.vegetableName,
          unit: price.unit,
        ),
      );
    }
    return options.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  double _priceFor(MarketPrice price) =>
      _showRetailPrice ? price.retailPrice : price.wholesalePrice;

  String _formatPrice(double price) =>
      BengaliFormatter.toBengaliDigits(price.toStringAsFixed(0));
}

class _VegetableOption {
  final String key;
  final String vegetableId;
  final String name;
  final String unit;

  const _VegetableOption({
    required this.key,
    required this.vegetableId,
    required this.name,
    required this.unit,
  });
}

class _MarketComparisonCard extends StatelessWidget {
  final MarketPrice price;
  final double amount;
  final bool isCheapest;
  final bool isRetail;
  final String unit;

  const _MarketComparisonCard({
    required this.price,
    required this.amount,
    required this.isCheapest,
    required this.isRetail,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isUnavailable = price.availability == 'অনুপলব্ধ';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCheapest ? AppTheme.green : const Color(0xFFE7ECE7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCheapest
                  ? AppTheme.lightGreen
                  : const Color(0xFFF0F2EF),
              child: Icon(
                isCheapest ? Icons.south_west_rounded : Icons.storefront,
                color: isCheapest ? AppTheme.green : Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.marketName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${price.district} · ${price.displayName}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (isCheapest && !isUnavailable) ...[
                    const SizedBox(height: 5),
                    const Text(
                      'সবচেয়ে কম',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (isUnavailable)
                    const Text(
                      'বর্তমানে অনুপলব্ধ',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${BengaliFormatter.toBengaliDigits(amount.toStringAsFixed(0))}',
                  style: TextStyle(
                    color: isUnavailable ? Colors.black45 : AppTheme.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'প্রতি $unit · ${isRetail ? 'খুচরা' : 'পাইকারি'}',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
