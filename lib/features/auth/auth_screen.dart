// lib/features/auth/auth_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'auth_repository.dart';
import '../shell/home_shell.dart';
import '../../core/config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _repo = AuthRepository();

  static const _isDev = AppConfig.env == 'dev' || AppConfig.env == 'local';

  final _email = TextEditingController(
      text: _isDev ? 'jwmatthews1126@gmail.com' : '');
  final _password = TextEditingController(
      text: _isDev ? 'testpassword123' : '');
  final _username = TextEditingController(
      text: _isDev ? 'joetest' : '');

  bool _isSignup = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    try {
      if (_isSignup) {
        await _repo.signup(
            _email.text.trim(), _password.text, _username.text.trim());
      } else {
        await _repo.signin(_email.text.trim(), _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on DioException catch (e) {
      setState(() => _error =
          e.response?.data?['error']?['message'] ?? 'Something went wrong.');
    } catch (_) {
      setState(() => _error = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_isSignup ? 'Create account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', border: OutlineInputBorder()),
                ),
                if (_isSignup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _username,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        labelText: 'Username', border: OutlineInputBorder()),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isSignup ? 'Sign up' : 'Sign in'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _isSignup = !_isSignup;
                            _error = null;
                          }),
                  child: Text(_isSignup
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}