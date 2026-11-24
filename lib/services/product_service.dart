import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  // En Android Emulator localhost es 10.0.2.2; en Windows Desktop / Web es localhost.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8081';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8081';
      default:
        return 'http://localhost:8081';
    }
  }

  static Future<List<ProductModel>> fetchProducts() async {
    final url = Uri.parse('$baseUrl/products');
    final response = await http.get(url).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error del servidor: Código ${response.statusCode}');
    }
  }
}
