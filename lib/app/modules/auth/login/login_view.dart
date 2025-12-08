// FILE: lib/app/modules/auth/login/login_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';

/// Login view
class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final authService = Get.find<AuthService>();
    final success = await authService.signIn(
      _emailController.text,
      _passwordController.text,
    );
    
    if (success) {
      final role = await authService.getCurrentUserRole();
      if (role == 'admin') {
        Get.offAllNamed(AppRoutes.ADMIN_LAYOUT);
      } else {
        Get.offAllNamed(AppRoutes.TENANT_LAYOUT);
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Kos Bae',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Selamat datang kembali!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Email field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),
              
              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              
              const SizedBox(height: 24),
              
              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppTheme.pastelBlue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Dev hint
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightYellow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dev Mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('admin@kosbae.com → Admin'),
                    Text('tenant@kosbae.com → Tenant'),
                    Text('Any password works'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
