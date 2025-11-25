import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import 'add_points_screen.dart';
import 'dart:convert';

class SearchCustomerScreen extends StatefulWidget {
  const SearchCustomerScreen({super.key});

  @override
  State<SearchCustomerScreen> createState() => _SearchCustomerScreenState();
}

class _SearchCustomerScreenState extends State<SearchCustomerScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isLoadingAll = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAllCustomers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCustomers() async {
    setState(() {
      _isLoadingAll = true;
    });

    final offlineService = OfflineService();

    // Najprv skúsiť načítať z API (bez ohľadu na isOnline, lebo to môže byť nespoľahlivé)
    try {
      final response = await ApiService.get('/points/customers', includeAuth: true)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final usersList = data['users'] ?? [];
          
          // Konvertovať List<dynamic> na List<Map<String, dynamic>>
          final users = (usersList as List)
              .map((user) => user as Map<String, dynamic>)
              .toList();
          
          // Cacheovať používateľov
          await offlineService.cacheUsers(users);
          
          if (mounted) {
            setState(() {
              _allUsers = users;
              _results = users;
              _isLoadingAll = false;
            });
          }
          return; // Úspešne načítané z API
        } catch (e) {
          // Chyba pri parsovaní JSON
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chyba pri parsovaní dát: $e\nResponse: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // Ak API zlyhá, skúsiť načítať z cache
        if (mounted && response.statusCode != 401 && response.statusCode != 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba pri načítaní: ${response.statusCode}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Ak API request zlyhá (timeout, network error, etc.), skúsiť načítať z cache
      if (mounted) {
        // Nezobrazovať chybu ak je to len network error - skúsiť cache
      }
    }

    // Ak sa nepodarilo načítať z API, skúsiť z cache
    await _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final offlineService = OfflineService();
    try {
      final cachedUsers = await offlineService.getCachedUsers();
      if (mounted) {
        setState(() {
          _allUsers = cachedUsers;
          _results = cachedUsers;
          _isLoadingAll = false;
        });
        
        if (cachedUsers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Žiadni zákazníci. Skúste sa pripojiť k internetu a obnoviť stránku.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // Zobraz informáciu že sú to cacheované dáta
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Zobrazené cacheované dáta (${cachedUsers.length} zákazníkov). Obnovte pre najnovšie dáta.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Obnoviť',
                textColor: Colors.white,
                onPressed: () {
                  _loadAllCustomers();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAll = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba pri načítaní z cache: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _filterUsers(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = _allUsers;
      });
      return;
    }

    final lowerQuery = query.toLowerCase().trim();
    final isNumeric = int.tryParse(query) != null;

    setState(() {
      _results = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final surname = (user['surname'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final id = user['id']?.toString() ?? '';
        
        return name.contains(lowerQuery) ||
            surname.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            (isNumeric && id == query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vyhľadať zákazníka'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Meno, priezvisko alebo ID',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                          });
                        },
                      ),
              ),
              onChanged: (value) {
                // Filtrovať lokálne
                _filterUsers(value);
              },
            ),
          ),
          Expanded(
            child: _isLoadingAll
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _results.isEmpty
                    ? Center(
                          child: Text(
                          _searchController.text.isEmpty
                              ? 'Načítavam zákazníkov...'
                              : 'Žiadni zákazníci',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final name = (user['name'] ?? '').toString();
                      final surname = (user['surname'] ?? '').toString();
                      final id = user['id']?.toString() ?? 'N/A';
                      final points = user['total_points'] ?? 0;
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF6B35),
                            child: Text(
                              initial,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('$name $surname', style: const TextStyle(color: Colors.white)),
                          subtitle: Text('ID: $id • $points bodov', style: const TextStyle(color: Colors.white70)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddPointsScreen(customer: user),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


