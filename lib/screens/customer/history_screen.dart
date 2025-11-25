import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/drinking_history.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DrinkingHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await ApiService.get('/history');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _history = (data['data'] as List)
              .map((item) => DrinkingHistory.fromJson(item))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('História pitia'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Text('Zatiaľ žiadna história'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_bar,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                        title: Text(
                          entry.drink?.name ?? 'Neznámy nápoj',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${entry.quantity}x ${entry.drink?.unit ?? 'ks'} • ${entry.pointsEarned} bodov',
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(entry.consumedAt),
                              style: const TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '+${entry.pointsEarned}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

