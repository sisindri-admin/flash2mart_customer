import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logout Function with Navigation
  Future<void> handleLogout(BuildContext context) async {
    try {
      // 1. Firebase నుండి Sign Out చేస్తుంది
      await _auth.signOut();

      if (context.mounted) {
        // 2. SnackBar ద్వారా మెసేజ్ చూపుతుంది
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged out successfully!"),
            backgroundColor: Color(0xFF00875A),
          ),
        );

        // 3. పాత స్క్రీన్ లన్నింటినీ తీసివేసి Login / Auth Screen కి రీడైరెక్ట్ చేస్తుంది
        // మీ లాగిన్ స్క్రీన్ రూట్ పేరు '/login' లేదా మీ ప్రాజెక్ట్ డెసిగ్నేషన్ ప్రకారం మార్చండి
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}