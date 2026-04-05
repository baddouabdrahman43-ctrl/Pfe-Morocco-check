import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../core/offline/pending_review_service.dart';
import '../../auth/presentation/auth_provider.dart';
import 'sites/site.dart';
import 'sites_provider.dart';

class AddReviewScreen extends StatefulWidget {
  final String? siteId;

  const AddReviewScreen({super.key, this.siteId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  Site? _site;
  int _rating = 0;
  bool _isLoading = false;
  List<XFile> _selectedPhotos = <XFile>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSite();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  String? _validateComment(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Le commentaire est obligatoire (min 20 caracteres)';
    }
    if (text.length < 20) {
      return 'Le commentaire doit contenir au moins 20 caracteres';
    }
    if (text.length > 4000) {
      return 'Le commentaire ne peut pas depasser 4000 caracteres';
    }
    return null;
  }

  Future<void> _pickReviewPhotos() async {
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
          content: Text('Impossible de selectionner les photos.'),
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

  Future<void> _handleSubmit() async {
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final router = GoRouter.of(context);

    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Veuillez selectionner une note'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_site == null) {
        throw ApiException(message: 'Site invalide');
      }

      final result = await _apiService.submitReview(
        siteId: _site!.id,
        rating: _rating,
        content: _commentController.text.trim(),
        photos: _selectedPhotos,
      );

      if (!mounted) return;
      context.read<SitesProvider>().recordReviewSubmission(
        _site!,
        rating: _rating,
      );
      if (!mounted) return;
      await authProvider.refreshUser();
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.isPendingModeration
                ? 'Avis envoye. Il sera visible apres moderation.'
                : 'Avis publie avec succes.',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
      router.pop();
    } catch (e) {
      if (!mounted) return;
      String message = 'Erreur lors de la publication de l avis.';
      if (e is ApiException) {
        if (e.isUnauthorized) {
          message = 'Votre session a expire. Reconnectez-vous pour continuer.';
        } else if (e.statusCode == 409 ||
            e.message.toLowerCase().contains('deja')) {
          message = 'Vous avez deja publie un avis pour ce site.';
        } else if (e.statusCode == 400) {
          message = 'Votre avis est invalide. Verifiez la note et le contenu.';
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.message.toLowerCase().contains('connexion')) {
          message = 'Pas de connexion internet. Reessayez.';
        } else if (e.message.isNotEmpty) {
          message = e.message;
        }
      }
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
      if (e is ApiException && e.isUnauthorized) {
        authProvider.clearError();
        router.go('/login');
      } else if (e is ApiException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) &&
          _site != null) {
        await PendingReviewService().enqueue(
          PendingReviewPayload(
            siteId: _site!.id,
            rating: _rating,
            content: _commentController.text.trim(),
            title: null,
            photoPaths: _selectedPhotos.map((photo) => photo.path).toList(),
            queuedAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Avis enregistre hors ligne. Il sera synchronise automatiquement des le retour de connexion.',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
        router.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_site == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajouter un avis')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un avis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.place,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _site!.name,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _site!.category,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votre note',
                        style: AppTextStyles.heading2.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cette etape est requise avant de publier votre avis.',
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(child: _buildRatingBar()),
                      if (_rating == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Veuillez selectionner une note',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commentaire et photos',
                        style: AppTextStyles.heading2.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez du contexte et des visuels pour enrichir votre retour.',
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 5,
                        maxLength: 4000,
                        validator: _validateComment,
                        decoration: const InputDecoration(
                          hintText: 'Decrivez votre experience...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Photos de l avis',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isLoading || _selectedPhotos.length >= 5
                            ? null
                            : _pickReviewPhotos,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(
                          _selectedPhotos.isEmpty
                              ? 'Ajouter jusqu a 5 photos'
                              : 'Ajouter d autres photos',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _selectedPhotos.isEmpty
                              ? 'Ajoutez des photos pour enrichir votre retour d experience.'
                              : '${_selectedPhotos.length} photo${_selectedPhotos.length > 1 ? 's' : ''} selectionnee${_selectedPhotos.length > 1 ? 's' : ''}.',
                          style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      if (_selectedPhotos.isNotEmpty)
                        const SizedBox(height: 12),
                      if (_selectedPhotos.isNotEmpty)
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedPhotos.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final photo = _selectedPhotos[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FutureBuilder<Uint8List>(
                                      future: photo.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            width: 96,
                                            height: 96,
                                            fit: BoxFit.cover,
                                          );
                                        }

                                        return Container(
                                          width: 96,
                                          height: 96,
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          alignment: Alignment.center,
                                          child: snapshot.hasError
                                              ? Icon(
                                                  Icons.broken_image_outlined,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.7),
                                                )
                                              : const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: _isLoading
                                          ? null
                                          : () => _removePhoto(photo),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading || _rating == 0 ? null : _handleSubmit,
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
                      : const Text('Publier l avis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    _rating = starIndex;
                  });
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= _rating ? Icons.star : Icons.star_border,
              size: 42,
              color: starIndex <= _rating
                  ? colorScheme.secondary
                  : colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        );
      }),
    );
  }
}
