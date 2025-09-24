// screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './verify_email_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _isLoading = false;

  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    if (_isLogin) {
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          // Send a new verification email as a courtesy.
          await userCredential.user!.sendEmailVerification();
          // Immediately sign out the user because their email is not verified.
          await _auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                // *** FIXED: Provide a clearer instruction to the user. ***
                content: Text('Please verify your email to log in. A new verification link has been sent.'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isLoading = false);
          }
          // Stop execution to prevent the user from being logged in.
          return;
        }
      } on FirebaseAuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message ?? 'Authentication failed.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } else {
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        await userCredential.user!.sendEmailVerification();
        await _auth.signOut();

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const VerifyEmailScreen()),
          );
          setState(() {
            _isLogin = true;
            _isLoading = false;
          });
        }
      } on FirebaseAuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(error.message ?? 'Signup failed.'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _resetPassword() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email to reset your password.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent! Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'An error occurred.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 80),
                const SizedBox(height: 16),
                Text(
                  'LifeBand',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
                const SizedBox(height: 40),
                Card(
                  margin: const EdgeInsets.all(0),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            key: const ValueKey('email'),
                            controller: _emailController,
                            validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Please enter a valid email address.' : null,
                            onSaved: (v) => _enteredEmail = v!,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email Address'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('password'),
                            validator: (v) => (v == null || v.length < 7) ? 'Password must be at least 7 characters long.' : null,
                            onSaved: (v) => _enteredPassword = v!,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 20),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _submit,
                                  child: Text(_isLogin ? 'Login' : 'Signup'),
                                ),
                                TextButton(
                                  child: Text(_isLogin ? 'Create new account' : 'I already have an account'),
                                  onPressed: () => setState(() => _isLogin = !_isLogin),
                                ),
                                if (_isLogin)
                                  TextButton(
                                    onPressed: _resetPassword,
                                    child: const Text('Forgot Password?'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}