import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Uložiť používateľa do cache (pre offline režim)
  Future<void> _cacheUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode({
      'id': user.id,
      'name': user.name,
      'surname': user.surname,
      'email': user.email,
      'role': user.role,
      'qr_code': user.qrCode,
      'total_points': user.totalPoints,
      'date_of_birth': user.dateOfBirth?.toIso8601String(),
    }));
  }

  // Načítať používateľa z cache
  Future<User?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_user');
    if (cached == null) return null;
    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // Vymazať cache používateľa
  Future<void> _clearCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

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
        await _cacheUser(_user!);
        
        // Stiahnuť údaje pre offline režim
        await _downloadOfflineData();
        
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

  // Stiahnuť údaje pre offline režim
  Future<void> _downloadOfflineData() async {
    if (_user == null) return;
    
    final offlineService = OfflineService();
    
    try {
      // Stiahnuť nápoje
      final drinksResponse = await ApiService.get('/drinks');
      if (drinksResponse.statusCode == 200) {
        final data = jsonDecode(drinksResponse.body);
        final drinks = (data['drinks'] as List).cast<Map<String, dynamic>>();
        await offlineService.cacheDrinks(drinks);
      }
      
      // Ak je obsluha alebo admin, stiahnuť zákazníkov
      if (_user!.isObsluha || _user!.isAdmin) {
        final customersResponse = await ApiService.get('/points/customers');
        if (customersResponse.statusCode == 200) {
          final data = jsonDecode(customersResponse.body);
          final users = (data['users'] as List).cast<Map<String, dynamic>>();
          await offlineService.cacheUsers(users);
        }
      }
    } catch (e) {
      // Ignorovať chyby - offline údaje nie sú kritické
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
        await _cacheUser(_user!);
        
        // Stiahnuť údaje pre offline režim
        await _downloadOfflineData();
        
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
    await _clearCachedUser();
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
        await _cacheUser(_user!);
        notifyListeners();
      } else if (response.statusCode == 401) {
        // Token je neplatný - odhlásiť
        await ApiService.removeToken();
        await _clearCachedUser();
        _user = null;
        notifyListeners();
      } else {
        // Iná chyba (napr. server nedostupný) - skúsiť načítať z cache
        _user = await _getCachedUser();
        notifyListeners();
      }
    } catch (e) {
      // Offline - skúsiť načítať z cache
      _user = await _getCachedUser();
      notifyListeners();
    }
  }
}

