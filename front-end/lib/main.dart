import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/firebase/app_firebase.dart';
import 'core/notifications/notification_service.dart';
import 'core/offline/pending_sync_service.dart';
import 'core/router/app_deep_link_service.dart';
import 'core/security/biometric_auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_service.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/map/presentation/map_provider.dart';
import 'features/sites/presentation/sites_provider.dart';

final AuthProvider appAuthProvider = AuthProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppFirebase.initialize();
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }
  await StorageService().init();
  await NotificationService.instance.init();
  await NotificationService.instance.syncReminderPreference();
  final initialLocation =
      await AppDeepLinkService.resolveInitialLocation() ?? '/';
  final app = MoroccoCheckApp(
    authProvider: appAuthProvider,
    initialLocation: initialLocation,
  );

  if (AppConstants.sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = AppConstants.sentryDsn;
      options.environment = AppConstants.appEnvironment;
      options.tracesSampleRate = AppConstants.sentryTracesSampleRate;
      options.sendDefaultPii = false;
    }, appRunner: () => runApp(app));
    return;
  }

  runApp(app);
}

class MoroccoCheckApp extends StatefulWidget {
  final AuthProvider authProvider;
  final String initialLocation;

  const MoroccoCheckApp({
    super.key,
    required this.authProvider,
    required this.initialLocation,
  });

  @override
  State<MoroccoCheckApp> createState() => _MoroccoCheckAppState();
}

class _MoroccoCheckAppState extends State<MoroccoCheckApp>
    with WidgetsBindingObserver {
  late final router = AppRouter.createRouter(
    widget.authProvider,
    initialLocation: widget.initialLocation,
  );
  bool _isUnlockPromptVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppDeepLinkService.attach(router);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppDeepLinkService.detach();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.authProvider.isAuthenticated) {
      PendingSyncService.instance.syncAll();
      _guardWithBiometricsIfNeeded();
    }
  }

  Future<void> _guardWithBiometricsIfNeeded() async {
    if (_isUnlockPromptVisible) {
      return;
    }

    final storage = StorageService();
    if (!storage.getBiometricAuthEnabled()) {
      return;
    }

    final isAvailable = await BiometricAuthService.instance.isAvailable();
    if (!isAvailable || !mounted) {
      return;
    }

    _isUnlockPromptVisible = true;
    final unlocked = await BiometricAuthService.instance
        .authenticateForUnlock();
    if (unlocked || !mounted) {
      _isUnlockPromptVisible = false;
      return;
    }

    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verification requise'),
        content: const Text(
          'La protection biométrique est active. Verifiez votre identite pour retrouver votre session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Se deconnecter'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );

    _isUnlockPromptVisible = false;

    if (shouldRetry == true) {
      await _guardWithBiometricsIfNeeded();
      return;
    }

    await widget.authProvider.logout();
    if (!mounted) {
      return;
    }
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => SitesProvider()),
      ],
      child: ValueListenableBuilder<String>(
        valueListenable: StorageService().preferredLanguageNotifier,
        builder: (context, languageCode, child) {
          return MaterialApp.router(
            title: 'MoroccoCheck',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
            locale: Locale(languageCode),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
