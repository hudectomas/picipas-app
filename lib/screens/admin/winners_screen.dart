import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  List<dynamic> _prizes = [];
  List<dynamic> _winners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrizes();
    _loadWinners();
  }

  Future<void> _loadPrizes() async {
    try {
      final response = await ApiService.get('/prizes');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prizes = data['prizes'];
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadWinners() async {
    try {
      final response = await ApiService.get('/winners');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _winners = data['winners'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _drawWinners(int prizeId) async {
    final countController = TextEditingController(text: '1');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Vylosovať víťazov', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: countController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Počet víťazov',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Losovať'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final response = await ApiService.post('/winners/draw', {
          'prize_id': prizeId,
          'count': int.parse(countController.text),
        });

        if (response.statusCode == 201) {
          _loadWinners();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Víťazi boli vylosovaní'),
                backgroundColor: Colors.green,
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
        title: const Text('Losovanie víťazov'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Ceny',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _prizes.length,
                          itemBuilder: (context, index) {
                            final prize = _prizes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  child: Text(
                                    '${prize['position']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(prize['name'], style: const TextStyle(color: Colors.white)),
                                subtitle: Text(prize['description'], style: const TextStyle(color: Colors.white70)),
                                trailing: ElevatedButton(
                                  onPressed: () => _drawWinners(prize['id']),
                                  child: const Text('Losovať'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Víťazi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _winners.isEmpty
                            ? const Center(
                                child: Text('Zatiaľ žiadni víťazi', style: TextStyle(color: Colors.white70)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _winners.length,
                                itemBuilder: (context, index) {
                                  final winner = _winners[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.emoji_events,
                                        color: Color(0xFFFF6B35),
                                      ),
                                      title: Text(
                                        '${winner['user']['name']} ${winner['user']['surname']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        winner['prize']['name'],
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      trailing: winner['notified']
                                          ? const Icon(Icons.email, color: Colors.green)
                                          : const Icon(Icons.email_outlined),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}






