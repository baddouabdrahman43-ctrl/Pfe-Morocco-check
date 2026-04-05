import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mor_che_frontend/features/auth/presentation/auth_provider.dart';
import 'package:mor_che_frontend/features/sites/presentation/site_detail_screen.dart';
import 'package:mor_che_frontend/features/sites/presentation/sites/site.dart';
import 'package:mor_che_frontend/features/sites/presentation/sites_provider.dart';
import 'package:provider/provider.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets(
    'affiche les actions bloquees et l invitation a se connecter pour un visiteur',
    (WidgetTester tester) async {
      const site = Site(
        id: '1',
        name: 'Pure Passion Agadir',
        description: 'Lieu de test pour verifier l etat visiteur.',
        category: 'Restaurant',
        imageUrl: '',
        address: 'Marina d Agadir',
        city: 'Agadir',
        region: 'Souss-Massa',
        latitude: 30.42,
        longitude: -9.60,
        freshnessScore: 88,
        rating: 4.5,
      );

      final authProvider = AuthProvider(
        authRepository: FakeAuthRepository(currentUser: null),
      );
      final sitesProvider = SitesProvider(initialSites: const <Site>[site]);
      final apiService = FakeApiService(siteDetail: site);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<SitesProvider>.value(value: sitesProvider),
          ],
          child: MaterialApp(
            home: SiteDetailScreen(siteId: '1', apiService: apiService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connectez-vous pour contribuer'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Ajouter un avis'), findsOneWidget);

      final checkInButton = tester.widget<ElevatedButton>(
        find.byWidgetPredicate(
          (widget) => widget is ElevatedButton && widget.onPressed == null,
        ),
      );
      final reviewButton = tester.widget<OutlinedButton>(
        find.byWidgetPredicate(
          (widget) => widget is OutlinedButton && widget.onPressed == null,
        ),
      );

      expect(checkInButton.onPressed, isNull);
      expect(reviewButton.onPressed, isNull);
    },
  );
}
