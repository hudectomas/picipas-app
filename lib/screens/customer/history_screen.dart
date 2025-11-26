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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await ApiService.get('/history');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend vracia paginate() čo má 'data' kľúč
        final historyList = data['data'] as List? ?? data as List? ?? [];
        setState(() {
          _history = historyList
              .map((item) => DrinkingHistory.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Chyba pri načítaní histórie';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Chyba: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('História pitia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          child: const Text('Skúsiť znova'),
                        ),
                      ],
                    ),
                  )
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, color: Colors.white38, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Zatiaľ žiadna história',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Vaša história pitia sa zobrazí tu',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: const Color(0xFFFF6B35),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final entry = _history[index];
                            return Card(
                              color: const Color(0xFF3D3D3D),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${entry.quantity}x ${entry.drink?.unit ?? 'ks'} • ${entry.pointsEarned} bodov',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      DateFormat('dd.MM.yyyy HH:mm').format(entry.consumedAt),
                                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '+${entry.pointsEarned}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
