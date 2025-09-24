// screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _sendPasswordResetEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    // The StreamBuilder in main.dart will handle navigation
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        ListTile(
          leading: const Icon(Icons.lock_reset),
          title: const Text('Change Password'),
          subtitle: const Text('Send a password reset link to your email'),
          onTap: () => _sendPasswordResetEmail(context),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text(
            'Logout',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}