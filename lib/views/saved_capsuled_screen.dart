import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'try_on_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedCapsulesScreen extends StatelessWidget {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  SavedCapsulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFEA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFEA),
        title: const Text(
          'Saved Capsules',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('capsules')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final capsules = snapshot.data?.docs ?? [];

          if (capsules.isEmpty) {
            return const Center(child: Text("No saved capsules yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: capsules.length,
            itemBuilder: (context, index) {
              final capsule = capsules[index].data() as Map<String, dynamic>;
              final capsuleId = capsules[index].id;
              final season = capsule['season'] ?? '-';
              final style = capsule['style'] ?? '-';

              final topUrl = capsule['topId'] ?? '';
              final bottomUrl = capsule['bottomId'] ?? '';
              final accessoryUrl = capsule['accessoryId'] ?? '';
              final footwearUrl = capsule['footwearId'] ?? '';

              final imageUrls = [
                if ((capsule['baseItemId'] ?? '').isNotEmpty)
                  {'url': capsule['baseItemId'], 'label': 'Base'},
                if (topUrl.isNotEmpty) {'url': topUrl, 'label': 'Top'},
                if (bottomUrl.isNotEmpty) {'url': bottomUrl, 'label': 'Bottom'},
                if (accessoryUrl.isNotEmpty)
                  {'url': accessoryUrl, 'label': 'Accessory'},
                if (footwearUrl.isNotEmpty)
                  {'url': footwearUrl, 'label': 'Footwear'},
              ];

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "$season #$style",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (imageUrls.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            imageUrls.map((image) {
                              return Column(
                                children: [
                                  Text(
                                    image['label'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade100,
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Image.network(
                                      image['url'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              const Icon(Icons.error),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('capsules')
                                .doc(capsuleId)
                                .delete();
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TryOnScreen(capsule: capsule),
                              ),
                            );
                          },

                          child: const Text("TRY ON"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
