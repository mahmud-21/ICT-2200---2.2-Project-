import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import 'vegetable_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  /// Called when the user wants to see the price-list tab for a vegetable name.
  final Function(String vegetableName)? onSelectVegetableForPrice;

  const ScanScreen({super.key, this.onSelectVegetableForPrice});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  final _aiService = AiService();
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  bool _isSavingToFirebase = false;
  bool _isSavedToFirebase = false;
  VegetableResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-resolve API key from Firestore if available
    AiService.getApiKeyAsync().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _errorMessage = null;
        _isSavedToFirebase = false;
        _isSavingToFirebase = false;
      });
      _analyzeImage();
    } catch (e) {
      setState(() => _errorMessage = 'ছবি খুলতে সমস্যা হয়েছে: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _result = null;
      _isSavedToFirebase = false;
      _isSavingToFirebase = false;
    });

    try {
      final result = await _aiService.analyzeVegetableImageBytes(_imageBytes!);
      if (mounted) {
        setState(() {
          _result = result;
        });

        // Automatically save picture and information to Firebase Firestore
        if (result.isVegetable) {
          setState(() => _isSavingToFirebase = true);
          AiService.saveVegetableScanToFirebase(
            result: result,
            imageBytes: _imageBytes!,
          ).then((docId) {
            if (mounted) {
              setState(() {
                _isSavingToFirebase = false;
                _isSavedToFirebase = (docId != null);
              });
            }
          });
        }
      }
    } on StateError catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } on FormatException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _runDemoResult() {
    setState(() {
      _result = const VegetableResult(
        isVegetable: true,
        vegetableNameBengali: 'আলু',
        vegetableNameEnglish: 'Potato',
        scientificName: 'Solanum tuberosum',
        confidence: 'উচ্চ (ডেমো)',
        detailsBengali: 'আলু একটি অত্যন্ত জনপ্রিয় কন্দজাতীয় সবজি। বাংলাদেশের প্রায় সব জেলায় রবি মৌসুমে এটি প্রচুর পরিমাণে চাষ হয়।',
        nutritionBengali:
            'আলু ভিটামিন সি, ভিটামিন বি৬, পটাশিয়াম ও আঁশে সমৃদ্ধ। ১০০ গ্রাম আলুতে প্রায় ৭৭ ক্যালোরি থাকে। এটি শর্করার একটি ভালো উৎস।',
        growingSeasonBengali: 'অক্টোবর – ফেব্রুয়ারি (রবি মৌসুম)',
        bestMonthBengali: 'অক্টোবর – নভেম্বর',
        usesBengali: 'রান্নায় তরকারি, আলুর দম, চিপস, ভাজি, ফ্রেঞ্চ ফ্রাই এবং ভর্তা তৈরিতে বহুল ব্যবহৃত হয়।',
      );
      _errorMessage = null;
      _isSavedToFirebase = false;
    });
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey = await AiService.getApiKeyAsync();
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppTheme.green),
            SizedBox(width: 8),
            Text('Gemini API কী সেট করুন', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'সবজি শনাক্ত করতে Google AI Studio-এর Gemini API Key ব্যবহার করা হয়।',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AQ.Ab... বা AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'aistudio.google.com/app/apikey থেকে ফ্রি API Key সংগ্রহ করতে পারেন।',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.green),
            onPressed: () async {
              final newKey = controller.text.trim();
              await AiService.saveApiKeyToFirestore(newKey);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gemini API কী সংরক্ষণ করা হয়েছে!')),
                );
                setState(() {});
              }
            },
            child: const Text('সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
  }

  /// Opens the full detail screen for the current result.
  void _openDetailScreen() {
    if (_result == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VegetableDetailScreen(
          result: _result!,
          imageBytes: _imageBytes,
        ),
      ),
    );
  }

  /// Shows the gallery of saved vegetable scans stored in Firebase
  void _openSavedGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: AppTheme.green),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ফায়ারবেসে সংরক্ষিত সবজির তালিকা',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AiService.watchSavedVegetables(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'এখনো কোনো সবজি ফায়ারবেসে সংরক্ষিত নেই।\nসবজির ছবি স্ক্যান করলে তা এখানে সংরক্ষিত হবে।',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final nameBn = item['vegetableNameBengali'] ?? 'সবজি';
                      final nameEn = item['vegetableNameEnglish'] ?? '';
                      final scientific = item['scientificName'] ?? '';
                      final base64Img = item['imageBase64'] as String?;
                      final scannedAt = item['scannedAt'] != null
                          ? DateTime.tryParse(item['scannedAt'].toString())
                          : null;
                      final dateStr = scannedAt != null
                          ? '${scannedAt.day}/${scannedAt.month}/${scannedAt.year}'
                          : '';

                      Uint8List? thumbBytes;
                      if (base64Img != null && base64Img.isNotEmpty) {
                        try {
                          thumbBytes = base64Decode(base64Img);
                        } catch (_) {}
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: thumbBytes != null
                                ? Image.memory(
                                    thumbBytes,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 58,
                                    height: 58,
                                    color: AppTheme.lightGreen,
                                    child: const Icon(Icons.eco, color: AppTheme.green),
                                  ),
                          ),
                          title: Text(
                            nameBn,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$nameEn ${scientific.isNotEmpty ? "($scientific)" : ""}'),
                              if (dateStr.isNotEmpty)
                                Text('সংরক্ষিত: $dateStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'মুছে ফেলুন',
                                onPressed: () async {
                                  if (item['id'] != null) {
                                    await FirebaseFirestore.instance
                                        .collection('scanned_vegetables')
                                        .doc(item['id'])
                                        .delete();
                                  }
                                },
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VegetableDetailScreen(
                                  result: VegetableResult.fromMap(item),
                                  imageBase64: base64Img,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ছবি দিয়ে সবজি চিনুন', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.collections_bookmark_outlined, color: AppTheme.green),
                    tooltip: 'ফায়ারবেসে সংরক্ষিত সবজির তালিকা',
                    onPressed: _openSavedGallery,
                  ),
                  IconButton(
                    icon: const Icon(Icons.key_rounded, color: AppTheme.green),
                    tooltip: 'Gemini API কী সেটিংস',
                    onPressed: _showApiKeyDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ক্যামেরা দিয়ে ছবি তুলুন অথবা গ্যালারি থেকে সবজির ছবি নির্বাচন করুন।',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 14),

          Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.green.withValues(alpha: 0.2)),
            ),
            child: _imageBytes == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 60, color: AppTheme.green),
                      SizedBox(height: 12),
                      Text('আপনার সবজির ছবি এখানে দেখাবে', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('ছবি তুলুন'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isAnalyzing ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('গ্যালারি'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isAnalyzing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Gemini AI সবজিটি ও এর বিস্তারিত তথ্য বিশ্লেষণ করছে...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null && !_isAnalyzing) ...[
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.green),
                          onPressed: _analyzeImage,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('পুনরায় চেষ্টা করুন'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showApiKeyDialog,
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text('API Key পরিবর্তন করুন'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _runDemoResult,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('ডেমো আলু দেখুন'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_result != null && !_isAnalyzing) ...[
            if (!_result!.isVegetable)
              Card(
                color: Colors.amber.shade50,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.no_food_outlined, color: Colors.amber.shade900, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'সবজি শনাক্ত করা যায়নি',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _result!.detailsBengali.isNotEmpty
                            ? _result!.detailsBengali
                            : 'ছবিতে কোনো সবজি পাওয়া যায়নি। দয়া করে সবজির একটি স্পষ্ট ছবি তুলে আবার চেষ্টা করুন।',
                        style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('নতুন ছবি তুলুন'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.eco, color: AppTheme.green, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _result!.vegetableNameBengali,
                                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  _result!.vegetableNameEnglish,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                if (_result!.scientificName.isNotEmpty)
                                  Text(
                                    _result!.scientificName,
                                    style: const TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'নিশ্চয়তা: ${_result!.confidence}',
                              style: const TextStyle(color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Firebase Cloud Save Status Banner
                      const SizedBox(height: 12),
                      if (_isSavingToFirebase)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('ফায়ারবেসে ছবি ও তথ্য সংরক্ষণ হচ্ছে...', style: TextStyle(fontSize: 12, color: Colors.blue)),
                            ],
                          ),
                        )
                      else if (_isSavedToFirebase)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_done_rounded, color: AppTheme.green, size: 16),
                              SizedBox(width: 6),
                              Text('ছবি ও তথ্য ফায়ারবেসে সংরক্ষিত হয়েছে', style: TextStyle(fontSize: 12, color: AppTheme.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                      // Information sections preview
                      if (_result!.detailsBengali.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          _result!.detailsBengali,
                          style: TextStyle(color: Colors.grey.shade800, height: 1.5, fontSize: 13),
                        ),
                      ],

                      // Nutrition Value Preview
                      if (_result!.nutritionBengali.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.restaurant_menu_rounded, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'পুষ্টিগুণ: ${_result!.nutritionBengali}',
                                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Best Time to Grow (Bangladesh)
                      if (_result!.bestMonthBengali.isNotEmpty || _result!.growingSeasonBengali.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'বাংলাদেশে চাষের সময়: ${_result!.bestMonthBengali.isNotEmpty ? _result!.bestMonthBengali : _result!.growingSeasonBengali}',
                                  style: TextStyle(color: Colors.teal.shade900, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Uses Preview
                      if (_result!.usesBengali.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.soup_kitchen_rounded, color: Colors.deepPurple, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ব্যবহার: ${_result!.usesBengali}',
                                  style: TextStyle(color: Colors.purple.shade900, fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Action buttons ────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.green),
                              onPressed: _openDetailScreen,
                              icon: const Icon(Icons.info_outline_rounded),
                              label: const Text('সম্পূর্ণ তথ্য ও ছবি দেখুন'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (widget.onSelectVegetableForPrice != null) {
                                widget.onSelectVegetableForPrice!(_result!.vegetableNameBengali);
                              }
                            },
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('দাম খুঁজুন'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 AI সবজি শনাক্তকরণ কীভাবে কাজ করে?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text(
                    'অ্যাপটি Google Gemini Vision AI মডেল ব্যবহার করে ছবি বিশ্লেষণ করে এবং সবজির বাংলা ও ইংরেজি নাম, বৈজ্ঞানিক নাম, পুষ্টিগুণ, ব্যবহার ও বাংলাদেশে চাষের সেরা সময় শনাক্ত করে এবং ছবিসহ তথ্য Firebase Firestore-এ ক্লাউডে সংরক্ষণ করে।',
                    style: TextStyle(height: 1.5, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
