import 'package:flutter/material.dart';
import 'package:my_app/screens/doctor/doctor_home_screen.dart';
import 'package:my_app/screens/doctor/doctor_patients_screen.dart';
import 'package:my_app/screens/doctor/doctor_schedule_screen.dart';

class DoctorMainShell extends StatefulWidget {
  const DoctorMainShell({super.key});

  @override
  State<DoctorMainShell> createState() => _DoctorMainShellState();
}

class _DoctorMainShellState extends State<DoctorMainShell> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _pages => [
    DoctorHomeScreen(
      onOpenPatients: () => _goToTab(1),
      onOpenSchedule: () => _goToTab(2),
    ),
    const DoctorPatientsScreen(),
    const DoctorScheduleScreen(),
  ];

  Widget _tabTransition(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: FadeTransition(opacity: animation, child: child),
      builder: (context, child) {
        final isForward = animation.status == AnimationStatus.forward ||
            animation.status == AnimationStatus.completed;
        final offset = isForward
            ? Offset(1.0 - animation.value, 0.0)
            : Offset(-0.08 * (1.0 - animation.value), 0.0);
        return FractionalTranslation(translation: offset, child: child!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: _tabTransition,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_2_outlined),
              activeIcon: Icon(Icons.groups_2),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
          ],
        ),
      ),
    );
  }
}
