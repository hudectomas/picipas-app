import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _leaderboard = [];
  int? _currentUserRank;
  int _currentUserPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final response = await ApiService.get('/leaderboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _leaderboard = data['leaderboard'];
          _currentUserRank = data['current_user_rank'];
          _currentUserPoints = data['current_user_points'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.white;
  }

  IconData? _getRankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events;
    if (rank == 2) return Icons.workspace_premium;
    if (rank == 3) return Icons.military_tech;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rebríček'),
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
            : Column(
                children: [
                  if (_currentUserRank != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF6B35),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFFFF6B35)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vaša pozícia',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                                Text(
                                  '$_currentUserRank. miesto • $_currentUserPoints bodov',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leaderboard.length,
                      itemBuilder: (context, index) {
                        final user = _leaderboard[index];
                        final rank = user['rank'] ?? (index + 1);
                        final isTopThree = rank <= 3;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isTopThree
                              ? _getRankColor(rank).withValues(alpha: 0.15)
                              : const Color(0xFF3D3D3D),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isTopThree
                                    ? _getRankColor(rank).withValues(alpha: 0.3)
                                    : Colors.grey[700],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isTopThree
                                    ? Icon(
                                        _getRankIcon(rank),
                                        color: _getRankColor(rank),
                                        size: 28,
                                      )
                                    : Text(
                                        '$rank',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              '${user['name']} ${user['surname']}',
                              style: TextStyle(
                                fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                                color: isTopThree ? _getRankColor(rank) : Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Text(
                              '${user['total_points']} bodov',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isTopThree ? _getRankColor(rank) : const Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
