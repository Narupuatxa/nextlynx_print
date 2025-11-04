import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'O email é obrigatório';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Insira um email válido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'A senha é obrigatória';
    if (value.trim().length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'O nome é obrigatório';
    return null;
  }

  String? _validateRole(String? value) {
    final trimmed = value?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) return 'A função é obrigatória';
    if (trimmed != 'admin' && trimmed != 'employee') return 'Função deve ser "admin" ou "employee"';
    return null;
  }

  Future<void> _signIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_validateEmail(email) != null || _validatePassword(password) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verifique email e senha', style: GoogleFonts.roboto(color: Colors.white)),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    try {
      await authProvider.signIn(email, password);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    } on AuthApiException catch (e) {
      String message = e.message;
      if (e.code == 'invalid_credentials') {
        message = 'Credenciais inválidas';
      } else if (e.code == 'email_not_confirmed') {
        message = 'Email não confirmado';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: GoogleFonts.roboto(color: Colors.white)), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e', style: GoogleFonts.roboto(color: Colors.white)), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _signUp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final ageText = _ageController.text.trim();
    final phone = _phoneController.text.trim();
    final roleText = _roleController.text.trim().toLowerCase();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final age = int.tryParse(ageText);

    if (_validateName(name) != null ||
        _validateEmail(email) != null ||
        _validatePassword(password) != null ||
        _validateRole(roleText) != null ||
        age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente', style: GoogleFonts.roboto(color: Colors.white)), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    try {
      await authProvider.signUp(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
        address: address,
        age: age,
        role: roleText,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cadastro realizado!', style: GoogleFonts.roboto(color: Colors.white)), backgroundColor: Colors.teal.shade700),
      );

      setState(() {
        _isSignUp = false;
        _clearAllControllers();
      });
      _animationController.forward(from: 0.0);
    } on AuthApiException catch (e) {
      String message = e.message;
      if (e.code == 'user_already_exists') {
        message = 'Este email já está registrado';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: GoogleFonts.roboto(color: Colors.white)), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e', style: GoogleFonts.roboto(color: Colors.white)), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _clearAllControllers() {
    _nameController.clear();
    _addressController.clear();
    _ageController.clear();
    _phoneController.clear();
    _roleController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  void _switchToLogin() {
    setState(() {
      _isSignUp = false;
      _clearAllControllers();
    });
    _animationController.forward(from: 0.0);
  }

  void _switchToSignUp() {
    setState(() {
      _isSignUp = true;
      _clearAllControllers();
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://media.licdn.com/dms/image/v2/C4D12AQHx9KlEIwLGJw/article-cover_image-shrink_600_2000/article-cover_image-shrink_600_2000/0/1648428650639?e=2147483647&v=beta&t=MGKME6pLBCZgidc8WYWhghqp3sUOYomph6xVcEBQOjo',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.teal.shade600, width: 2),
                ),
                child: Container(
                  width: 400,
                  constraints: const BoxConstraints(maxHeight: 600),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png', height: 100, color: Colors.teal.shade800),
                        const SizedBox(height: 24),
                        Text(
                          _isSignUp ? 'Cadastrar Funcionário' : 'Bem-vindo à NextLynx',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp ? 'Crie sua conta agora' : 'Faça login para continuar',
                          style: GoogleFonts.roboto(fontSize: 18, color: Colors.purple.shade600),
                        ),
                        const SizedBox(height: 24),
                        if (_isSignUp) ...[
                          _buildTextField(_nameController, 'Nome', Icons.person),
                          const SizedBox(height: 16),
                          _buildTextField(_addressController, 'Morada', Icons.home),
                          const SizedBox(height: 16),
                          _buildTextField(_ageController, 'Idade', Icons.cake, keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                          _buildTextField(_phoneController, 'Telefone', Icons.phone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          _buildTextField(_roleController, 'Função (admin/employee)', Icons.work),
                          const SizedBox(height: 16),
                        ],
                        _buildTextField(_emailController, 'Email', Icons.email),
                        const SizedBox(height: 16),
                        _buildTextField(_passwordController, 'Senha', Icons.lock, obscureText: true),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScaleButton(
                              onPressed: _isSignUp ? _signUp : _signIn,
                              child: Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.yellowAccent]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                                ),
                                child: Center(
                                  child: Text(
                                    _isSignUp ? 'Cadastrar' : 'Entrar',
                                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(width: 16),
                              AnimatedScaleButton(
                                onPressed: _switchToLogin,
                                child: Container(
                                  width: 150,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Voltar ao Login',
                                      style: GoogleFonts.roboto(color: Colors.blueAccent.shade700, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!_isSignUp)
                          TextButton(
                            onPressed: _switchToSignUp,
                            child: Text('Criar nova conta', style: GoogleFonts.roboto(fontSize: 18, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.blueAccent.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueAccent.shade700, width: 2)),
          filled: true,
          fillColor: Colors.grey.shade100,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const AnimatedScaleButton({super.key, required this.onPressed, required this.child});

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}