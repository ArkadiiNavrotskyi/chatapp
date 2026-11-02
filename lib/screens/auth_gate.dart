import 'package:flutter/material.dart';

import '../backend/local_auth.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

/// Shows the chat only to authenticated users, otherwise the login screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LocalUser?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return ChatScreen(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}
