import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/colors.dart';
import '../../utils/user_provider.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';
import '../schools/screens/school_list_screen.dart';
import '../test/screens/exam_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

int _selectedIndex = 0;

class _MainScreenState extends State<MainScreen> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _screens = [_buildHomeScreen(), const ProfileScreen()];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeScreen() {
    // Use Consumer to only rebuild when user changes
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return AuthScreen();
        }

        if (user.email?.endsWith('@admin.edu') ?? false) {
          return SchoolsScreen();
        }

        return ExamListScreen();
      },
    );
  }
}
