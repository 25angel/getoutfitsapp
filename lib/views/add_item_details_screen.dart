import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

import 'add_item_screen.dart';

class AddItemDetailsScreen extends StatefulWidget {
  final XFile imageFile;

  const AddItemDetailsScreen({super.key, required this.imageFile});

  @override
  State<AddItemDetailsScreen> createState() => _AddItemDetailsScreenState();
}

class _AddItemDetailsScreenState extends State<AddItemDetailsScreen> {
  bool isWish = false;
  String? category;
  String? color;
  String? season;
  String? style;
  String? brand;
  bool isLoading = false;

  final List<String> categories = [
    "Outer Top",
    "Mid Top",
    "Top",
    "Bottom",
    "Footwear",
    "Head",
    "Bags",
  ];

  final List<String> colors = [
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

  final List<String> seasons = ["Winter", "Summer", "Spring", "Fall"];
  final List<String> styles = ["Casual", "Formal", "Sport"];
  final List<String> brands = [
    "Zara",
    "H&M",
    "Uniqlo",
    "Nike",
    "Adidas",
    "Other",
  ];

  final Map<String, String> categoryMap = {
    "blusa": "Mid Top",
    "playera": "Top",
    "chamarra": "Outer Top",
    "chaleco": "Outer Top",
    "falda": "Bottom",
    "pantalon": "Bottom",
    "short": "Bottom",
    "zapatos": "Footwear",
    "gorra": "Head",
    "sueter": "Outer Top",
    "bufanda": "Outer Top",
    "saco": "Outer Top",
  };

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<File> _removeBackground(File imageFile) async {
    final apiKey = 'YwJiSuuSfL1FyQFcyLb93B6h';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('image_file', imageFile.path),
    );
    request.headers['X-Api-Key'] = apiKey;

    final response = await request.send();
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final directory = await getTemporaryDirectory();
      final output = File('${directory.path}/${const Uuid().v4()}.png');
      await output.writeAsBytes(bytes);
      return output;
    } else {
      throw Exception('Background removal failed: ${response.statusCode}');
    }
  }

  Future<void> _analyzeImage() async {
    try {
      // Удаляем фон
      final cleanedFile = await _removeBackground(File(widget.imageFile.path));
      final bytes = await cleanedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Категория
      final categoryUrl =
          'https://detect.roboflow.com/clothes-classification-4y9fn-7q1dy/1?api_key=5wVvvjcAvstpjtG7pFHd';
      final categoryResponse = await http.post(
        Uri.parse(categoryUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      );

      debugPrint("📦 CATEGORY RAW RESPONSE: ${categoryResponse.body}");

      if (categoryResponse.statusCode == 200) {
        final result = jsonDecode(categoryResponse.body);
        final predictions = result['predictions'] as List<dynamic>;
        if (predictions.isNotEmpty) {
          predictions.sort(
            (a, b) => (b['confidence'] as num).compareTo(a['confidence']),
          );
          final label = (predictions.first['class'] as String).toLowerCase();
          debugPrint("✅ CATEGORY: $label");

          setState(() {
            category =
                categoryMap.entries
                    .firstWhere(
                      (entry) => label.contains(entry.key),
                      orElse: () => const MapEntry('', ''),
                    )
                    .value;

            for (var brandName in brands) {
              if (label.contains(brandName.toLowerCase())) {
                brand = brandName;
                break;
              }
            }

            if (label.contains("sport")) style = "Sport";
            if (label.contains("formal")) style = "Formal";
            if (label.contains("casual")) style = "Casual";
          });
        }
      } else {
        debugPrint(
          "❌ Category error: ${categoryResponse.statusCode} — ${categoryResponse.body}",
        );
      }

      // Цвет
      final colorUrl =
          'https://detect.roboflow.com/colours-rtjqy-wwl8o/1?api_key=5wVvvjcAvstpjtG7pFHd';

      final colorResponse = await http.post(
        Uri.parse(colorUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      );

      debugPrint("🎨 COLOR RAW RESPONSE: ${colorResponse.body}");

      if (colorResponse.statusCode == 200) {
        final colorResult = jsonDecode(colorResponse.body);
        final predictions = colorResult['predictions'] as List<dynamic>;
        if (predictions.isNotEmpty) {
          predictions.sort(
            (a, b) => (b['confidence'] as num).compareTo(a['confidence']),
          );
          final label = (predictions.first['class'] as String).toLowerCase();
          debugPrint("🎯 COLOR: $label");

          setState(() {
            for (var colorName in colors) {
              if (label.contains(colorName.toLowerCase())) {
                color = colorName;
                break;
              }
            }
          });
        }
      } else {
        debugPrint(
          "❌ Color error: ${colorResponse.statusCode} — ${colorResponse.body}",
        );
      }
    } catch (e) {
      debugPrint("❌ Analyze Exception: $e");
    }
  }

  void _finish() async {
    if (category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final itemId = const Uuid().v4();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      final originalFile = File(widget.imageFile.path);
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        '${originalFile.parent.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 70,
      );

      if (compressedFile == null) throw Exception("Compression failed");

      final cleanedFile = await _removeBackground(File(compressedFile.path));

      final ref = FirebaseStorage.instance.ref().child(
        'items/$userId/$itemId.jpg',
      );
      await ref.putFile(cleanedFile);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .set({
            'imageUrl': imageUrl,
            'category': category,
            'color': color,
            'season': season,
            'style': style,
            'brand': brand,
            'isWish': isWish,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving item')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewFile = File(widget.imageFile.path);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Item Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AddItemScreen()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      previewFile,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Mark as WISH"),
                    Switch(
                      value: isWish,
                      onChanged: (val) => setState(() => isWish = val),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _dropdown(
                  "Category",
                  category,
                  categories,
                  (val) => setState(() => category = val),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  "Color",
                  color,
                  colors,
                  (val) => setState(() => color = val),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  "Season",
                  season,
                  seasons,
                  (val) => setState(() => season = val),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  "Style",
                  style,
                  styles,
                  (val) => setState(() => style = val),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  "Brand",
                  brand,
                  brands,
                  (val) => setState(() => brand = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _finish,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("FINISH"),
                ),
              ],
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
