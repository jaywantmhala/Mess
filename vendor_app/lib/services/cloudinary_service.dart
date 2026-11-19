// lib/services/cloudinary_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String _cloudName = 'dzyhoeurm';
  static const String _apiKey = '826648439174773';
  static const String _apiSecret = 'wI6oL1bHuwTtDgaq3XBKZuZVpTQ';

  /// Uploads image bytes to Cloudinary and returns the secure URL (web & mobile compatible)
  static Future<String?> uploadImageBytes(Uint8List bytes, {String filename = 'upload.jpg'}) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      const folder = 'hotels';

      final stringToSign = 'folder=$folder&timestamp=$timestamp$_apiSecret';

      final sigBytes = utf8.encode(stringToSign);
      final signature = sha1.convert(sigBytes).toString();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['folder'] = folder;
      request.fields['signature'] = signature;

      final isPng = filename.toLowerCase().endsWith('.png');
      final mediaType = isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      );

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

  /// Legacy helper for File
  static Future<String?> uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.path.contains('/') || file.path.contains('\\')
          ? file.path.split(RegExp(r'[/\\]')).last
          : 'upload.jpg';
      return uploadImageBytes(bytes, filename: filename);
    } catch (e) {
      print('Error reading file for Cloudinary upload: $e');
      return null;
    }
  }
}
