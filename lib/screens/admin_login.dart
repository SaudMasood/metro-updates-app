import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_panel.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final auth = AuthService();

  bool isLoading = false;
  bool showPassword = false;
  String errorMessage = '';
  int attemptCount = 0;
  DateTime? lockUntil;
  Timer? _lockTimer;

  @override
  void dispose() {
    _lockTimer?.cancel();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  // ── Validators ──

  String? emailValidate(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required';
    final trimmed = val.trim();
    if (!trimmed.contains('@')) return 'Email must contain @';
    if (!trimmed.split('@')[1].contains('.')) return 'Email must contain . after @';
    return null;
  }

  String? passwordValidate(String? val) {
    if (val == null || val.trim().isEmpty) return 'Password is required';
    if (val.trim().length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ── Lock Logic ──

  bool get isLocked {
    if (lockUntil == null) return false;
    if (DateTime.now().isBefore(lockUntil!)) return true;
    lockUntil = null;
    attemptCount = 0;
    return false;
  }

  String get lockTimeLeft {
    if (lockUntil == null) return '';
    final seconds = lockUntil!.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return '';
    return '$seconds sec';
  }

  // ── Live Countdown Timer ──

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isLocked) _lockTimer?.cancel();
      if (mounted) setState(() {});
    });
  }

  // ── Login ──

  Future<void> login() async {
    if (isLocked) {
      setState(() => errorMessage = 'Too many attempts. Wait $lockTimeLeft');
      return;
    }

    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await auth.login(
        emailController.text.trim(),
        passController.text.trim(),
      );

      if (!mounted) return;

      attemptCount = 0;
      lockUntil = null;
      _lockTimer?.cancel();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminPanel()),
      );

    } on FirebaseAuthException catch (e) {
      // ✅ Catch FirebaseAuthException directly — e.code is clean now
      attemptCount++;
      if (attemptCount >= 3) {
        lockUntil = DateTime.now().add(const Duration(seconds: 30));
        _startLockTimer();
      }

      final left = 3 - attemptCount;
      String friendlyError;

      debugPrint('🔥 Firebase Auth Error code: ${e.code}'); // check your console

      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
        case 'INVALID_LOGIN_CREDENTIALS':
          friendlyError = left > 0
              ? 'Invalid email or password. $left attempt(s) left.'
              : 'Invalid email or password.';
          break;
        case 'invalid-email':
          friendlyError = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          friendlyError = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          friendlyError = 'Too many attempts. Try again later.';
          break;
        case 'network-request-failed':
          friendlyError = 'No internet connection.';
          break;
        default:
          friendlyError = 'Login failed (${e.code}). Please try again.';
      }

      setState(() {
        errorMessage = friendlyError;
        isLoading = false;
      });

    } catch (e) {
      // Non-Firebase error
      debugPrint('❌ Unknown login error: $e');
      setState(() {
        errorMessage = 'Unexpected error. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Admin Login",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [

              const SizedBox(height: 30),

              // ── Icon ──
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 44,
                  color: Color(0xFF0D47A1),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Admin Access",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Only authorized admins can login",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 32),

              // ── Attempt Warning ──
              if (attemptCount > 0 && !isLocked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${3 - attemptCount} attempt(s) left before lockout',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Locked Warning ──
              if (isLocked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Locked. Try again in $lockTimeLeft',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Email Field ──
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLocked,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: emailValidate,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "admin@example.com",
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF0D47A1),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF0D47A1), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Password Field ──
              TextFormField(
                controller: passController,
                obscureText: !showPassword,
                enabled: !isLocked,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: passwordValidate,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Min 6 characters",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF0D47A1),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF0D47A1), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Colors.red, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Error Box ──
              if (errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // ── Login Button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading || isLocked ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : Text(
                    isLocked
                        ? 'Locked — Wait $lockTimeLeft'
                        : 'Login',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Back ──
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Go back to Metro Updates",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}