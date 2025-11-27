import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../customer/home_screen.dart';
import '../staff/staff_home_screen.dart';
import '../admin/admin_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  DateTime? _dateOfBirth;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _updateDateOfBirth() {
    if (_selectedDay != null && _selectedMonth != null && _selectedYear != null) {
      try {
        // Validácia počtu dní v mesiaci
        final daysInMonth = DateTime(_selectedYear!, _selectedMonth! + 1, 0).day;
        if (_selectedDay! > daysInMonth) {
          setState(() {
            _dateOfBirth = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Neplatný dátum - tento mesiac má iba $daysInMonth dní')),
          );
          return;
        }

        final date = DateTime(_selectedYear!, _selectedMonth!, _selectedDay!);
        if (date.isBefore(DateTime.now()) || date.isAtSameMomentAs(DateTime.now())) {
          setState(() {
            _dateOfBirth = date;
          });
        } else {
          setState(() {
            _dateOfBirth = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dátum narodenia nemôže byť v budúcnosti')),
          );
        }
      } catch (e) {
        setState(() {
          _dateOfBirth = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Neplatný dátum')),
        );
      }
    } else {
      setState(() {
        _dateOfBirth = null;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyberte dátum narodenia')),
      );
      return;
    }
    
    // Automatická validácia veku
    final age = _calculateAge(_dateOfBirth!);
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Na registráciu musíte mať aspoň 18 rokov'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final success = await authProvider.register(
      _nameController.text.trim(),
      _surnameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _passwordConfirmationController.text,
      _dateOfBirth!,
    );

    if (!mounted) return;

    if (success && authProvider.user != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Registrácia úspešná! Vitajte v Picí pas.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      final user = authProvider.user!;
      // Navigácia na príslušnú domovskú obrazovku
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => user.isAdmin 
            ? const AdminHomeScreen()
            : user.isObsluha 
              ? const StaffHomeScreen()
              : const CustomerHomeScreen(),
        ),
        (route) => false, // Odstrániť všetky predchádzajúce obrazovky
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registrácia zlyhala'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrácia'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Meno',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Zadajte meno';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                      labelText: 'Priezvisko',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Zadajte priezvisko';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Zadajte email';
                      }
                      if (!value.contains('@')) {
                        return 'Zadajte platný email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dátum narodenia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Deň
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedDay,
                          dropdownColor: const Color(0xFF2D2D2D),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Deň',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                          ),
                          items: List.generate(31, (index) => index + 1)
                              .map((day) => DropdownMenuItem(
                                    value: day,
                                    child: Text('$day', style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDay = value;
                            });
                            _updateDateOfBirth();
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vyberte';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mesiac
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          dropdownColor: const Color(0xFF2D2D2D),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Mesiac',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                          items: [
                            {'value': 1, 'label': 'Január'},
                            {'value': 2, 'label': 'Február'},
                            {'value': 3, 'label': 'Marec'},
                            {'value': 4, 'label': 'Apríl'},
                            {'value': 5, 'label': 'Máj'},
                            {'value': 6, 'label': 'Jún'},
                            {'value': 7, 'label': 'Júl'},
                            {'value': 8, 'label': 'August'},
                            {'value': 9, 'label': 'September'},
                            {'value': 10, 'label': 'Október'},
                            {'value': 11, 'label': 'November'},
                            {'value': 12, 'label': 'December'},
                          ]
                              .map((item) => DropdownMenuItem(
                                    value: item['value'] as int,
                                    child: Text(item['label'] as String, style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMonth = value;
                            });
                            _updateDateOfBirth();
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vyberte';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Rok
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedYear,
                          dropdownColor: const Color(0xFF2D2D2D),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Rok',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                          items: List.generate(
                                  DateTime.now().year - 1950 + 1,
                                  (index) => DateTime.now().year - index)
                              .map((year) => DropdownMenuItem(
                                    value: year,
                                    child: Text('$year', style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value;
                            });
                            _updateDateOfBirth();
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vyberte';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_dateOfBirth != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final age = _calculateAge(_dateOfBirth!);
                        final isAdult = age >= 18;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vybraný dátum: ${DateFormat('dd.MM.yyyy').format(_dateOfBirth!)}',
                              style: TextStyle(
                                color: isAdult ? Colors.green : Colors.red,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAdult 
                                ? 'Vek: $age rokov ✓'
                                : 'Vek: $age rokov - Na registráciu musíte mať aspoň 18 rokov',
                              style: TextStyle(
                                color: isAdult ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: isAdult ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Heslo',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Zadajte heslo';
                      }
                      if (value.length < 8) {
                        return 'Heslo musí mať aspoň 8 znakov';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordConfirmationController,
                    obscureText: _obscurePasswordConfirmation,
                    decoration: InputDecoration(
                      labelText: 'Potvrdenie hesla',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirmation ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePasswordConfirmation = !_obscurePasswordConfirmation;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Potvrďte heslo';
                      }
                      if (value != _passwordController.text) {
                        return 'Heslá sa nezhodujú';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _register,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Registrovať sa'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




