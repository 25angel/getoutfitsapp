import 'package:flutter/material.dart';

class OutfitDetailScreen extends StatelessWidget {
  final Map<String, dynamic> outfit;

  const OutfitDetailScreen({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    final top = outfit['topId'];
    final bottom = outfit['bottomId'];
    final accessory = outfit['accessoryId'];
    final base = outfit['baseItemId'];
    final footwear = outfit['footwearId'];

    final images = [
      if (top != null) top,
      if (base != null) base,
      if (bottom != null) bottom,
      if (accessory != null) accessory,
      if (footwear != null) footwear,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final url = images[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              url,
              height: 140,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.error),
            ),
          );
        },
      ),
    );
  }
}
