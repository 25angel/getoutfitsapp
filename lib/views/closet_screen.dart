import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';
import 'saved_capsuled_screen.dart';
import 'outfits_screen.dart';
import 'profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  bool wishOnly = false;
  bool showFilters = false;
  List<String> selectedColors = [];
  List<String> selectedSeasons = [];

  final List<String> availableColors = [
    "Black",
    "White",
    "Gray",
    "Brown",
    "Beige",
    "Blue",
    "Red",
    "Green",
    "Yellow",
    "Pink",
    "Purple",
    "Orange",
  ];

  final List<String> availableSeasons = ["Winter", "Summer", "Spring", "Fall"];

  void _toggleColor(String color) {
    setState(() {
      selectedColors.contains(color)
          ? selectedColors.remove(color)
          : selectedColors.add(color);
    });
  }

  void _toggleSeason(String season) {
    setState(() {
      selectedSeasons.contains(season)
          ? selectedSeasons.remove(season)
          : selectedSeasons.add(season);
    });
  }

  void _toggleWish() {
    setState(() => wishOnly = !wishOnly);
  }

  Widget _buildFilterSection() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState:
          showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "Filter by Color",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            children: [
              FilterChipWidget(
                label: 'WISH',
                selected: wishOnly,
                onTap: _toggleWish,
              ),
              ...availableColors.map(
                (color) => FilterChipWidget(
                  label: color,
                  selected: selectedColors.contains(color),
                  onTap: () => _toggleColor(color),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "Filter by Season",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            children:
                availableSeasons
                    .map(
                      (season) => FilterChipWidget(
                        label: season,
                        selected: selectedSeasons.contains(season),
                        onTap: () => _toggleSeason(season),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
      secondChild: const SizedBox.shrink(),
    );
  }

  List<QueryDocumentSnapshot> filterItems(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final matchWish = !wishOnly || (data['isWish'] == true);
      final matchColor =
          selectedColors.isEmpty || selectedColors.contains(data['color']);
      final matchSeason =
          selectedSeasons.isEmpty || selectedSeasons.contains(data['season']);
      return matchWish && matchColor && matchSeason;
    }).toList();
  }

  Future<void> deleteItem(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('items')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'My collection',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.black),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavedCapsulesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.style, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OutfitsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              showFilters ? Icons.expand_less : Icons.expand_more,
              color: Colors.black,
            ),
            onPressed: () => setState(() => showFilters = !showFilters),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('items')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final filtered = filterItems(docs);

                return Column(
                  children: [
                    if (filtered.isEmpty)
                      const Expanded(
                        child: Center(child: Text("Your closet is empty.")),
                      )
                    else
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            final item = doc.data() as Map<String, dynamic>;
                            return GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ItemDetailScreen(data: item),
                                    ),
                                  ),
                              onLongPress: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder:
                                      (_) => AlertDialog(
                                        title: const Text("Delete item"),
                                        content: const Text(
                                          "Are you sure you want to delete this item?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) await deleteItem(doc.id);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade200,
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        item['imageUrl'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (item['isWish'] == true)
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(
                                          Icons.favorite_border,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (item['category'] != null)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            item['category'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddItemScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("+ ADD MY ITEM"),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
          const BottomNavBar(),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.black,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black45,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OutfitsScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Items'),
        BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Outfits'),
      ],
    );
  }
}
