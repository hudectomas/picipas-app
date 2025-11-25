import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import '../../models/drink.dart';
import 'dart:convert';

class AddPointsScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const AddPointsScreen({super.key, required this.customer});

  @override
  State<AddPointsScreen> createState() => _AddPointsScreenState();
}

class _AddPointsScreenState extends State<AddPointsScreen> {
  List<Drink> _drinks = [];
  Drink? _selectedDrink;
  int _quantity = 1;
  bool _isLoading = false;
  bool _drinksLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    final offlineService = OfflineService();
    final isOnline = await offlineService.isOnline();

    try {
      if (isOnline) {
        final response = await ApiService.get('/drinks');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final drinks = (data['drinks'] as List)
              .map((item) => Drink.fromJson(item))
              .toList();
          
          // Cacheovať nápoje
          await offlineService.cacheDrinks((data['drinks'] as List).cast<Map<String, dynamic>>());
          
          setState(() {
            _drinks = drinks;
            _drinksLoading = false;
          });
        }
      } else {
        // Offline - načítať z cache
        final cachedDrinks = await offlineService.getCachedDrinks();
        setState(() {
          _drinks = cachedDrinks.map((item) => Drink.fromJson(item)).toList();
          _drinksLoading = false;
        });
      }
    } catch (e) {
      // Ak online zlyhá, skúsiť offline
      try {
        final cachedDrinks = await offlineService.getCachedDrinks();
        setState(() {
          _drinks = cachedDrinks.map((item) => Drink.fromJson(item)).toList();
          _drinksLoading = false;
        });
      } catch (offlineError) {
        setState(() {
          _drinksLoading = false;
        });
      }
    }
  }

  int _calculatePoints() {
    if (_selectedDrink == null) return 0;
    return (_selectedDrink!.alcoholPercentage * 2.5 * _quantity).round();
  }

  Future<void> _addPoints() async {
    if (_selectedDrink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyberte nápoj')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final offlineService = OfflineService();
    final isOnline = await offlineService.isOnline();
    final pointsEarned = _calculatePoints();

    try {
      if (isOnline) {
        // Online - skúsiť pridať na server
        final response = await ApiService.post('/points/add', {
          'user_id': widget.customer['id'],
          'drink_id': _selectedDrink!.id,
          'quantity': _quantity,
        });

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Body boli úspešne pridané'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          final data = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Chyba'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Offline - uložiť lokálne
        await offlineService.saveOfflinePoints(
          userId: widget.customer['id'],
          drinkId: _selectedDrink!.id,
          quantity: _quantity,
          pointsEarned: pointsEarned,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Body uložené offline. Synchronizujú sa automaticky keď sa internet vráti.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Ak online zlyhá, skúsiť offline
      if (isOnline) {
        try {
          await offlineService.saveOfflinePoints(
            userId: widget.customer['id'],
            drinkId: _selectedDrink!.id,
            quantity: _quantity,
            pointsEarned: pointsEarned,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Body uložené offline. Synchronizujú sa automaticky.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (offlineError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chyba: $offlineError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pridať body'),
      ),
      body: _drinksLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.customer['name']} ${widget.customer['surname']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${widget.customer['id']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aktuálne body: ${widget.customer['total_points']}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Vyberte nápoj',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._drinks.map((drink) {
                    final isSelected = _selectedDrink?.id == drink.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSelected
                          ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                          : null,
                      child: ListTile(
                        leading: const Icon(Icons.local_bar),
                        title: Text(drink.name),
                        subtitle: Text(
                          '${drink.alcoholPercentage}% • ${drink.pointsPerUnit} bodov/${drink.unit}',
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFFFF6B35))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedDrink = drink;
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text(
                    'Množstvo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: const Icon(Icons.add_circle),
                      ),
                      const Spacer(),
                      Text(
                        '${_calculatePoints()} bodov',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addPoints,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Pridať body'),
                  ),
                ],
              ),
            ),
    );
  }
}

