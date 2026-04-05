import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../shared/models/user.dart';

class EditProfileScreen extends StatefulWidget {
  final User initialUser;

  const EditProfileScreen({super.key, required this.initialUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _profilePictureController;
  late final TextEditingController _bioController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initialUser.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.initialUser.lastName,
    );
    _emailController = TextEditingController(text: widget.initialUser.email);
    _phoneController = TextEditingController(
      text: widget.initialUser.phoneNumber ?? '',
    );
    _nationalityController = TextEditingController(
      text: widget.initialUser.nationality ?? '',
    );
    _profilePictureController = TextEditingController(
      text: widget.initialUser.profilePicture ?? '',
    );
    _bioController = TextEditingController(text: widget.initialUser.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    _profilePictureController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner $label';
    }
    if (value.trim().length < 2) {
      return '$label est trop court';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner votre email';
    }
    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Adresse email invalide';
    }
    return null;
  }

  String? _validateNationality(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length != 2) {
      return 'Utilisez un code pays a 2 lettres';
    }
    return null;
  }

  String? _validatePhone(String? value) {
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

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      return 'URL invalide';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiService.updateMyProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        nationality: _nationalityController.text.trim().toUpperCase(),
        bio: _bioController.text.trim(),
        profilePicture: _profilePictureController.text.trim(),
      );

      if (!mounted) return;

      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis a jour avec succes.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;

      var message = 'Impossible de mettre a jour le profil.';
      if (error is ApiException) {
        if (error.code == 'EMAIL_ALREADY_USED' || error.statusCode == 409) {
          message = 'Cette adresse email est deja utilisee.';
        } else if (error.statusCode == 400) {
          message = 'Certaines informations sont invalides.';
        } else if (error.isUnauthorized) {
          message = 'Votre session a expire. Reconnectez-vous.';
        } else if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          message = 'Impossible de contacter le serveur.';
        } else if (error.message.isNotEmpty) {
          message = error.message;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier mon profil')),
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
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Mettez a jour vos informations personnelles. La photo de profil fonctionne actuellement via une URL publique.',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
                ),
              ),
              const SizedBox(height: 20),
              Text('Identite', style: AppTextStyles.heading2),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'Prenom',
                              ),
                              validator: (value) =>
                                  _requiredText(value, 'votre prenom'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nom',
                              ),
                              validator: (value) =>
                                  _requiredText(value, 'votre nom'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: _validateEmail,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    title: Text(
                      'Informations complementaires',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Photo URL, bio, telephone et nationalite',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    children: [
                      TextFormField(
                        controller: _profilePictureController,
                        decoration: const InputDecoration(
                          labelText: 'Photo de profil',
                          hintText: 'https://...',
                        ),
                        validator: _validateUrl,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText:
                              'Parlez un peu de vous, de vos voyages ou de votre activite.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telephone',
                          hintText: '+212600000000',
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nationalityController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Nationalite',
                          hintText: 'MA',
                        ),
                        validator: _validateNationality,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
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
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
