import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mor_che_frontend/core/router/app_router.dart';
import 'package:mor_che_frontend/features/auth/presentation/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('redirige un visiteur vers login pour une route protegee', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      authRepository: FakeAuthRepository(currentUser: null),
    );
    final router = AppRouter.createRouter(
      authProvider,
      initialLocation: '/profile',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connectez-vous a votre compte'), findsOneWidget);
    expect(find.text('Profil'), findsNothing);
  });
}
