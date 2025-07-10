import 'package:flutter/material.dart';
import '/views/find_outfits_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ItemDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorMap = {
      'Black': Colors.black,
      'White': Colors.white,
      'Gray': Colors.grey,
      'Brown': Colors.brown,
      'Beige': const Color(0xFFF5F5DC),
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Pink': Colors.pink,
      'Purple': Colors.purple,
      'Orange': Colors.orange,
    };

    final colorName = data['color'] as String?;
    final itemColor = colorMap[colorName] ?? Colors.grey.shade400;

    return Scaffold(
      backgroundColor: const Color(0xFFFDEFEA),
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: const Color(0xFFFDEFEA),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data['imageUrl'] != null)
            Container(
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
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data['imageUrl'],
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (data['category'] != null)
            Text(
              data['category'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          if (colorName != null)
            Row(
              children: [
                CircleAvatar(backgroundColor: itemColor, radius: 10),
                const SizedBox(width: 8),
                Text(colorName),
              ],
            ),
          if (data['season'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Season: ${data['season']}"),
            ),
          Wrap(
            spacing: 8,
            children: [
              if (data['style'] != null) Chip(label: Text('#${data['style']}')),
              if (data['function'] != null)
                Chip(label: Text('#${data['function']}')),
            ],
          ),
          if (data['brand'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Brand: ${data['brand']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ),
          const Divider(height: 32),
          const Text(
            "Create an Outfit",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Tap below to find matching items."),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FindOutfitsScreen(baseItem: data),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text("FIND OUTFITS"),
          ),
        ],
      ),
    );
  }
}
