class MarketPrice {
  final String id;
  final String vegetableId;
  final String vegetableName;
  /// Regional or market-specific name / variety in this particular market
  /// (e.g. 'কদু' for 'লাউ', 'গোল বেগুন' / 'তাল বেগুন' for 'বেগুন', 'লাল আলু' for 'আলু')
  final String localName;
  final String marketName;
  final String district;
  final double wholesalePrice;
  final double retailPrice;
  final String unit;
  final DateTime updatedAt;
  final String source;
  /// Stock availability status: 'সহজলভ্য' (Available), 'সীমিত মজুত' (Limited), 'অনুপলব্ধ' (Unavailable)
  final String availability;

  const MarketPrice({
    required this.id,
    required this.vegetableId,
    required this.vegetableName,
    this.localName = '',
    required this.marketName,
    required this.district,
    required this.wholesalePrice,
    required this.retailPrice,
    this.unit = 'কেজি',
    required this.updatedAt,
    this.source = 'অ্যাডমিন আপডেট',
    this.availability = 'সহজলভ্য',
  });

  /// Returns the display name in this market:
  /// Uses localName if provided and different, else vegetableName
  String get displayName =>
      (localName.isNotEmpty && localName.trim() != vegetableName.trim())
          ? '$vegetableName ($localName)'
          : vegetableName;

  factory MarketPrice.fromMap(String id, Map<String, dynamic> map) {
    return MarketPrice(
      id: id,
      vegetableId: map['vegetableId'] ?? '',
      vegetableName: map['vegetableName'] ?? '',
      localName: map['localName'] ?? '',
      marketName: map['marketName'] ?? '',
      district: map['district'] ?? '',
      wholesalePrice: (map['wholesalePrice'] as num? ?? 0).toDouble(),
      retailPrice: (map['retailPrice'] as num? ?? 0).toDouble(),
      unit: map['unit'] ?? 'কেজি',
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      source: map['source'] ?? 'অ্যাডমিন আপডেট',
      availability: map['availability'] ?? 'সহজলভ্য',
    );
  }

  Map<String, dynamic> toMap() => {
    'vegetableId': vegetableId,
    'vegetableName': vegetableName,
    'localName': localName,
    'marketName': marketName,
    'district': district,
    'wholesalePrice': wholesalePrice,
    'retailPrice': retailPrice,
    'unit': unit,
    'updatedAt': updatedAt.toIso8601String(),
    'source': source,
    'availability': availability,
  };
}
