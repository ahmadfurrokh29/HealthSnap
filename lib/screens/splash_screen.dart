import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/onboarding_screen.dart';
import 'package:my_app/screens/doctor/doctor_main_shell.dart';
import 'package:my_app/screens/patient/patient_main_shell.dart';
import 'package:my_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait minimum 2s for splash AND for Firebase auth state to be ready
    final results = await Future.wait<dynamic>([
      Future.delayed(const Duration(seconds: 2)),
      FirebaseAuth.instance.authStateChanges().first,
    ]);

    if (!mounted) return;

    final user = results[1] as User?;

    if (user != null) {
      final role = await AuthService().getUserRole(user.uid);
      if (!mounted) return;
      Widget home;
      if (role == 'Patient') {
        home = const PatientMainShell();
      } else if (role == 'Doctor') {
        home = const DoctorMainShell();
      } else {
        home = const OnboardingScreen();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => home),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                'Assets/logo3.jpeg',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'HealthSnap',
              style: TextStyle(
                color: Color(0xFF3B5BDB),
                fontWeight: FontWeight.w700,
                fontSize: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
