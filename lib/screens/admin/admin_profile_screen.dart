import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user!;

          return Container(
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
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: const Icon(Icons.email, color: Colors.white),
                        title: const Text('Email', style: TextStyle(color: Colors.white)),
                        subtitle: Text(user.email, style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.white),
                        title: const Text('Dátum narodenia', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          user.dateOfBirth != null
                              ? '${user.dateOfBirth!.day}.${user.dateOfBirth!.month}.${user.dateOfBirth!.year}'
                              : 'Nezadané',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: const Icon(Icons.lock, color: Colors.white),
                        title: const Text('Zmeniť heslo', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white),
                        onTap: () {
                          _showChangePasswordDialog(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: const Icon(Icons.email_outlined, color: Colors.white),
                        title: const Text('Zmeniť email', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white),
                        onTap: () {
                          _showChangeEmailDialog(context, user.email);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/',
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Odhlásiť sa'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmeniť heslo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Staré heslo',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nové heslo',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Potvrdenie nového hesla',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušiť'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funkcia zmeny hesla bude čoskoro dostupná'),
                ),
              );
            },
            child: const Text('Zmeniť'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, String currentEmail) {
    final emailController = TextEditingController(text: currentEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmeniť email'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Nový email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušiť'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funkcia zmeny emailu bude čoskoro dostupná'),
                ),
              );
            },
            child: const Text('Zmeniť'),
          ),
        ],
      ),
    );
  }
}

