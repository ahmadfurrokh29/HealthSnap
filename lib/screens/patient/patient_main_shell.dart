import 'package:flutter/material.dart';
import 'package:my_app/screens/patient/patient_home_screen.dart';
import 'package:my_app/screens/patient/history_screen.dart';
import 'package:my_app/screens/patient/reports_screen.dart';
import 'package:my_app/screens/patient/profile_screen.dart';
import 'package:my_app/screens/patient/scan_screen.dart';
import 'package:my_app/screens/patient/qr_screen.dart';

class PatientMainShell extends StatefulWidget {
  const PatientMainShell({super.key});

  @override
  State<PatientMainShell> createState() => _PatientMainShellState();
}

class _PatientMainShellState extends State<PatientMainShell> {
  int _currentIndex = 0;
  bool _autoShowQr = false;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _goToProfileWithQr() {
    setState(() {
      _autoShowQr = true;
      _currentIndex = 3;
    });
  }

  List<Widget> get _pages => [
    PatientHomeScreen(onSwitchTab: _switchTab, onQrTap: _goToProfileWithQr),
    HistoryScreen(onBack: () => _switchTab(0)),
    ReportsScreen(onBack: () => _switchTab(0)),
    ProfileScreen(autoShowQr: _autoShowQr, onQrShown: () { _autoShowQr = false; }),
  ];

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: GlobalKey<NavigatorState>(),
      onGenerateRoute: (settings) {
        // Handle named routes from home screen
        switch (settings.name) {
          case '/scan':
            return MaterialPageRoute(builder: (_) => ScanScreen());
          case '/qr':
            return MaterialPageRoute(builder: (_) => const QrScreen());
          case '/history':
            return MaterialPageRoute(builder: (_) => const HistoryScreen());
          case '/reports':
            return MaterialPageRoute(builder: (_) => const ReportsScreen());
          default:
            return MaterialPageRoute(
              builder: (_) => _buildShell(),
            );
        }
      },
    );
  }

  Widget _buildShell() {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3B5BDB),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'REPORTS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
