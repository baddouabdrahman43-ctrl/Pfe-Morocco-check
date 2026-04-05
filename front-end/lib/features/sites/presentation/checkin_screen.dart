import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/location/location_service.dart';
import '../../../core/location/location_utils.dart';
import '../../../core/network/api_service.dart';
import '../../../core/offline/pending_checkin_service.dart';
import '../../auth/presentation/auth_provider.dart';
import 'checkin_policy.dart';
import 'sites/site.dart';
import 'sites_provider.dart';
import 'widgets/checkin_sections.dart';

class CheckinScreen extends StatefulWidget {
  final String? siteId;
  final bool skipLocationCheckForTest;
  final double? mockDistanceForTest;

  const CheckinScreen({
    super.key,
    this.siteId,
    this.skipLocationCheckForTest = false,
    this.mockDistanceForTest,
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  static const Set<String> _allowedRoles = <String>{
    'CONTRIBUTOR',
    'PROFESSIONAL',
    'ADMIN',
  };

  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final DateTime _screenOpenedAt = DateTime.now();

  Site? _site;
  Position? _userPosition;
  double? _distance;
  double? _positionAccuracy;
  bool _isLoading = false;
  bool _isCheckingLocation = true;
  bool _showSuccessAnimation = false;
  String? _error;
  String? _selectedStatus = 'OPEN';
  int _pointsEarned = 10;
  List<XFile> _selectedPhotos = <XFile>[];
  int _pendingQueueCount = 0;
  DateTime? _insideAllowedZoneSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPendingQueueCount();
      await _loadSite();
      if (!mounted) return;

      if (widget.skipLocationCheckForTest) {
        setState(() {
          _isCheckingLocation = false;
          _distance = widget.mockDistanceForTest ?? 245.0;
          if (_distance! > _policy.allowedDistanceMeters) {
            _error =
                'Vous etes trop loin du site. Distance: ${formatDistance(_distance!)}. Vous devez etre a moins de ${_policy.allowedDistanceMeters} metres pour effectuer un check-in.';
          }
        });
      } else {
        await _checkUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  CheckinPolicy get _policy {
    final site = _site;
    if (site == null) {
      return const CheckinPolicy(
        allowedDistanceMeters: 100,
        maxAccuracyMeters: 50,
        minimumVisitDurationSeconds: 15,
        strategyLabel: 'Verification standard',
      );
    }

    return resolveCheckinPolicyForSite(site);
  }

  int get _visitDurationSeconds {
    final start = _insideAllowedZoneSince ?? _screenOpenedAt;
    return DateTime.now().difference(start).inSeconds;
  }

  Future<void> _loadPendingQueueCount() async {
    final count = await PendingCheckinService().getPendingCount();
    if (!mounted) return;
    setState(() {
      _pendingQueueCount = count;
    });
  }

  Future<void> _loadSite() async {
    if (widget.siteId == null) {
      return;
    }

    final sitesProvider = context.read<SitesProvider>();
    final cachedSite = sitesProvider.getSiteById(widget.siteId!);
    if (cachedSite != null) {
      setState(() {
        _site = cachedSite;
      });
      return;
    }

    try {
      if (sitesProvider.sites.isEmpty) {
        await sitesProvider.getSites();
      }

      final providerSite = sitesProvider.getSiteById(widget.siteId!);
      if (providerSite != null) {
        if (!mounted) return;
        setState(() {
          _site = providerSite;
        });
        return;
      }

      final apiSite = await _apiService.fetchSiteDetail(widget.siteId!);
      if (!mounted) return;
      setState(() {
        _site = apiSite;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _site = null;
      });
    }
  }

  Future<void> _checkUserLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _error = null;
    });

    try {
      await _locationService.requestPermission();
      final position = await _locationService.getCurrentPosition(
        accuracy: LocationAccuracy.high,
      );

      if (mounted && _site != null) {
        final distance = calculateDistance(
          position.latitude,
          position.longitude,
          _site!.latitude,
          _site!.longitude,
        );

        setState(() {
          _userPosition = position;
          _distance = distance;
          _positionAccuracy = position.accuracy;
          _isCheckingLocation = false;

          if (distance <= _policy.allowedDistanceMeters) {
            _insideAllowedZoneSince ??= DateTime.now();
          }

          if (distance > _policy.allowedDistanceMeters) {
            _insideAllowedZoneSince = null;
            _error =
                'Vous etes trop loin du site. Distance: ${formatDistance(distance)}. Vous devez etre a moins de ${_policy.allowedDistanceMeters} metres pour effectuer un check-in.';
          } else if (position.accuracy > _policy.maxAccuracyMeters) {
            _error =
                'La precision GPS actuelle (${position.accuracy.toStringAsFixed(0)} m) est insuffisante. Essayez de vous stabiliser avant de soumettre.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _error =
              'Impossible de verifier votre position. Activez la localisation puis reessayez.';
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider?>();
    final router = GoRouter.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_distance == null || _distance! > _policy.allowedDistanceMeters) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez vous rapprocher du site pour effectuer un check-in dans le rayon de ${_policy.allowedDistanceMeters} m.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_site == null || _userPosition == null) {
        throw ApiException(message: 'Site ou position invalide');
      }

      final deviceInfo = <String, dynamic>{
        'visit_duration_seconds': _visitDurationSeconds,
        'is_mocked_location': _userPosition!.isMocked,
        'app_platform': defaultTargetPlatform.name,
      };

      final result = await _apiService.submitCheckin(
        siteId: _site!.id,
        latitude: _userPosition!.latitude,
        longitude: _userPosition!.longitude,
        accuracy: _userPosition!.accuracy,
        status: _selectedStatus,
        comment: _commentController.text.trim(),
        hasPhoto: _selectedPhotos.isNotEmpty,
        photos: _selectedPhotos,
        deviceInfo: deviceInfo,
      );

      if (!mounted) return;

      context.read<SitesProvider>().markSiteCheckedIn(
        _site!.id,
        siteName: _site!.name,
      );
      await context.read<AuthProvider>().refreshUser();

      setState(() {
        _isLoading = false;
        _showSuccessAnimation = true;
        _pointsEarned = result.pointsEarned > 0 ? result.pointsEarned : 10;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.isPendingReview
                ? 'Check-in enregistre. Il sera verifie a cause d une duree de presence encore courte.'
                : 'Check-in valide avec succes.',
          ),
          backgroundColor: result.isPendingReview
              ? Colors.orange
              : AppColors.secondary,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      var message = 'Erreur lors du check-in.';
      if (e is ApiException) {
        if (e.isUnauthorized) {
          message = 'Votre session a expire. Reconnectez-vous pour continuer.';
        } else if (e.code == 'ROLE_NOT_ALLOWED' || e.isForbidden) {
          message =
              'Le check-in est reserve aux comptes contributeur, professionnel, moderateur ou admin.';
        } else if (e.code == 'CHECKIN_TOO_FAR') {
          final maxDistance = e.details is Map
              ? int.tryParse('${(e.details as Map)['maxDistance'] ?? ''}')
              : null;
          message = maxDistance != null
              ? 'Distance trop grande. Approchez-vous a moins de $maxDistance m.'
              : 'Distance trop grande. Approchez-vous davantage du site.';
        } else if (e.code == 'CHECKIN_LOW_ACCURACY') {
          message =
              'Precision GPS insuffisante. Attendez un signal plus stable avant de reessayer.';
        } else if (e.code == 'CHECKIN_MOCK_LOCATION') {
          message =
              'Une position simulee a ete detectee. Desactivez-la pour valider le check-in.';
        } else if (e.statusCode == 409 ||
            e.message.toLowerCase().contains('deja')) {
          message =
              'Vous avez deja enregistre un check-in pour ce site aujourd hui.';
        } else if (e.statusCode == 400) {
          message = 'Les donnees du check-in sont invalides.';
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message = 'Pas de connexion internet. Reessayez.';
        } else if (e.message.isNotEmpty) {
          message = e.message;
        }
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
        if (e is ApiException && e.isUnauthorized) {
          authProvider?.clearError();
          router.go('/login');
        } else if (e is ApiException &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout) &&
            _site != null &&
            _userPosition != null) {
          await PendingCheckinService().enqueue(
            PendingCheckinPayload(
              siteId: _site!.id,
              latitude: _userPosition!.latitude,
              longitude: _userPosition!.longitude,
              accuracy: _userPosition!.accuracy,
              status: _selectedStatus,
              comment: _commentController.text.trim(),
              photoPaths: _selectedPhotos.map((photo) => photo.path).toList(),
              deviceInfo: <String, dynamic>{
                'visit_duration_seconds': _visitDurationSeconds,
                'is_mocked_location': _userPosition!.isMocked,
                'app_platform': defaultTargetPlatform.name,
                'collected_offline': true,
              },
              queuedAt: DateTime.now(),
            ),
          );
          await _loadPendingQueueCount();
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Check-in enregistre hors ligne. Il sera synchronise automatiquement des le retour de connexion.',
              ),
              backgroundColor: AppColors.secondary,
            ),
          );
          context.pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickCheckinPhotos() async {
    try {
      final pickedPhotos = await _imagePicker.pickMultiImage(
        imageQuality: 82,
        limit: 5,
      );
      if (!mounted || pickedPhotos.isEmpty) return;

      setState(() {
        final merged = <XFile>[
          ..._selectedPhotos,
          ...pickedPhotos.where(
            (photo) => !_selectedPhotos.any((item) => item.path == photo.path),
          ),
        ];
        _selectedPhotos = merged.take(5).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de selectionner les photos du check-in.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removePhoto(XFile photo) {
    setState(() {
      _selectedPhotos = _selectedPhotos
          .where((item) => item.path != photo.path)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider?>()?.user;
    final canSubmitCheckin =
        currentUser == null || _allowedRoles.contains(currentUser.role);
    final colorScheme = Theme.of(context).colorScheme;

    if (_site == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-in')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Check-in')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckinSiteSummaryCard(
                  name: _site!.name,
                  category: _site!.category,
                ),
                const SizedBox(height: 24),
                CheckinPolicyCard(
                  strategyLabel: _policy.strategyLabel,
                  allowedDistanceMeters: _policy.allowedDistanceMeters,
                  maxAccuracyMeters: _policy.maxAccuracyMeters,
                  minimumVisitDurationSeconds:
                      _policy.minimumVisitDurationSeconds,
                  pendingQueueCount: _pendingQueueCount,
                ),
                const SizedBox(height: 16),
                if (_isCheckingLocation) const CheckinLocationLoadingCard(),
                if (_distance != null && !_isCheckingLocation)
                  CheckinDistanceCard(
                    distanceMeters: _distance!,
                    allowedDistanceMeters: _policy.allowedDistanceMeters,
                    positionAccuracy: _positionAccuracy,
                    visitDurationSeconds: _insideAllowedZoneSince != null
                        ? _visitDurationSeconds
                        : null,
                    formatDistance: formatDistance,
                  ),
                if (_error != null && !_isCheckingLocation)
                  CheckinErrorCard(error: _error!, onRetry: _checkUserLocation),
                if (!canSubmitCheckin)
                  const CheckinRestrictionCard(
                    message:
                        'Le backend reserve le check-in aux comptes contributeur, professionnel, moderateur ou admin.',
                  ),
                if (_distance != null &&
                    _distance! <= _policy.allowedDistanceMeters &&
                    _error == null &&
                    canSubmitCheckin)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Statut du site',
                          style: AppTextStyles.heading2.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<String>(
                          groupValue: _selectedStatus,
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                          child: Column(
                            children: ['OPEN', 'CLOSED', 'UNDER_CONSTRUCTION']
                                .map((status) {
                                  return RadioListTile<String>(
                                    title: Text(_getStatusLabel(status)),
                                    value: status,
                                    selected: _selectedStatus == status,
                                    activeColor: AppColors.primary,
                                  );
                                })
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Commentaire (optionnel)',
                          style: AppTextStyles.heading2.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Ajoutez un commentaire sur l etat du site...',
                          ),
                        ),
                        const SizedBox(height: 20),
                        CheckinPhotoSection(
                          isLoading: _isLoading,
                          selectedPhotos: _selectedPhotos,
                          onAddPhotos: _pickCheckinPhotos,
                          onRemovePhoto: _removePhoto,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Soumettre le check-in',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_showSuccessAnimation)
          CheckinSuccessAnimationOverlay(
            pointsEarned: _pointsEarned,
            onAnimationComplete: () {
              setState(() {
                _showSuccessAnimation = false;
              });
            },
          ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return 'Ouvert';
      case 'CLOSED':
        return 'Ferme';
      case 'UNDER_CONSTRUCTION':
        return 'En construction';
      default:
        return status;
    }
  }
}
