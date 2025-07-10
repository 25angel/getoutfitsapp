import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageClassifierService {
  final String apiUrl =
      'https://infer.roboflow.com/custom-workflow-multi-label-classification-fugzi/1';
  final String apiKey = 'WUBYtVC2or';

  Future<List<String>> classifyImage(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$apiUrl?api_key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"image": imageUrl}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final predictions = json['predictions'] as List<dynamic>?;

      if (predictions != null) {
        // Возвращаем список всех найденных лейблов
        return predictions.map((p) => p['class'].toString()).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to classify image: ${response.body}');
    }
  }
}
