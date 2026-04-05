import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mor_che_frontend/features/sites/presentation/checkin_screen.dart';
import 'package:mor_che_frontend/features/sites/presentation/sites/site.dart';
import 'package:mor_che_frontend/features/sites/presentation/sites_provider.dart';

void main() {
  testWidgets('affiche message distance trop grande', (
    WidgetTester tester,
  ) async {
    final provider = SitesProvider(
      initialSites: const <Site>[
        Site(
          id: '1',
          name: 'Koutoubia',
          description: 'Mosquee historique',
          category: 'Monument',
          imageUrl: '',
          address: 'Marrakech',
          city: 'Marrakech',
          region: 'Marrakech-Safi',
          latitude: 31.6248,
          longitude: -7.9892,
          freshnessScore: 85,
          rating: 4.5,
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SitesProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: CheckinScreen(
            siteId: '1',
            skipLocationCheckForTest: true,
            mockDistanceForTest: 245,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('trop loin'), findsOneWidget);
  });
}
