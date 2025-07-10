import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TryOnScreen extends StatelessWidget {
  final Map<String, dynamic> capsule;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  TryOnScreen({super.key, required this.capsule});

  @override
  Widget build(BuildContext context) {
    final parts = [
      {'label': 'Top', 'url': capsule['topId']},
      {'label': 'Base', 'url': capsule['baseItemId']},
      {'label': 'Bottom', 'url': capsule['bottomId']},
      {'label': 'Footwear', 'url': capsule['footwearId']},
      {'label': 'Accessory', 'url': capsule['accessoryId']},
    ];

    final filteredParts =
        parts
            .where((p) => p['url'] != null && p['url'].toString().isNotEmpty)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFEA),
      appBar: AppBar(
        title: const Text("Try On Capsule"),
        backgroundColor: const Color(0xFFFDEFEA),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredParts.length,
              itemBuilder: (context, index) {
                final part = filteredParts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        part['label']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          part['url']!,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.error, size: 50),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('outfits')
                      .add({
                        'topId': capsule['topId'],
                        'bottomId': capsule['bottomId'],
                        'accessoryId': capsule['accessoryId'],
                        'footwearId': capsule['footwearId'],
                        'baseItemId': capsule['baseItemId'],
                        'season': capsule['season'],
                        'style': capsule['style'],
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Outfit saved!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("SAVE OUTFIT"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
