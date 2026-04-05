import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../core/offline/pending_site_submission_service.dart';
import '../../../shared/models/site_category.dart';
import '../models/professional_site.dart';

class CreateSiteScreen extends StatefulWidget {
  final ProfessionalSite? initialSite;

  const CreateSiteScreen({super.key, this.initialSite});

  @override
  State<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends State<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late final TextEditingController _nameController;
  late final TextEditingController _nameArController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _descriptionArController;
  late final TextEditingController _subcategoryController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _amenitiesController;
  late final TextEditingController _coverPhotoController;

  late int _selectedCategoryId;
  late String? _selectedPriceRange;
  late bool _acceptsCardPayment;
  late bool _hasWifi;
  late bool _hasParking;
  late bool _isAccessible;
  List<SiteCategory> _categories = const <SiteCategory>[];
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  String? _categoriesError;

  bool get _isEditMode => widget.initialSite != null;

  static const List<String> _priceRanges = [
    'BUDGET',
    'MODERATE',
    'EXPENSIVE',
    'LUXURY',
  ];

  @override
  void initState() {
    super.initState();
    final site = widget.initialSite;
    _nameController = TextEditingController(text: site?.name ?? '');
    _nameArController = TextEditingController(text: site?.nameAr ?? '');
    _descriptionController = TextEditingController(
      text: site?.description ?? '',
    );
    _descriptionArController = TextEditingController(
      text: site?.descriptionAr ?? '',
    );
    _subcategoryController = TextEditingController(
      text: site?.subcategory ?? '',
    );
    _addressController = TextEditingController(text: site?.address ?? '');
    _cityController = TextEditingController(
      text: site?.city ?? AppConstants.focusCity,
    );
    _regionController = TextEditingController(
      text: site?.region ?? AppConstants.focusRegion,
    );
    _postalCodeController = TextEditingController(text: site?.postalCode ?? '');
    _latitudeController = TextEditingController(
      text: '${site?.latitude ?? AppConstants.focusLatitude}',
    );
    _longitudeController = TextEditingController(
      text: '${site?.longitude ?? AppConstants.focusLongitude}',
    );
    _phoneController = TextEditingController(text: site?.phoneNumber ?? '');
    _emailController = TextEditingController(text: site?.email ?? '');
    _websiteController = TextEditingController(text: site?.website ?? '');
    _amenitiesController = TextEditingController(
      text: site?.amenities.join(', ') ?? '',
    );
    _coverPhotoController = TextEditingController(text: site?.coverPhoto ?? '');
    _selectedCategoryId = site?.categoryId ?? 1;
    _selectedPriceRange = site?.priceRange ?? 'MODERATE';
    _acceptsCardPayment = site?.acceptsCardPayment ?? true;
    _hasWifi = site?.hasWifi ?? true;
    _hasParking = site?.hasParking ?? false;
    _isAccessible = site?.isAccessible ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _subcategoryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _amenitiesController.dispose();
    _coverPhotoController.dispose();
    super.dispose();
  }

  String? _validateRequiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner $label';
    }
    if (value.trim().length < 2) {
      return '$label est trop court';
    }
    return null;
  }

  String? _validateLatitude(String? value) {
    final latitude = double.tryParse((value ?? '').trim());
    if (latitude == null) {
      return 'Latitude invalide';
    }
    if (latitude < 27 || latitude > 36) {
      return 'Latitude hors zone Maroc';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    final longitude = double.tryParse((value ?? '').trim());
    if (longitude == null) {
      return 'Longitude invalide';
    }
    if (longitude < -13 || longitude > -1) {
      return 'Longitude hors zone Maroc';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^[+]?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Telephone invalide';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validateWebsite(String? value) {
    final website = (value ?? '').trim();
    if (website.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(website);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'URL invalide';
    }
    return null;
  }

  String _priceRangeLabel(String? value) {
    switch (value) {
      case 'BUDGET':
        return 'Budget';
      case 'MODERATE':
        return 'Modere';
      case 'EXPENSIVE':
        return 'Premium';
      case 'LUXURY':
        return 'Luxe';
      default:
        return value?.trim().isNotEmpty == true ? value! : 'Non renseignee';
    }
  }

  List<String> _parseAmenities() {
    return _amenitiesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Map<String, dynamic> _buildSubmissionPayload() {
    return <String, dynamic>{
      'name': _nameController.text.trim(),
      'category_id': _selectedCategoryId,
      'latitude': double.parse(_latitudeController.text.trim()),
      'longitude': double.parse(_longitudeController.text.trim()),
      'name_ar': _nameArController.text.trim(),
      'description': _descriptionController.text.trim(),
      'description_ar': _descriptionArController.text.trim(),
      'subcategory': _subcategoryController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'region': _regionController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'website': _websiteController.text.trim(),
      'price_range': _selectedPriceRange,
      'amenities': _parseAmenities(),
      'cover_photo': _coverPhotoController.text.trim(),
      'accepts_card_payment': _acceptsCardPayment,
      'has_wifi': _hasWifi,
      'has_parking': _hasParking,
      'is_accessible': _isAccessible,
    };
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _categoriesError = null;
    });

    try {
      final categories = await _apiService.fetchCategories(topLevelOnly: true);
      if (!mounted) return;

      final sortedCategories = List<SiteCategory>.from(categories)
        ..sort((left, right) {
          final orderComparison = left.displayOrder.compareTo(
            right.displayOrder,
          );
          if (orderComparison != 0) {
            return orderComparison;
          }
          return left.name.compareTo(right.name);
        });

      final selectedExists = sortedCategories.any(
        (category) => category.id == _selectedCategoryId,
      );

      setState(() {
        _categories = sortedCategories;
        if (!selectedExists && sortedCategories.isNotEmpty) {
          _selectedCategoryId = sortedCategories.first.id;
        }
        _isCategoriesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _categories = const <SiteCategory>[];
        _categoriesError = error.toString();
        _isCategoriesLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isCategoriesLoading || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les categories ne sont pas encore chargees. Reessayez dans un instant.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final submissionPayload = _buildSubmissionPayload();

    try {
      final result = _isEditMode
          ? await _apiService.updateSite(
              siteId: widget.initialSite!.id,
              name: submissionPayload['name'] as String,
              categoryId: submissionPayload['category_id'] as int,
              latitude: submissionPayload['latitude'] as double,
              longitude: submissionPayload['longitude'] as double,
              nameAr: submissionPayload['name_ar'] as String,
              description: submissionPayload['description'] as String,
              descriptionAr: submissionPayload['description_ar'] as String,
              subcategory: submissionPayload['subcategory'] as String,
              address: submissionPayload['address'] as String,
              city: submissionPayload['city'] as String,
              region: submissionPayload['region'] as String,
              postalCode: submissionPayload['postal_code'] as String,
              phoneNumber: submissionPayload['phone_number'] as String,
              email: submissionPayload['email'] as String,
              website: submissionPayload['website'] as String,
              priceRange: submissionPayload['price_range'] as String?,
              amenities: submissionPayload['amenities'] as List<String>,
              coverPhoto: submissionPayload['cover_photo'] as String,
              acceptsCardPayment: _acceptsCardPayment,
              hasWifi: _hasWifi,
              hasParking: _hasParking,
              isAccessible: _isAccessible,
            )
          : await _apiService.createSite(
              name: submissionPayload['name'] as String,
              categoryId: submissionPayload['category_id'] as int,
              latitude: submissionPayload['latitude'] as double,
              longitude: submissionPayload['longitude'] as double,
              nameAr: submissionPayload['name_ar'] as String,
              description: submissionPayload['description'] as String,
              descriptionAr: submissionPayload['description_ar'] as String,
              subcategory: submissionPayload['subcategory'] as String,
              address: submissionPayload['address'] as String,
              city: submissionPayload['city'] as String,
              region: submissionPayload['region'] as String,
              postalCode: submissionPayload['postal_code'] as String,
              phoneNumber: submissionPayload['phone_number'] as String,
              email: submissionPayload['email'] as String,
              website: submissionPayload['website'] as String,
              priceRange: submissionPayload['price_range'] as String?,
              amenities: submissionPayload['amenities'] as List<String>,
              coverPhoto: submissionPayload['cover_photo'] as String,
              acceptsCardPayment: _acceptsCardPayment,
              hasWifi: _hasWifi,
              hasParking: _hasParking,
              isAccessible: _isAccessible,
            );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Lieu mis a jour avec succes.'
                : (result.status == 'PENDING_REVIEW'
                      ? 'Lieu soumis avec succes. Il reste en attente de validation.'
                      : 'Lieu publie avec succes.'),
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;

      String message = _isEditMode
          ? 'Impossible de mettre a jour ce lieu.'
          : 'Impossible de creer ce lieu.';
      if (e is ApiException) {
        if (e.statusCode == 400) {
          message = 'Certaines informations du formulaire sont invalides.';
        } else if (e.isForbidden) {
          message = 'Votre compte ne peut pas modifier ce lieu.';
        } else if (e.isUnauthorized) {
          message = 'Votre session a expire. Reconnectez-vous.';
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message = 'Impossible de contacter le serveur.';
        } else if (e.message.isNotEmpty) {
          message = e.message;
        }
      }

      final isRetryableNetworkError =
          e is ApiException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout);

      if (isRetryableNetworkError) {
        await PendingSiteSubmissionService().enqueue(
          PendingSiteSubmissionPayload(
            action: _isEditMode ? 'update' : 'create',
            siteId: widget.initialSite?.id,
            data: submissionPayload,
            queuedAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Mise a jour enregistree hors ligne. Elle sera synchronisee automatiquement.'
                  : 'Soumission enregistree hors ligne. Elle sera synchronisee automatiquement.',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
        context.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier le lieu' : 'Ajouter un lieu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _isEditMode
                      ? 'Vous pouvez ajuster les informations de votre lieu. Les changements sensibles peuvent necessiter une nouvelle validation.'
                      : 'Le lieu sera soumis au backend avec un statut de validation. Pour un compte PROFESSIONAL, il passera generalement en PENDING_REVIEW.',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 20),
              _CreateFlowSummary(isEditMode: _isEditMode),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Identite',
                subtitle: 'Nom, categorie et description visibles sur la fiche.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom du lieu'),
                      validator: (value) =>
                          _validateRequiredText(value, 'le nom'),
                    ),
                    const SizedBox(height: 16),
                    if (_categoriesError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Impossible de charger les categories metier depuis le backend.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadCategories,
                              child: const Text('Reessayer'),
                            ),
                          ],
                        ),
                      ),
                    const _InlineFieldLabel('Categorie'),
                    DropdownButtonFormField<int>(
                      initialValue:
                          _categories.any(
                            (category) => category.id == _selectedCategoryId,
                          )
                          ? _selectedCategoryId
                          : null,
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 320,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Choisir une categorie',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(
                                category.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) =>
                          value == null
                              ? 'Veuillez choisir une categorie'
                              : null,
                      disabledHint: _isCategoriesLoading
                          ? const Text('Chargement des categories...')
                          : const Text('Aucune categorie disponible'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Decrivez votre lieu en quelques lignes',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subcategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Sous-categorie',
                        hintText: 'Ex. Surf camp, rooftop, kasbah...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Localisation',
                subtitle:
                    'Adresse et coordonnees utilisees pour la carte et le check-in.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Adresse'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'Ville'),
                            validator: (value) =>
                                _validateRequiredText(value, 'la ville'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _regionController,
                            decoration: const InputDecoration(
                              labelText: 'Region',
                            ),
                            validator: (value) =>
                                _validateRequiredText(value, 'la region'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                            ),
                            validator: _validateLatitude,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                            ),
                            validator: _validateLongitude,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Contact',
                subtitle: 'Coordonnees publiques pour aider le visiteur a vous joindre.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telephone'),
                      validator: _validatePhoneNumber,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email public',
                      ),
                      validator: _validateEmail,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Services',
                subtitle: 'Elements pratiques qui renforcent la lisibilite de votre fiche.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amenitiesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Commodites',
                        hintText: 'wifi, parking, terrasse, plage...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _InlineFieldLabel('Gamme de prix'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriceRange,
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 260,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Choisir une gamme',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                      items: _priceRanges
                          .map(
                            (range) => DropdownMenuItem<String>(
                              value: range,
                              child: Text(
                                _priceRangeLabel(range),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriceRange = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ExpandableFormSection(
                title: 'Informations complementaires',
                subtitle:
                    'Traductions, site web, photo de couverture et drapeaux de service',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameArController,
                      decoration: const InputDecoration(
                        labelText: 'Nom en arabe',
                        hintText: 'Optionnel',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionArController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description en arabe',
                        hintText: 'Optionnel',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _postalCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Code postal',
                        hintText: 'Optionnel',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(labelText: 'Site web'),
                      validator: _validateWebsite,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverPhotoController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL photo de couverture',
                        hintText: 'https://...',
                      ),
                      validator: _validateWebsite,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptsCardPayment,
                      onChanged: (value) {
                        setState(() {
                          _acceptsCardPayment = value;
                        });
                      },
                      title: const Text('Paiement par carte'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hasWifi,
                      onChanged: (value) {
                        setState(() {
                          _hasWifi = value;
                        });
                      },
                      title: const Text('Wi-Fi disponible'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hasParking,
                      onChanged: (value) {
                        setState(() {
                          _hasParking = value;
                        });
                      },
                      title: const Text('Parking disponible'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isAccessible,
                      onChanged: (value) {
                        setState(() {
                          _isAccessible = value;
                        });
                      },
                      title: const Text('Accessible'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(_isEditMode ? Icons.save : Icons.add_business),
                  label: Text(
                    _isLoading
                        ? (_isEditMode ? 'Mise a jour...' : 'Envoi...')
                        : (_isEditMode
                              ? 'Enregistrer les modifications'
                              : 'Soumettre le lieu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineFieldLabel extends StatelessWidget {
  final String text;

  const _InlineFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _FormSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _CreateFlowSummary extends StatelessWidget {
  final bool isEditMode;

  const _CreateFlowSummary({required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    final steps = <_CreateSummaryItem>[
      const _CreateSummaryItem(
        icon: Icons.badge_outlined,
        title: '1. Identite',
        subtitle: 'Nom, categorie, description',
      ),
      const _CreateSummaryItem(
        icon: Icons.place_outlined,
        title: '2. Localisation',
        subtitle: 'Carte, ville et coordonnees',
      ),
      const _CreateSummaryItem(
        icon: Icons.call_outlined,
        title: '3. Contact',
        subtitle: 'Telephone et email public',
      ),
      const _CreateSummaryItem(
        icon: Icons.fact_check_outlined,
        title: '4. Services',
        subtitle: 'Infos utiles pour le visiteur',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? 'Plan de mise a jour' : 'Plan de soumission',
              style: AppTextStyles.heading2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Renseignez d abord l essentiel. Les champs optionnels restent regroupes plus bas pour garder un formulaire simple.',
              style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: steps
                  .map((step) => _CreateSummaryChip(item: step))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_city, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La ville et la region sont deja pre-remplies pour ${AppConstants.focusCity}. Ajustez-les seulement si votre lieu se situe ailleurs.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSummaryItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CreateSummaryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _CreateSummaryChip extends StatelessWidget {
  final _CreateSummaryItem item;

  const _CreateSummaryChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableFormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ExpandableFormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
          ),
          children: [child],
        ),
      ),
    );
  }
}
