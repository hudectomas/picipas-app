import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/login', {
        'email': email,
        'password': password,
      }, includeAuth: false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await ApiService.saveToken(data['token']);
        _user = User.fromJson(data['user']);
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        final errorMessage = data['message'] ?? 'Prihlásenie zlyhalo';
        _error = errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Chyba pri prihlásení: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String surname, String email, String password, String passwordConfirmation, DateTime dateOfBirth) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/register', {
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      }, includeAuth: false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await ApiService.saveToken(data['token']);
        _user = User.fromJson(data['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Registrácia zlyhala';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          _error = errors.values.first[0] ?? _error;
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Chyba pri registrácii: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/logout', {});
    } catch (e) {
      // Ignore errors
    }
    await ApiService.removeToken();
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await ApiService.getToken();
    if (token == null) {
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final response = await ApiService.get('/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data['user']);
        notifyListeners();
      } else {
        await ApiService.removeToken();
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      await ApiService.removeToken();
      _user = null;
      notifyListeners();
    }
  }
}

