import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../splash/splash_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/professional/presentation/create_site_screen.dart';
import '../../features/professional/presentation/professional_claim_site_screen.dart';
import '../../features/professional/presentation/professional_hub_screen.dart';
import '../../features/professional/presentation/professional_site_detail_screen.dart';
import '../../features/professional/presentation/professional_sites_screen.dart';
import '../../features/professional/models/professional_site.dart';
import '../../features/profile/presentation/badges_catalog_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/leaderboard_screen.dart';
import '../../features/profile/presentation/my_checkins_screen.dart';
import '../../features/profile/presentation/my_reviews_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/public_user_profile_screen.dart';
import '../../shared/models/user.dart';
import '../../features/sites/presentation/sites_list_screen.dart';
import '../../features/sites/presentation/site_detail_screen.dart';
import '../../features/sites/presentation/checkin_screen.dart';
import '../../features/sites/presentation/checkin_detail_screen.dart';
import '../../features/sites/presentation/add_review_screen.dart';
import '../../debug/debug_home.dart';

class AppRouter {
  static GoRouter createRouter(
    AuthProvider authProvider, {
    String initialLocation = '/',
  }) {
    bool canAccessSiteManagement(String? role) {
      return role == 'PROFESSIONAL' || role == 'ADMIN';
    }

    bool isProtectedRoute(String location) {
      return location == '/profile' ||
          location == '/profile/edit' ||
          location == '/profile/password' ||
          location == '/profile/checkins' ||
          location == '/profile/reviews' ||
          location == '/profile/badges' ||
          location == '/leaderboard' ||
          location.startsWith('/users/') ||
          location.startsWith('/professional/sites') ||
          location.startsWith('/professional/claims') ||
          location.startsWith('/checkin/') ||
          location.startsWith('/checkins/') ||
          location.startsWith('/review/');
    }

    bool isProfessionalRoute(String location) {
      return location.startsWith('/professional/sites') ||
          location.startsWith('/professional/claims');
    }

    bool isAuthRoute(String location) {
      return location == '/welcome' ||
          location == '/login' ||
          location == '/register';
    }

    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isAuthenticated = authProvider.isAuthenticated;

        if (location == '/') {
          return null;
        }

        if (!isAuthenticated && isProtectedRoute(location)) {
          return '/login';
        }

        if (isAuthenticated &&
            isProfessionalRoute(location) &&
            !canAccessSiteManagement(authProvider.user?.role)) {
          return '/home';
        }

        if (isAuthenticated && isAuthRoute(location)) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          name: 'profile-edit',
          builder: (context, state) {
            final user = state.extra as User;
            return EditProfileScreen(initialUser: user);
          },
        ),
        GoRoute(
          path: '/profile/password',
          name: 'profile-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/profile/checkins',
          name: 'profile-checkins',
          builder: (context, state) => const MyCheckinsScreen(),
        ),
        GoRoute(
          path: '/profile/reviews',
          name: 'profile-reviews',
          builder: (context, state) => const MyReviewsScreen(),
        ),
        GoRoute(
          path: '/profile/badges',
          name: 'profile-badges-catalog',
          builder: (context, state) => const BadgesCatalogScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          name: 'leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/users/:id',
          name: 'public-user-profile',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return PublicUserProfileScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/professional',
          name: 'professional-hub',
          builder: (context, state) => const ProfessionalHubScreen(),
        ),
        GoRoute(
          path: '/professional/claims',
          name: 'professional-claims',
          builder: (context, state) => const ProfessionalClaimSiteScreen(),
        ),
        GoRoute(
          path: '/professional/sites',
          name: 'professional-sites',
          builder: (context, state) => const ProfessionalSitesScreen(),
        ),
        GoRoute(
          path: '/professional/sites/new',
          name: 'professional-site-create',
          builder: (context, state) => const CreateSiteScreen(),
        ),
        GoRoute(
          path: '/professional/sites/:id/edit',
          name: 'professional-site-edit',
          builder: (context, state) {
            final site = state.extra as ProfessionalSite?;
            return CreateSiteScreen(initialSite: site);
          },
        ),
        GoRoute(
          path: '/professional/sites/:id',
          name: 'professional-site-detail',
          builder: (context, state) {
            final siteId = state.pathParameters['id']!;
            return ProfessionalSiteDetailScreen(siteId: siteId);
          },
        ),
        GoRoute(
          path: '/sites',
          name: 'sites',
          builder: (context, state) => const SitesListScreen(),
        ),
        GoRoute(
          path: '/sites/:id',
          name: 'site-detail',
          builder: (context, state) {
            final siteId = state.pathParameters['id'];
            return SiteDetailScreen(siteId: siteId);
          },
        ),
        GoRoute(
          path: '/site/:id',
          name: 'site-detail-alt',
          builder: (context, state) {
            final siteId = state.pathParameters['id'];
            return SiteDetailScreen(siteId: siteId);
          },
        ),
        GoRoute(
          path: '/checkin/:id',
          name: 'checkin',
          builder: (context, state) {
            final siteId = state.pathParameters['id'];
            return CheckinScreen(siteId: siteId);
          },
        ),
        GoRoute(
          path: '/checkins/:id',
          name: 'checkin-detail',
          builder: (context, state) {
            final checkinId = state.pathParameters['id']!;
            return CheckinDetailScreen(checkinId: checkinId);
          },
        ),
        GoRoute(
          path: '/review/:id',
          name: 'add-review',
          builder: (context, state) {
            final siteId = state.pathParameters['id'];
            return AddReviewScreen(siteId: siteId);
          },
        ),
        if (kDebugMode)
          GoRoute(
            path: '/debug',
            name: 'debug',
            builder: (context, state) => const DebugHomeScreen(),
          ),
      ],
    );
  }
}
