import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/security/biometric_auth_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/spacing_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _preciseLocationEnabled = true;
  bool _technicalInfoVisible = false;
  bool _showAdvancedOptions = false;
  bool _biometricAuthEnabled = false;
  bool _biometricAuthAvailable = false;
  bool _locationServiceEnabled = false;
  LocationPermission? _locationPermission;
  String _preferredLanguage = 'fr';
  String _apiBaseUrl = AppConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final locationEnabled = await _locationService.isLocationServiceEnabled();
    final permission = await _locationService.checkPermission();

    if (!mounted) return;

    setState(() {
      _preferredLanguage = _storageService.getPreferredLanguage();
      _notificationsEnabled = _storageService.getNotificationsEnabled();
      _biometricAuthEnabled = _storageService.getBiometricAuthEnabled();
      _preciseLocationEnabled = _storageService.getPreciseLocationEnabled();
      _technicalInfoVisible = _storageService.getTechnicalInfoVisible();
      _apiBaseUrl = AppConstants.baseUrl;
      _locationServiceEnabled = locationEnabled;
      _locationPermission = permission;
      _isLoading = false;
    });

    final biometricAvailable = await BiometricAuthService.instance
        .isAvailable();
    if (!mounted) return;
    setState(() {
      _biometricAuthAvailable = biometricAvailable;
    });
  }

  Future<void> _updateLanguage(String value) async {
    await _storageService.savePreferredLanguage(value);
    if (!mounted) return;

    setState(() {
      _preferredLanguage = value;
    });

    _showInfoSnack(
      'Langue de l application mise a jour. Les composants systeme suivent maintenant cette preference.',
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    await _storageService.saveNotificationsEnabled(value);
    await _storageService.saveDailyReminderEnabled(value);
    if (value) {
      await NotificationService.instance.syncReminderPreference();
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = value;
    });

    _showInfoSnack(
      value
          ? 'Les rappels locaux quotidiens sont actives sur cet appareil.'
          : 'Les notifications locales et rappels quotidiens sont desactives.',
    );
  }

  Future<void> _toggleBiometricAuth(bool value) async {
    if (value && !_biometricAuthAvailable) {
      _showInfoSnack(
        'Aucune authentification biométrique compatible n est disponible sur cet appareil.',
      );
      return;
    }

    if (value) {
      final authenticated = await BiometricAuthService.instance
          .authenticateForUnlock();
      if (!authenticated) {
        if (!mounted) return;
        _showInfoSnack(
          'Activation annulee: verification biométrique non confirmee.',
        );
        return;
      }
    }

    await _storageService.saveBiometricAuthEnabled(value);
    if (!mounted) return;

    setState(() {
      _biometricAuthEnabled = value;
    });

    _showInfoSnack(
      value
          ? 'La protection biométrique est activee pour les retours dans l application.'
          : 'La protection biométrique est desactivee.',
    );
  }

  Future<void> _sendTestNotification() async {
    final granted = await NotificationService.instance.requestPermissions();
    if (!mounted) return;

    if (!granted) {
      _showInfoSnack(
        'Permission de notification refusee. Activez-la depuis les reglages du telephone.',
      );
      return;
    }

    await NotificationService.instance.showTestNotification();
    if (!mounted) return;
    _showInfoSnack('Notification de test envoyee.');
  }

  Future<void> _togglePreciseLocation(bool value) async {
    await _storageService.savePreciseLocationEnabled(value);
    if (!mounted) return;

    setState(() {
      _preciseLocationEnabled = value;
    });

    _showInfoSnack(
      value
          ? 'La localisation precise est privilegiee pour les parcours terrain.'
          : 'L application privilegiera des parcours sans localisation fine quand c est possible.',
    );
  }

  Future<void> _toggleTechnicalInfo(bool value) async {
    await _storageService.saveTechnicalInfoVisible(value);
    if (!mounted) return;

    setState(() {
      _technicalInfoVisible = value;
    });
  }

  Future<void> _editApiBaseUrl() async {
    final controller = TextEditingController(text: _apiBaseUrl);
    final nextValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Configurer l API'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL du backend',
            hintText: 'http://192.168.x.x:5001/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (nextValue == null) return;

    final normalized = AppConstants.normalizeApiBaseUrl(nextValue);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _showInfoSnack('URL API invalide.');
      return;
    }

    await _storageService.saveApiBaseUrl(normalized);
    ApiService.updateBaseUrl(normalized);
    if (!mounted) return;

    setState(() {
      _apiBaseUrl = normalized;
    });
    _showInfoSnack('Nouvelle URL API enregistree.');
  }

  Future<void> _resetApiBaseUrl() async {
    await _storageService.clearApiBaseUrl();
    ApiService.updateBaseUrl(AppConstants.defaultBaseUrl);
    if (!mounted) return;

    setState(() {
      _apiBaseUrl = AppConstants.baseUrl;
    });
    _showInfoSnack('URL API reinitialisee.');
  }

  Future<void> _copyApiBaseUrl() async {
    await Clipboard.setData(ClipboardData(text: _apiBaseUrl));
    if (!mounted) return;

    _showInfoSnack('URL API copiee.');
  }

  Future<void> _openLocationSettings() async {
    final opened = await _locationService.openLocationSettings();
    if (!mounted) return;

    if (opened) {
      _showInfoSnack('Ouverture des reglages de localisation.');
    } else {
      _showInfoSnack(
        'Impossible d ouvrir automatiquement les reglages de localisation.',
      );
    }

    await _loadSettings();
  }

  Future<void> _openAppSettings() async {
    final opened = await _locationService.openAppSettings();
    if (!mounted) return;

    if (opened) {
      _showInfoSnack('Ouverture des reglages de l application.');
    } else {
      _showInfoSnack(
        'Impossible d ouvrir automatiquement les reglages de l application.',
      );
    }

    await _loadSettings();
  }

  Future<void> _resetPreferences() async {
    await _storageService.resetAppPreferences();
    await NotificationService.instance.cancelDailyReminder();
    await _loadSettings();
    if (!mounted) return;

    _showInfoSnack('Les preferences locales ont ete reinitialisees.');
  }

  Future<void> _copySupportEmail() async {
    if (!AppConstants.hasOperationalSupportContact) {
      _showInfoSnack(
        'Aucun canal de support direct n est disponible dans cette build.',
      );
      return;
    }

    await Clipboard.setData(
      const ClipboardData(text: AppConstants.supportEmail),
    );
    if (!mounted) return;

    _showInfoSnack('Adresse de support copiee.');
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidentialite'),
        content: const Text(
          'Cette version stocke localement vos preferences et vos jetons de session. Les donnees de contribution, de profil et d activite sont transmises au backend MoroccoCheck lorsque vous utilisez les parcours relies a l API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reglages')),
      body: RefreshIndicator(
        onRefresh: _loadSettings,
        child: ListView(
          padding: SpacingTokens.allL,
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.xl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RadiusTokens.card),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Colors.white, size: 28),
                      SizedBox(width: SpacingTokens.m),
                      Text(
                        'Preferences de l application',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.m),
                  Text(
                    'Personnalisez votre experience locale autour de ${AppConstants.focusCity}, gelez vos preferences et gardez un oeil sur l etat de la localisation.',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.l),
            _SectionCard(
              title: 'Preferences',
              icon: Icons.settings_suggest_outlined,
              children: [
                _LanguageTile(
                  value: _preferredLanguage,
                  onChanged: _updateLanguage,
                ),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Rappels quotidiens'),
                  subtitle: const Text(
                    'Programmer un rappel local chaque jour pour contribuer sur le terrain',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: _notificationsEnabled,
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Envoyer une notification test'),
                  subtitle: const Text(
                    'Verifier immediatement que les rappels locaux fonctionnent sur cet appareil',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _notificationsEnabled ? _sendTestNotification : null,
                ),
                SwitchListTile(
                  value: _preciseLocationEnabled,
                  onChanged: _togglePreciseLocation,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Mode localisation fine'),
                  subtitle: const Text(
                    'Preferer une position detaillee pour la carte et les check-ins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.l),
            _SectionCard(
              title: 'Permissions',
              icon: Icons.verified_user_outlined,
              children: [
                SwitchListTile(
                  value: _biometricAuthEnabled,
                  onChanged: _toggleBiometricAuth,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Protection biométrique'),
                  subtitle: Text(
                    _biometricAuthAvailable
                        ? 'Demander une verification biométrique au retour dans l application'
                        : 'Aucune biométrie compatible detectee sur cet appareil',
                  ),
                ),
                _StatusRow(
                  label: 'Service de localisation',
                  state: _locationServiceEnabled ? 'Actif' : 'Desactive',
                  color: _locationServiceEnabled
                      ? AppColors.secondary
                      : Colors.orange,
                ),
                _StatusRow(
                  label: 'Permission actuelle',
                  state: _permissionLabel(_locationPermission),
                  color: _permissionColor(_locationPermission),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gps_fixed_outlined),
                  title: const Text('Ouvrir les reglages de localisation'),
                  subtitle: const Text(
                    'Activez le GPS ou ajustez les services de position du telephone',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openLocationSettings,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.app_settings_alt_outlined),
                  title: const Text('Ouvrir les reglages de l application'),
                  subtitle: const Text(
                    'Gerez les permissions de MoroccoCheck sur cet appareil',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: _openAppSettings,
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.l),
            _SectionCard(
              title: 'A propos',
              icon: Icons.info_outline,
              children: [
                _InfoRow(label: 'Version', value: AppConstants.appVersion),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Politique de confidentialite'),
                  subtitle: const Text(
                    'Lire un resume des donnees utilisees par cette version',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showPrivacyDialog,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Decouvrir l espace professionnel'),
                  subtitle: const Text(
                    'Voir le hub dedie aux proprietaires, gestionnaires et etablissements',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/professional'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _showAdvancedOptions
                        ? Icons.expand_less_rounded
                        : Icons.code_rounded,
                  ),
                  title: const Text('Avance'),
                  subtitle: const Text(
                    'Afficher la connexion API et les details techniques',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                ),
              ],
            ),
            if (_showAdvancedOptions) ...[
              const SizedBox(height: SpacingTokens.l),
              _SectionCard(
                title: 'Avance',
                icon: Icons.code_rounded,
                children: [
                  SwitchListTile(
                    value: _technicalInfoVisible,
                    onChanged: _toggleTechnicalInfo,
                    activeThumbColor: AppColors.primary,
                    title: const Text('Afficher les details techniques'),
                    subtitle: const Text(
                      'Montrer la configuration locale et les informations de debug',
                    ),
                  ),
                  _InfoRow(label: 'API active', value: _apiBaseUrl),
                  _InfoRow(
                    label: 'API par defaut',
                    value: AppConstants.defaultBaseUrl,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Modifier l URL API'),
                    subtitle: const Text(
                      'Changer l adresse du backend de cette installation locale',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editApiBaseUrl,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copier l URL active'),
                    subtitle: const Text(
                      'Recopier rapidement l adresse actuellement utilisee',
                    ),
                    trailing: const Icon(Icons.copy),
                    onTap: _copyApiBaseUrl,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore_outlined),
                    title: const Text('Revenir a l URL par defaut'),
                    subtitle: const Text(
                      'Supprimer l override local et reutiliser la configuration standard',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _resetApiBaseUrl,
                  ),
                  if (_technicalInfoVisible) ...[
                    const SizedBox(height: SpacingTokens.s),
                    _InfoRow(
                      label: 'Ville active',
                      value: AppConstants.focusCity,
                    ),
                    _InfoRow(label: 'Region', value: AppConstants.focusRegion),
                    _InfoRow(label: 'API', value: AppConstants.baseUrl),
                    _InfoRow(
                      label: 'Coordonnees',
                      value:
                          '${AppConstants.focusLatitude}, ${AppConstants.focusLongitude}',
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: SpacingTokens.l),
            Container(
              padding: const EdgeInsets.all(RadiusTokens.form),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(RadiusTokens.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support et maintenance',
                    style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: SpacingTokens.m),
                  if (AppConstants.hasOperationalSupportContact)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.support_agent_outlined),
                      title: const Text('Support'),
                      subtitle: Text(AppConstants.supportEmail),
                      trailing: const Icon(Icons.copy_outlined),
                      onTap: _copySupportEmail,
                    )
                  else
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.support_agent_outlined),
                      title: Text('Support direct indisponible'),
                      subtitle: Text(
                        'Aucun email de support operationnel n est publie dans cette build.',
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.cleaning_services_outlined,
                      color: AppColors.error,
                    ),
                    title: const Text('Reinitialiser les preferences'),
                    subtitle: const Text(
                      'Remettre les options locales a leur valeur par defaut',
                    ),
                    trailing: const Icon(Icons.restore_outlined),
                    onTap: _resetPreferences,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _permissionLabel(LocationPermission? permission) {
    switch (permission) {
      case LocationPermission.always:
        return 'Toujours autorisee';
      case LocationPermission.whileInUse:
        return 'Autorisee pendant l usage';
      case LocationPermission.deniedForever:
        return 'Refusee definitivement';
      case LocationPermission.denied:
        return 'Refusee';
      case LocationPermission.unableToDetermine:
        return 'Indeterminee';
      case null:
        return 'Indisponible';
    }
  }

  Color _permissionColor(LocationPermission? permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return AppColors.secondary;
      case LocationPermission.deniedForever:
        return AppColors.error;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
      case null:
        return Colors.orange;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RadiusTokens.form),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: SpacingTokens.m),
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.m),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String state;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.state,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.m,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadiusTokens.chip),
            ),
            child: Text(
              state,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguageTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language_outlined),
      title: const Text('Langue preferee'),
      subtitle: const Text(
        'Le choix est memorise localement pour preparer une future version multilingue',
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (nextValue) {
          if (nextValue != null) {
            onChanged(nextValue);
          }
        },
        items: const [
          DropdownMenuItem(value: 'fr', child: Text('Francais')),
          DropdownMenuItem(value: 'ar', child: Text('Arabe')),
          DropdownMenuItem(value: 'en', child: Text('Anglais')),
        ],
      ),
    );
  }
}
