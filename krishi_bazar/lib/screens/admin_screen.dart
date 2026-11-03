import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/market_price.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _vegetable = TextEditingController();
  final _localName = TextEditingController();
  final _market = TextEditingController();
  final _district = TextEditingController(text: 'ভোলা');
  final _wholesale = TextEditingController();
  final _retail = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final String _availability = 'সহজলভ্য';
  late final MarketService _service;
  bool _saving = false;
  bool _seeding = false;
  bool _savingApiKey = false;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore? db;
    try { db = FirebaseFirestore.instance; } catch (_) { db = null; }
    _service = MarketService(firestore: db);
    AiService.getApiKeyAsync().then((k) {
      if (mounted) _geminiKeyController.text = k;
    });
  }

  @override
  void dispose() {
    _vegetable.dispose();
    _localName.dispose();
    _market.dispose();
    _district.dispose();
    _wholesale.dispose();
    _retail.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveGeminiKey() async {
    setState(() => _savingApiKey = true);
    try {
      await AiService.saveApiKeyToFirestore(_geminiKeyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini API কী সফলভাবে ফায়ারবেসে সংরক্ষণ হয়েছে!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সংরক্ষণ করা যায়নি: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _savingApiKey = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final price = MarketPrice(
        id: 'new',
        vegetableId: _vegetable.text.trim().toLowerCase(),
        vegetableName: _vegetable.text.trim(),
        localName: _localName.text.trim(),
        marketName: _market.text.trim(),
        district: _district.text.trim(),
        wholesalePrice: double.parse(_wholesale.text.trim()),
        retailPrice: double.parse(_retail.text.trim()),
        updatedAt: DateTime.now(),
        source: 'অ্যাডমিন আপডেট',
        availability: _availability,
      );
      await _service.savePrice(price);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('দাম ও মজুত সফলভাবে ফায়ারবেসে সংরক্ষণ হয়েছে!')),
        );
        _vegetable.clear();
        _localName.clear();
        _market.clear();
        _wholesale.clear();
        _retail.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ফায়ারবেসে সংরক্ষণ করা যায়নি: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _seedDemoData() async {
    setState(() => _seeding = true);
    try {
      final count = await _service.seedDemoData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count টি নমুনা ডেটা ফায়ারবেসে জমা করা হয়েছে!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সিড করা যায়নি: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _deletePrice(String id, String vegetableName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('দাম মুছে ফেলুন'),
        content: Text('আপনি কি নিশ্চিত যে "$vegetableName"-এর এই বাজারদর ফায়ারবেস থেকে মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছে ফেলুন'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deletePrice(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('বাজারদর ফায়ারবেস থেকে মুছে ফেলা হয়েছে।')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('মুছে ফেলা যায়নি: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট'),
        content: const Text('আপনি কি অ্যাডমিন সেশন থেকে লগআউট করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('লগআউট')),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        // If not logged in, show LoginScreen embedded in Admin route
        if (user == null) {
          return const LoginScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('অ্যাডমিন প্যানেল'),
            actions: [
              IconButton(
                tooltip: 'লগআউট',
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppTheme.green, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'অ্যাডমিন হিসেবে সাইন-ইন আছেন',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            user.email ?? 'অ্যাডমিন ইউজার',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.blue.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ফায়ারবেস ডেটাবেজ খালি থাকলে এক ক্লিকে ডেমো বাজারদর ফায়ারবেসে আপলোড করতে পারেন:',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _seeding ? null : _seedDemoData,
                        child: Text(_seeding ? 'আপলোড হচ্ছে...' : 'সিড করুন'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, color: AppTheme.green),
                          SizedBox(width: 8),
                          Text('Google Gemini AI সেটিংস (API Key)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'সবজি শনাক্তকরণের জন্য Google AI Studio (aistudio.google.com)-এর API Key দিন। এটি ফায়ারবেসে ক্লাউডে সংরক্ষিত থাকবে।',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _geminiKeyController,
                              decoration: const InputDecoration(
                                hintText: 'AIzaSy...',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppTheme.green),
                            onPressed: _savingApiKey ? null : _saveGeminiKey,
                            child: Text(_savingApiKey ? '...' : 'সংরক্ষণ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('নতুন বাজারদর যোগ করুন', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(_vegetable, 'সবজির নাম (যেমন: আলু)'),
                    _field(_market, 'বাজারের নাম'),
                    _field(_district, 'জেলা'),
                    _field(_wholesale, 'পাইকারি দাম (টাকা)', numeric: true),
                    _field(_retail, 'খুচরা দাম (টাকা)', numeric: true),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'দাম ফায়ারবেসে সংরক্ষণ করুন'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('বিদ্যমান বাজারদরের তালিকা (Firestore CRUD)', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              StreamBuilder<List<MarketPrice>>(
                stream: _service.watchPrices(),
                builder: (context, priceSnapshot) {
                  final prices = priceSnapshot.data ?? [];
                  if (prices.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('কোনো ডেটা পাওয়া যায়নি।'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prices.length,
                    itemBuilder: (context, index) {
                      final p = prices[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.lightGreen,
                            child: Icon(Icons.shopping_basket_outlined, color: AppTheme.green),
                          ),
                          title: Text('${p.vegetableName} - ${p.marketName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('পাইকারি: ৳${p.wholesalePrice.toStringAsFixed(0)} | খুচরা: ৳${p.retailPrice.toStringAsFixed(0)} (${p.source})'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deletePrice(p.id, p.vegetableName),
                            tooltip: 'মুছে ফেলুন',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label, {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(labelText: label),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'এই ঘরটি পূরণ করুন';
            if (numeric && double.tryParse(v.trim()) == null) return 'সঠিক সংখ্যা লিখুন';
            return null;
          },
        ),
      );
}
