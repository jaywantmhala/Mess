// lib/utils/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();

  Completer<String?>? _refreshCompleter;

  final StreamController<void> _unauthenticatedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthenticated => _unauthenticatedController.stream;

  Future<Map<String, String>> _getHeaders(Map<String, String>? customHeaders) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    if (!headers.containsKey('Authorization')) {
      final token = await AuthService.instance.getSavedToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _sendWithRetry(() async {
      final h = await _getHeaders(headers);
      return _client.get(url, headers: h);
    }, url: url, method: 'GET');
  }

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _sendWithRetry(() async {
      final h = await _getHeaders(headers);
      return _client.post(url, headers: h, body: body, encoding: encoding);
    }, url: url, method: 'POST');
  }

  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _sendWithRetry(() async {
      final h = await _getHeaders(headers);
      return _client.put(url, headers: h, body: body, encoding: encoding);
    }, url: url, method: 'PUT');
  }

  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _sendWithRetry(() async {
      final h = await _getHeaders(headers);
      return _client.delete(url, headers: h, body: body, encoding: encoding);
    }, url: url, method: 'DELETE');
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    required Uri url,
    required String method,
  }) async {
    final response = await requestFn();

    if (response.statusCode == 401 && !url.path.contains('/login') && !url.path.contains('/signup') && !url.path.contains('/refresh')) {
      debugPrint('ApiClient (Customer): HTTP 401 received for $method $url. Initiating token refresh...');

      String? newToken;

      if (_refreshCompleter != null) {
        // Refresh already in progress; await single lock completer
        newToken = await _refreshCompleter!.future;
      } else {
        _refreshCompleter = Completer<String?>();
        try {
          newToken = await AuthService.instance.refreshAccessToken();
          _refreshCompleter!.complete(newToken);
        } catch (e) {
          _refreshCompleter!.complete(null);
        } finally {
          _refreshCompleter = null;
        }
      }

      if (newToken != null && newToken.isNotEmpty) {
        debugPrint('ApiClient (Customer): Refresh succeeded. Retrying $method $url...');
        return requestFn();
      } else {
        debugPrint('ApiClient (Customer): Refresh failed. User session expired.');
        _unauthenticatedController.add(null);
      }
    }

    return response;
  }
}
