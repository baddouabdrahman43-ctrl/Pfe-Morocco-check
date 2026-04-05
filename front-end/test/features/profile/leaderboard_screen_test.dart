import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mor_che_frontend/core/network/api_service.dart';
import 'package:mor_che_frontend/features/auth/presentation/auth_provider.dart';
import 'package:mor_che_frontend/features/profile/presentation/leaderboard_screen.dart';
import 'package:mor_che_frontend/features/profile/presentation/models/leaderboard_entry.dart';
import 'package:mor_che_frontend/shared/models/user.dart';
import 'package:provider/provider.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets(
    'affiche les donnees du leaderboard et met en avant l utilisateur courant',
    (WidgetTester tester) async {
      final authProvider = AuthProvider(
        authRepository: FakeAuthRepository(
          currentUser: const User(
            id: 7,
            firstName: 'Fatima',
            lastName: 'Alami',
            email: 'fatima@example.com',
          ),
        ),
      );
      await authProvider.login('fatima@example.com', 'password123');

      final apiService = FakeApiService(
        leaderboardResult: const PaginatedResult<LeaderboardEntry>(
          items: <LeaderboardEntry>[
            LeaderboardEntry(
              id: '7',
              firstName: 'Fatima',
              lastName: 'Alami',
              profilePicture: null,
              points: 1200,
              level: 12,
              rank: 'GOLD',
              checkinsCount: 24,
              reviewsCount: 9,
            ),
            LeaderboardEntry(
              id: '8',
              firstName: 'Ahmed',
              lastName: 'Benali',
              profilePicture: null,
              points: 800,
              level: 8,
              rank: 'SILVER',
              checkinsCount: 12,
              reviewsCount: 4,
            ),
          ],
          page: 1,
          limit: 20,
          total: 2,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: MaterialApp(home: LeaderboardScreen(apiService: apiService)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Classement communautaire'), findsOneWidget);
      expect(find.text('Fatima Alami'), findsWidgets);
      expect(find.text('Ahmed Benali'), findsWidgets);
    },
  );
}
