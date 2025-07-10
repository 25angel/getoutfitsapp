import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'outfit_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  String selectedSeason = 'All';

  final List<String> seasons = ['All', 'Winter', 'Spring', 'Summer', 'Fall'];

  Future<void> deleteOutfit(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('outfits')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Outfits', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedSeason,
            onSelected: (String value) {
              setState(() {
                selectedSeason = value;
              });
            },
            icon: const Icon(Icons.filter_list, color: Colors.black),
            itemBuilder: (BuildContext context) {
              return seasons.map((String season) {
                return PopupMenuItem<String>(
                  value: season,
                  child: Text(season),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('outfits')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredDocs =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final season = data['season'] ?? '';
                return selectedSeason == 'All' || season == selectedSeason;
              }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(child: Text("No outfits found."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final topUrl = data['topId'] ?? '';
              final bottomUrl = data['bottomId'] ?? '';
              final accessoryUrl = data['accessoryId'] ?? '';
              final baseUrl = data['baseItemId'] ?? '';
              final footwearUrl = data['footwearId'] ?? '';

              final imageUrls = [
                if (topUrl.isNotEmpty) topUrl,
                if (baseUrl.isNotEmpty) baseUrl,
                if (bottomUrl.isNotEmpty) bottomUrl,
                if (accessoryUrl.isNotEmpty) accessoryUrl,
                if (footwearUrl.isNotEmpty) footwearUrl,
              ];

              return GestureDetector(
                onLongPress: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text("Delete Outfit"),
                          content: const Text(
                            "Do you want to delete this outfit?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    await deleteOutfit(doc.id);
                  }
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutfitDetailScreen(outfit: data),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        imageUrls
                            .map(
                              (url) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(Icons.error),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
