import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Navigation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 8),
          Text(
            'Navigation Debug',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un écran à afficher',
            style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildNavigationButton(
            context: context,
            title: 'Login',
            icon: Icons.login,
            route: '/login',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildNavigationButton(
            context: context,
            title: 'Register',
            icon: Icons.person_add,
            route: '/register',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildNavigationButton(
            context: context,
            title: 'Map',
            icon: Icons.map,
            route: '/map',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildNavigationButton(
            context: context,
            title: 'Sites List',
            icon: Icons.list,
            route: '/sites',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildNavigationButton(
            context: context,
            title: 'Site Detail',
            icon: Icons.info,
            route: '/sites/1',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildNavigationButton(
            context: context,
            title: 'Profile',
            icon: Icons.person,
            route: '/profile',
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () {
        context.go(route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
