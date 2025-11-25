import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Production URL - zmeňte na URL vášho produkčného servera
  // Pre lokálny vývoj použite: 'http://127.0.0.1:8000/api'
  // Pre produkciu použite napr.: 'https://api.picipas.sk/api'
  static const String baseUrl = 'https://picipas.dft.sk/api';
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> delete(String endpoint, {bool includeAuth = true}) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }
}

