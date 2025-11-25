import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/drink.dart';
import 'dart:convert';

class DrinksScreen extends StatefulWidget {
  const DrinksScreen({super.key});

  @override
  State<DrinksScreen> createState() => _DrinksScreenState();
}

class _DrinksScreenState extends State<DrinksScreen> {
  List<Drink> _drinks = [];
  bool _isLoading = true;

  String _formatDrinkInfo(Drink drink) {
    final parts = <String>[];
    
    // Obsah alkoholu
    parts.add('${drink.alcoholPercentage.toStringAsFixed(drink.alcoholPercentage.truncateToDouble() == drink.alcoholPercentage ? 0 : 1)}%');
    
    // Body za jednotku
    parts.add('${drink.pointsPerUnit} bodov/${drink.unit}');
    
    // Množstvo v ml (ak je vyplnené)
    if (drink.volumeMl != null) {
      parts.add('${drink.volumeMl}ml');
    }
    
    return parts.join(' • ');
  }

  @override
  void initState() {
    super.initState();
    _loadDrinks();
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.get('/admin/drinks');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _drinks = (data['drinks'] as List)
              .map((item) => Drink.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba pri načítaní nápojov: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _showEditDrinkDialog(Drink drink) async {
    final nameController = TextEditingController(text: drink.name);
    final alcoholController = TextEditingController(text: drink.alcoholPercentage.toString());
    final pointsController = TextEditingController(text: drink.pointsPerUnit.toString());
    final unitController = TextEditingController(text: drink.unit);
    final volumeMlController = TextEditingController(text: drink.volumeMl?.toString() ?? '');
    final descriptionController = TextEditingController(text: drink.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDrinkDialog(
        title: 'Upraviť nápoj',
        nameController: nameController,
        alcoholController: alcoholController,
        pointsController: pointsController,
        unitController: unitController,
        volumeMlController: volumeMlController,
        descriptionController: descriptionController,
        submitText: 'Uložiť',
      ),
    );

    if (result == true) {
      try {
        final response = await ApiService.put('/admin/drinks/${drink.id}', {
          'name': nameController.text.trim(),
          'alcohol_percentage': double.parse(alcoholController.text.trim()),
          'points_per_unit': int.parse(pointsController.text.trim()),
          'unit': unitController.text.trim(),
          'volume_ml': volumeMlController.text.trim().isEmpty ? null : int.parse(volumeMlController.text.trim()),
          'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        });

        if (response.statusCode == 200) {
          await _loadDrinks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nápoj bol upravený'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final errorData = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chyba: ${errorData['message'] ?? 'Neznáma chyba'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(Drink drink) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Vymazať nápoj?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Naozaj chcete vymazať nápoj "${drink.name}"? Táto akcia sa nedá vrátiť späť.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Vymazať'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final response = await ApiService.delete('/admin/drinks/${drink.id}');

        if (response.statusCode == 200) {
          await _loadDrinks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nápoj bol vymazaný'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final errorData = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chyba: ${errorData['message'] ?? 'Neznáma chyba'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDrinkDialog({
    required String title,
    required TextEditingController nameController,
    required TextEditingController alcoholController,
    required TextEditingController pointsController,
    required TextEditingController unitController,
    required TextEditingController volumeMlController,
    required TextEditingController descriptionController,
    required String submitText,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D2D),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Názov *',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alcoholController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Obsah alkoholu (%) *',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Body za jednotku *',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Jednotka (ks, dl, atď.) *',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: volumeMlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Množstvo v ml (mililitroch)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
                hintText: 'Napríklad: 330 (pre plechovku)',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Popis',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Zrušiť', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            // Validácia formulára
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prosím vyplňte názov nápoja'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (alcoholController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prosím vyplňte obsah alkoholu'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (pointsController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prosím vyplňte body za jednotku'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (unitController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prosím vyplňte jednotku'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validácia číselných hodnôt
            try {
              final alcoholValue = double.parse(alcoholController.text.trim());
              if (alcoholValue < 0 || alcoholValue > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Obsah alkoholu musí byť medzi 0 a 100%'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Obsah alkoholu musí byť platné číslo'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            try {
              final pointsValue = int.parse(pointsController.text.trim());
              if (pointsValue < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Body musia byť kladné číslo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Body musia byť platné celé číslo'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (volumeMlController.text.trim().isNotEmpty) {
              try {
                final volumeValue = int.parse(volumeMlController.text.trim());
                if (volumeValue < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Množstvo v ml musí byť kladné číslo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Množstvo v ml musí byť platné celé číslo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }

            Navigator.pop(context, true);
          },
          child: Text(submitText),
        ),
      ],
    );
  }

  Future<void> _showAddDrinkDialog() async {
    final nameController = TextEditingController();
    final alcoholController = TextEditingController();
    final pointsController = TextEditingController();
    final unitController = TextEditingController(text: 'ks');
    final volumeMlController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDrinkDialog(
        title: 'Nový nápoj',
        nameController: nameController,
        alcoholController: alcoholController,
        pointsController: pointsController,
        unitController: unitController,
        volumeMlController: volumeMlController,
        descriptionController: descriptionController,
        submitText: 'Vytvoriť',
      ),
    );

    if (result == true) {
      try {
        final response = await ApiService.post('/admin/drinks', {
          'name': nameController.text.trim(),
          'alcohol_percentage': double.parse(alcoholController.text.trim()),
          'points_per_unit': int.parse(pointsController.text.trim()),
          'unit': unitController.text.trim(),
          'volume_ml': volumeMlController.text.trim().isEmpty ? null : int.parse(volumeMlController.text.trim()),
          'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        });

        if (response.statusCode == 201) {
          await _loadDrinks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nápoj bol vytvorený'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final errorData = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chyba: ${errorData['message'] ?? 'Neznáma chyba'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chyba: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Správa nápojov'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drinks.isEmpty
              ? const Center(
                  child: Text(
                    'Žiadne nápoje',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drinks.length,
                  itemBuilder: (context, index) {
                    final drink = _drinks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.local_bar, color: Color(0xFFFF6B35)),
                        title: Text(drink.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              _formatDrinkInfo(drink),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (drink.description != null && drink.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                drink.description!,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              drink.active ? Icons.check_circle : Icons.cancel,
                              color: drink.active ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFFFF6B35)),
                              onPressed: () => _showEditDrinkDialog(drink),
                              tooltip: 'Upraviť',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmDialog(drink),
                              tooltip: 'Vymazať',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDrinkDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
