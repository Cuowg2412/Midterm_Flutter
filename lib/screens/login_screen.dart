import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/theme_controller.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/password_strength_bar.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hotenController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _hotenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        final regResult = await AuthService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _hotenController.text.trim(),
        );
        if (!mounted) return;
        if (regResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Đang đăng nhập...'),
              backgroundColor: Colors.green,
            ),
          );
          final loginResult = await AuthService.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (!mounted) return;
          if (loginResult['success']) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(regResult['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final result = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!mounted) return;
        if (result['success']) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối server (${ApiConfig.serverUrl}): $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showServerConfigDialog() async {
    final controller = TextEditingController(text: ApiConfig.serverUrl);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình Server API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mặc định:\n• Web: http://localhost:3000\n• Android Emulator: http://10.0.2.2:3000\n• Điện thoại thật: http://<IP-LAN-MAY-TINH>:3000',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApiConfig.setCustomServerUrl(null);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Mặc định'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiConfig.setCustomServerUrl(controller.text);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              ThemeController.isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.blue,
            ),
            tooltip: 'Đổi giao diện Sáng / Tối',
            onPressed: () => ThemeController.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blue),
            tooltip: 'Cấu hình Server URL',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 76,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isRegisterMode ? 'ĐĂNG KÝ ADMIN' : 'ĐĂNG NHẬP ADMIN',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quản lý người dùng - MongoDB Atlas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_isRegisterMode) ...[
                        TextFormField(
                          controller: _hotenController,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => _isRegisterMode
                              ? FormValidators.validateName(value)
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: FormValidators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onFieldSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_isRegisterMode) setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: FormValidators.validatePassword,
                      ),
                      if (_isRegisterMode)
                        PasswordStrengthBar(
                            password: _passwordController.text),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isRegisterMode ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                          });
                        },
                        child: Text(
                          _isRegisterMode
                              ? 'Đã có tài khoản? Đăng nhập ngay'
                              : 'Chưa có tài khoản? Đăng ký mới',
                        ),
                      ),
                      if (!_isRegisterMode) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tài khoản mẫu: admin@gmail.com / 123456',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
