import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../map/presentation/map_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../sites/presentation/sites_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _tabsFor(bool isAuthenticated) => const [
    MapScreen(),
    SitesListScreen(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    final authProvider = context.read<AuthProvider>();

    if (index == 2 && !authProvider.isAuthenticated) {
      context.push('/login');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    final tabs = _tabsFor(isAuthenticated);
    final safeIndex = _selectedIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Carte',
              ),
              NavigationDestination(
                icon: Icon(Icons.ballot_outlined),
                selectedIcon: Icon(Icons.ballot),
                label: 'Explorer',
              ),
              NavigationDestination(
                icon: Icon(
                  isAuthenticated
                      ? Icons.person_outline_rounded
                      : Icons.login_rounded,
                ),
                selectedIcon: Icon(
                  isAuthenticated ? Icons.person_rounded : Icons.login_rounded,
                ),
                label: isAuthenticated ? 'Profil' : 'Connexion',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
