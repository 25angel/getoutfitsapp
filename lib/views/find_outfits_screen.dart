import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindOutfitsScreen extends StatefulWidget {
  final Map<String, dynamic> baseItem;

  const FindOutfitsScreen({super.key, required this.baseItem});

  @override
  State<FindOutfitsScreen> createState() => _FindOutfitsScreenState();
}

class _FindOutfitsScreenState extends State<FindOutfitsScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> compatibleItems = [];
  Set<String> selectedImageUrls = {};
  bool isLoading = true;

  final Map<String, String> categoryMapping = {
    't-shirt': 'topId',
    'shirt': 'topId',
    'hoodie': 'topId',
    'jacket': 'topId',
    'outer top': 'topId',
    'top': 'topId',
    'pants': 'bottomId',
    'jeans': 'bottomId',
    'bottom': 'bottomId',
    'skirt': 'bottomId',
    'shorts': 'bottomId',
    'footwear': 'footwearId',
    'shoes': 'footwearId',
    'sneakers': 'footwearId',
    'boots': 'footwearId',
    'accessory': 'accessoryId',
    'bag': 'accessoryId',
    'hat': 'accessoryId',
    'headwear': 'accessoryId',
    'cap': 'accessoryId',
    'glasses': 'accessoryId',
  };

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('items')
              .get();

      final all =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      final baseStyle = widget.baseItem['style'];
      final baseSeason = widget.baseItem['season'];
      final baseId = widget.baseItem['imageUrl'];
      final baseCategory =
          (widget.baseItem['category'] as String?)?.toLowerCase();

      compatibleItems =
          all.where((item) {
            final isNotSame = item['imageUrl'] != baseId;
            final sameStyle = item['style'] == baseStyle;
            final sameSeason = item['season'] == baseSeason;
            final itemCategory = (item['category'] as String?)?.toLowerCase();

            final differentCategory =
                baseCategory != null &&
                itemCategory != null &&
                itemCategory != baseCategory;

            return isNotSame && sameStyle && sameSeason && differentCategory;
          }).toList();

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _saveMultiCapsule() async {
    final capsuleData = {
      'baseItemId': widget.baseItem['imageUrl'],
      'season': widget.baseItem['season'],
      'style': widget.baseItem['style'],
      'createdAt': FieldValue.serverTimestamp(),
    };

    for (var url in selectedImageUrls) {
      final match = compatibleItems.firstWhere(
        (item) => item['imageUrl'] == url,
        orElse: () => {},
      );

      final cat = match['category']?.toLowerCase();
      if (cat != null && categoryMapping.containsKey(cat)) {
        capsuleData[categoryMapping[cat]!] = url;
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('capsules')
        .add(capsuleData);

    setState(() => selectedImageUrls.clear());

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Capsule saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFEA),
      appBar: AppBar(
        title: const Text("Matching Outfits"),
        backgroundColor: const Color(0xFFFDEFEA),
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : compatibleItems.isEmpty
              ? const Center(
                child: Text(
                  "We couldn’t find any matching outfits right now.",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: compatibleItems.length,
                      itemBuilder: (context, index) {
                        final match = compatibleItems[index];
                        final imageUrl = match['imageUrl'];
                        final isSelected = selectedImageUrls.contains(imageUrl);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedImageUrls.remove(imageUrl);
                              } else {
                                selectedImageUrls.add(imageUrl);
                              }
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          height: 220,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                                Icons.broken_image,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            match['category'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Season: ${match['season'] ?? '-'}",
                                          ),
                                          Text(
                                            "Style: ${match['style'] ?? '-'}",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (selectedImageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _saveMultiCapsule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text("SAVE CAPSULE"),
                      ),
                    ),
                ],
              ),
    );
  }
}
