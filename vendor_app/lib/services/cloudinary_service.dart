// lib/services/cloudinary_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dzyhoeurm';
  static const String _apiKey = '826648439174773';
  static const String _apiSecret = 'wI6oL1bHuwTtDgaq3XBKZuZVpTQ';

  /// Uploads a file to Cloudinary and returns the secure URL
  static Future<String?> uploadImage(File file) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      const folder = 'hotels';

      // Alphabetical order: folder, timestamp
      final stringToSign = 'folder=$folder&timestamp=$timestamp$_apiSecret';

      // SHA-1 signature
      final bytes = utf8.encode(stringToSign);
      final signature = sha1.convert(bytes).toString();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['folder'] = folder;
      request.fields['signature'] = signature;

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        print('Cloudinary upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
