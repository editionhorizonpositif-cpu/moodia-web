// lib/pages/add_activity_page.dart - VERSION FINALE COMPLÈTE ET CORRIGÉE

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/activity_category.dart';
import '../models/activity_dtos.dart';
import '../models/activity_enums.dart';
import '../services/activity_api_service.dart';
import '../services/media_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ============ IMPLÉMENTATION DU DTO DE CONFIGURATION ============

class ActivityConfigurationImpl implements ActivityConfigurationDTO {
  @override
  final bool? requiresPreparation;
  @override
  final int? preparationTimeSeconds;
  @override
  final bool? isGuided;
  @override
  final bool? hasBackgroundMusic;
  @override
  final bool? isOfflineAvailable;
  @override
  final int? maxParticipants;
  @override
  final int? energyLevel;
  @override
  final int? focusLevel;
  @override
  final String? moodImpact;
  @override
  final String? recommendedTimeOfDay;
  @override
  final String? idealEnvironment;
  @override
  final String? equipmentRequired;
  @override
  final bool? hasGuidedAudio;
  @override
  final bool? hasVideoGuide;
  @override
  final bool? hasAnimation;
  @override
  final bool? isInteractive;
  @override
  final bool? hasReminders;
  @override
  final bool? hasProgressTracking;
  @override
  final int? minimumAge;
  @override
  final bool? isAccessible;

  ActivityConfigurationImpl({
    required this.requiresPreparation,
    required this.preparationTimeSeconds,
    required this.isGuided,
    required this.hasBackgroundMusic,
    required this.isOfflineAvailable,
    required this.maxParticipants,
    required this.energyLevel,
    required this.focusLevel,
    required this.moodImpact,
    required this.recommendedTimeOfDay,
    required this.idealEnvironment,
    required this.equipmentRequired,
    required this.hasGuidedAudio,
    required this.hasVideoGuide,
    required this.hasAnimation,
    required this.isInteractive,
    required this.hasReminders,
    required this.hasProgressTracking,
    required this.minimumAge,
    required this.isAccessible,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'requiresPreparation': requiresPreparation,
      'preparationTimeSeconds': preparationTimeSeconds,
      'isGuided': isGuided,
      'hasBackgroundMusic': hasBackgroundMusic,
      'isOfflineAvailable': isOfflineAvailable,
      'maxParticipants': maxParticipants,
      'energyLevel': energyLevel,
      'focusLevel': focusLevel,
      'moodImpact': moodImpact,
      'recommendedTimeOfDay': recommendedTimeOfDay,
      'idealEnvironment': idealEnvironment,
      'equipmentRequired': equipmentRequired,
      'hasGuidedAudio': hasGuidedAudio,
      'hasVideoGuide': hasVideoGuide,
      'hasAnimation': hasAnimation,
      'isInteractive': isInteractive,
      'hasReminders': hasReminders,
      'hasProgressTracking': hasProgressTracking,
      'minimumAge': minimumAge,
      'isAccessible': isAccessible,
    };
  }

  @override
  ActivityConfigurationDTO copyWith({
    bool? requiresPreparation,
    int? preparationTimeSeconds,
    bool? isGuided,
    bool? hasBackgroundMusic,
    bool? isOfflineAvailable,
    int? maxParticipants,
    int? energyLevel,
    int? focusLevel,
    String? moodImpact,
    String? recommendedTimeOfDay,
    String? idealEnvironment,
    String? equipmentRequired,
    bool? hasGuidedAudio,
    bool? hasVideoGuide,
    bool? hasAnimation,
    bool? isInteractive,
    bool? hasReminders,
    bool? hasProgressTracking,
    int? minimumAge,
    bool? isAccessible,
  }) {
    return ActivityConfigurationImpl(
      requiresPreparation: requiresPreparation ?? this.requiresPreparation!,
      preparationTimeSeconds:
          preparationTimeSeconds ?? this.preparationTimeSeconds!,
      isGuided: isGuided ?? this.isGuided!,
      hasBackgroundMusic: hasBackgroundMusic ?? this.hasBackgroundMusic!,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable!,
      maxParticipants: maxParticipants ?? this.maxParticipants!,
      energyLevel: energyLevel ?? this.energyLevel!,
      focusLevel: focusLevel ?? this.focusLevel!,
      moodImpact: moodImpact ?? this.moodImpact!,
      recommendedTimeOfDay: recommendedTimeOfDay ?? this.recommendedTimeOfDay!,
      idealEnvironment: idealEnvironment ?? this.idealEnvironment!,
      equipmentRequired: equipmentRequired ?? this.equipmentRequired!,
      hasGuidedAudio: hasGuidedAudio ?? this.hasGuidedAudio!,
      hasVideoGuide: hasVideoGuide ?? this.hasVideoGuide!,
      hasAnimation: hasAnimation ?? this.hasAnimation!,
      isInteractive: isInteractive ?? this.isInteractive!,
      hasReminders: hasReminders ?? this.hasReminders!,
      hasProgressTracking: hasProgressTracking ?? this.hasProgressTracking!,
      minimumAge: minimumAge ?? this.minimumAge!,
      isAccessible: isAccessible ?? this.isAccessible!,
    );
  }
}

class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key});

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();

  // ============ CONTROLLERS ============
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _shortDescriptionController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _prerequisitesController =
      TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _colorHexController = TextEditingController(
    text: '#7DBBC3',
  );
  final TextEditingController _iconNameController = TextEditingController();

  // ============ SERVICES ============
  ActivityApiService? _activityService;
  MediaService? _mediaService;
  AuthService? _authService;

  // ============ ÉTATS ============
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAdmin = false;
  bool _isContentCreator = false;
  String? _errorMessage;

  // ============ CATÉGORIES ============
  List<ActivityCategory> _categories = [];
  bool _isLoadingCategories = false;
  int? _selectedCategoryId;

  // ============ FICHIERS ET ASSETS ============
  // Cover Image
  File? _coverImageFile;
  int? _coverImageAssetId;
  bool _isUploadingCover = false;
  double _coverUploadProgress = 0.0;

  // Lottie Animation
  File? _lottieFile;
  int? _lottieAssetId;
  bool _isUploadingLottie = false;
  double _lottieUploadProgress = 0.0;

  // Audio Guide
  File? _audioGuideFile;
  int? _audioGuideAssetId;
  bool _isUploadingAudio = false;
  double _audioUploadProgress = 0.0;

  // ============ CHAMPS ACTIVITÉ - AVEC VALEURS PAR DÉFAUT ============
  String _type = ActivityTypeEnum.MEDITATION.displayWithEmoji;
  String _difficultyLevel = DifficultyLevelEnum.BEGINNER.displayName;
  String _selectedMoodImpact = MoodImpactEnum.CALM.displayName;
  String _selectedTimeOfDay = TimeOfDayEnum.MORNING.displayName;
  String _selectedIdealEnvironment = IdealEnvironmentEnum.QUIET.displayName;
  String _selectedEquipmentRequired = EquipmentRequiredEnum.NONE.displayName;

  // ============ CONFIGURATION ============
  bool _requiresPreparation = false;
  int _preparationTimeSeconds = 300;
  bool _isGuided = true;
  bool _hasBackgroundMusic = false;
  bool _isOfflineAvailable = false;
  int _maxParticipants = 1;
  int _energyLevel = 3;
  int _focusLevel = 3;
  bool _hasGuidedAudio = true;
  bool _hasVideoGuide = false;
  bool _hasAnimation = true;
  bool _isInteractive = false;
  bool _hasReminders = false;
  bool _hasProgressTracking = true;
  int _minimumAge = 0;
  bool _isAccessible = true;

  // ============ LISTES DE SÉLECTION ============
  final List<String> _activityTypes = ActivityTypeEnum.displayOptions;
  final List<String> _difficultyLevels = DifficultyLevelEnum.displayOptions;
  final List<String> _timeOfDayOptions = TimeOfDayEnum.displayOptions;
  final List<String> _moodImpactOptions = MoodImpactEnum.displayOptions;
  final List<String> _environmentOptions = IdealEnvironmentEnum.displayOptions;
  final List<String> _equipmentOptions = EquipmentRequiredEnum.displayOptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _tagsController.dispose();
    _instructionsController.dispose();
    _prerequisitesController.dispose();
    _benefitsController.dispose();
    _colorHexController.dispose();
    _iconNameController.dispose();
    super.dispose();
  }

  // ============ INITIALISATION ============
  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _authService = Provider.of<AuthService>(context, listen: false);
      await _authService!.initialize();

      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.initialize();

      _activityService = ActivityApiService();
      _mediaService = MediaService(apiService);

      await _checkUserRole();
      await _loadCategories();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur d\'initialisation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final currentUser = await _authService!.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Vous devez être connecté pour accéder à cette page';
          _isAdmin = false;
          _isContentCreator = false;
          _isLoading = false;
        });
        return;
      }

      final isAdmin = currentUser.isAdmin;
      final isContentCreator = currentUser.isContentCreator;

      setState(() {
        _isAdmin = isAdmin;
        _isContentCreator = isContentCreator;
        _isLoading = false;
      });

      if (!isAdmin && !isContentCreator) {
        setState(() {
          _errorMessage =
              'Accès non autorisé. Cette page est réservée aux administrateurs et créateurs de contenu.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la vérification des permissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    if (_activityService == null) return;

    setState(() => _isLoadingCategories = true);

    try {
      final categories = await _activityService!.getCategories(
        activeOnly: true,
      );
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
          if (categories.isNotEmpty && _selectedCategoryId == null) {
            _selectedCategoryId = categories.first.id;
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur chargement catégories: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============ GESTION DES FICHIERS ============

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (file != null) {
        setState(() {
          _coverImageFile = File(file.path);
          _coverImageAssetId = null;
          _coverUploadProgress = 0.0;
        });
        await _uploadCoverImage();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur sélection cover: $e');
    }
  }

  Future<void> _uploadCoverImage() async {
    if (_coverImageFile == null ||
        _authService == null ||
        _mediaService == null)
      return;

    try {
      setState(() {
        _isUploadingCover = true;
        _coverUploadProgress = 0.0;
      });

      _simulateUploadProgress(
        () => _coverUploadProgress,
        (value) => _coverUploadProgress = value,
      );

      final currentUser = await _authService!.currentUser;
      if (currentUser == null || currentUser.id == null) {
        throw Exception('Utilisateur non connecté ou ID manquant');
      }

      final response = await _mediaService!.uploadMediaSimple(
        currentUser.id!,
        _coverImageFile!,
        category: 'ACTIVITY_COVER',
        isPublic: true,
      );

      setState(() {
        _coverImageAssetId = response.mediaId;
        _coverUploadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _showSuccessSnackBar('✅ Cover uploadée (ID: ${response.mediaId})');
    } catch (e) {
      setState(() => _coverUploadProgress = 0.0);
      _showErrorSnackBar('❌ Erreur upload cover: $e');
    } finally {
      setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickLottieFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'lottie'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        setState(() {
          _lottieFile = file;
          _lottieAssetId = null;
          _lottieUploadProgress = 0.0;
        });
        await _uploadLottieFile();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur sélection Lottie: $e');
    }
  }

  Future<void> _uploadLottieFile() async {
    if (_lottieFile == null || _authService == null || _mediaService == null)
      return;

    try {
      setState(() {
        _isUploadingLottie = true;
        _lottieUploadProgress = 0.0;
      });

      _simulateUploadProgress(
        () => _lottieUploadProgress,
        (value) => _lottieUploadProgress = value,
      );

      final currentUser = await _authService!.currentUser;
      if (currentUser == null || currentUser.id == null) {
        throw Exception('Utilisateur non connecté ou ID manquant');
      }

      final response = await _mediaService!.uploadLottieFile(
        currentUser.id!,
        _lottieFile!,
        category: 'ACTIVITY_LOTTIE',
        isPublic: true,
      );

      setState(() {
        _lottieAssetId = response.mediaId;
        _lottieUploadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _showSuccessSnackBar(
        '✅ Animation Lottie uploadée (ID: ${response.mediaId})',
      );
    } catch (e) {
      setState(() => _lottieUploadProgress = 0.0);
      _showErrorSnackBar('❌ Erreur upload Lottie: $e');
    } finally {
      setState(() => _isUploadingLottie = false);
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        setState(() {
          _audioGuideFile = file;
          _audioGuideAssetId = null;
          _audioUploadProgress = 0.0;
        });
        await _uploadAudioFile();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur sélection audio: $e');
    }
  }

  Future<void> _uploadAudioFile() async {
    if (_audioGuideFile == null ||
        _authService == null ||
        _mediaService == null)
      return;

    try {
      setState(() {
        _isUploadingAudio = true;
        _audioUploadProgress = 0.0;
      });

      _simulateUploadProgress(
        () => _audioUploadProgress,
        (value) => _audioUploadProgress = value,
      );

      final currentUser = await _authService!.currentUser;
      if (currentUser == null || currentUser.id == null) {
        throw Exception('Utilisateur non connecté ou ID manquant');
      }

      final response = await _mediaService!.uploadMediaSimple(
        currentUser.id!,
        _audioGuideFile!,
        category: 'ACTIVITY_AUDIO',
        isPublic: true,
      );

      setState(() {
        _audioGuideAssetId = response.mediaId;
        _audioUploadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _showSuccessSnackBar('✅ Audio uploadé (ID: ${response.mediaId})');
    } catch (e) {
      setState(() => _audioUploadProgress = 0.0);
      _showErrorSnackBar('❌ Erreur upload audio: $e');
    } finally {
      setState(() => _isUploadingAudio = false);
    }
  }

  void _simulateUploadProgress(
    double Function() getProgress,
    Function(double) setProgress,
  ) {
    const totalSteps = 10;
    var currentStep = 0;

    final timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentStep++;
      setProgress(currentStep / totalSteps);

      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }

  // ============ SNACKBARS ============
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============ VALIDATION ET SOUMISSION ============
  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Le titre est requis');
      return false;
    }

    if (_selectedCategoryId == null) {
      _showErrorSnackBar('Veuillez sélectionner une catégorie');
      return false;
    }

    if (_durationController.text.trim().isEmpty) {
      _showErrorSnackBar('La durée est requise');
      return false;
    }

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      _showErrorSnackBar('Durée invalide');
      return false;
    }

    if (_coverImageAssetId == null) {
      _showErrorSnackBar('L\'image de couverture est requise');
      return false;
    }

    if (_lottieAssetId == null) {
      _showErrorSnackBar('L\'animation Lottie est requise');
      return false;
    }

    if (_audioGuideAssetId == null) {
      _showErrorSnackBar('Le guide audio est requis');
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;
    if (_activityService == null || _authService == null) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await _authService!.currentUser;
      if (currentUser == null || currentUser.id == null) {
        throw Exception('Utilisateur non connecté');
      }

      final durationSeconds = int.parse(_durationController.text.trim()) * 60;

      // ✅ CONVERTIR LES VALEURS D'AFFICHAGE EN VALEURS BACKEND
      final typeBackendValue = ActivityTypeEnum.getBackendValueFromDisplay(
        _type,
      );
      if (typeBackendValue == null) {
        throw Exception('Type d\'activité invalide');
      }

      final difficultyBackendValue =
          DifficultyLevelEnum.getBackendValueFromDisplay(_difficultyLevel);
      if (difficultyBackendValue == null) {
        throw Exception('Niveau de difficulté invalide');
      }

      final moodImpactBackendValue = MoodImpactEnum.getBackendValueFromDisplay(
        _selectedMoodImpact,
      );
      final timeOfDayBackendValue = TimeOfDayEnum.getBackendValueFromDisplay(
        _selectedTimeOfDay,
      );
      final idealEnvironmentBackendValue =
          IdealEnvironmentEnum.getBackendValueFromDisplay(
            _selectedIdealEnvironment,
          );
      final equipmentRequiredBackendValue =
          EquipmentRequiredEnum.getBackendValueFromDisplay(
            _selectedEquipmentRequired,
          );

      // ✅ Construction de la configuration
      final configuration = ActivityConfigurationImpl(
        requiresPreparation: _requiresPreparation,
        preparationTimeSeconds: _preparationTimeSeconds,
        isGuided: _isGuided,
        hasBackgroundMusic: _hasBackgroundMusic,
        isOfflineAvailable: _isOfflineAvailable,
        maxParticipants: _maxParticipants,
        energyLevel: _energyLevel,
        focusLevel: _focusLevel,
        moodImpact: moodImpactBackendValue ?? 'CALM',
        recommendedTimeOfDay: timeOfDayBackendValue ?? 'MORNING',
        idealEnvironment: idealEnvironmentBackendValue ?? 'QUIET',
        equipmentRequired: equipmentRequiredBackendValue ?? 'NONE',
        hasGuidedAudio: _hasGuidedAudio,
        hasVideoGuide: _hasVideoGuide,
        hasAnimation: _hasAnimation,
        isInteractive: _isInteractive,
        hasReminders: _hasReminders,
        hasProgressTracking: _hasProgressTracking,
        minimumAge: _minimumAge,
        isAccessible: _isAccessible,
      );

      // ✅ Construction de la requête DTO
      final request = ActivityRequestDTO(
        title: _titleController.text.trim(),
        shortDescription: _shortDescriptionController.text.trim().isNotEmpty
            ? _shortDescriptionController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        type: typeBackendValue,
        categoryId: _selectedCategoryId!,
        tags: _tagsController.text.trim().isNotEmpty
            ? _tagsController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList()
            : null,
        durationSeconds: durationSeconds,
        difficultyLevel: difficultyBackendValue,
        coverImageAssetId: _coverImageAssetId!,
        lottieAnimationAssetId: _lottieAssetId!,
        audioGuideAssetId: _audioGuideAssetId!,
        iconName: _iconNameController.text.trim().isNotEmpty
            ? _iconNameController.text.trim()
            : null,
        colorHex: _colorHexController.text.trim().isNotEmpty
            ? _colorHexController.text.trim()
            : null,
        configuration: configuration,
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        prerequisites: _prerequisitesController.text.trim().isNotEmpty
            ? _prerequisitesController.text.trim()
            : null,
        benefits: _benefitsController.text.trim().isNotEmpty
            ? _benefitsController.text.trim()
            : null,
      );

      // ✅ Création de l'activité
      await _activityService!.createActivity(request);

      _showSuccessSnackBar('✅ Activité créée avec succès !');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('❌ Erreur création: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============ WIDGETS UI ============

  Widget _buildFilePickerCard({
    required String title,
    required String? fileName,
    required VoidCallback onPick,
    required IconData icon,
    required bool required,
    required bool isUploading,
    required double uploadProgress,
    required int? assetId,
  }) {
    final bool isUploaded = assetId != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: required && !isUploaded
              ? Colors.red.shade300
              : isUploaded
              ? Colors.green.shade200
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isUploading ? null : onPick,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUploaded
                      ? Colors.green.shade50
                      : isUploading
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isUploading
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                value: uploadProgress,
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF7DBBC3),
                                ),
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                            Text(
                              '${(uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          isUploaded ? Icons.check_circle : icon,
                          color: isUploaded
                              ? Colors.green
                              : const Color(0xFF7DBBC3),
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        if (required)
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (fileName != null)
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (!isUploaded && !isUploading)
                      Text(
                        required ? 'Aucun fichier sélectionné' : 'Optionnel',
                        style: TextStyle(
                          fontSize: 12,
                          color: required
                              ? Colors.red.shade400
                              : Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (isUploaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ID: $assetId',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (isUploading)
                const SizedBox(width: 8)
              else if (isUploaded)
                Icon(Icons.check_circle, color: Colors.green.shade400, size: 24)
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DBBC3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF7DBBC3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Configuration avancée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Préparation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Nécessite une préparation',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'L\'utilisateur doit se préparer avant',
                    ),
                    value: _requiresPreparation,
                    onChanged: (value) =>
                        setState(() => _requiresPreparation = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_requiresPreparation) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Temps de préparation:'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _preparationTimeSeconds.toDouble(),
                            min: 0,
                            max: 900,
                            divisions: 6,
                            label: '${_preparationTimeSeconds ~/ 60} min',
                            onChanged: (value) => setState(() {
                              _preparationTimeSeconds = value.toInt();
                            }),
                            activeColor: const Color(0xFF7DBBC3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7DBBC3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_preparationTimeSeconds ~/ 60} min',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7DBBC3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Type de guide
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Activité guidée',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Instructions audio/vidéo'),
                    value: _isGuided,
                    onChanged: (value) => setState(() => _isGuided = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Musique d\'ambiance',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Inclure une musique de fond'),
                    value: _hasBackgroundMusic,
                    onChanged: (value) =>
                        setState(() => _hasBackgroundMusic = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Disponible hors ligne',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Téléchargement pour utilisation sans connexion',
                    ),
                    value: _isOfflineAvailable,
                    onChanged: (value) =>
                        setState(() => _isOfflineAvailable = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Participants et niveaux
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Participants',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 20,
                        color: Color(0xFF7DBBC3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _maxParticipants.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_maxParticipants',
                          onChanged: (value) => setState(() {
                            _maxParticipants = value.toInt();
                          }),
                          activeColor: const Color(0xFF7DBBC3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DBBC3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_maxParticipants',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7DBBC3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Niveau d\'énergie',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 20,
                        color: Color(0xFFF9A826),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _energyLevel.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _getEnergyLabel(_energyLevel),
                          onChanged: (value) => setState(() {
                            _energyLevel = value.toInt();
                          }),
                          activeColor: const Color(0xFFF9A826),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9A826).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getEnergyLabel(_energyLevel),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF9A826),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Niveau de concentration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.center_focus_strong,
                        size: 20,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _focusLevel.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _getFocusLabel(_focusLevel),
                          onChanged: (value) => setState(() {
                            _focusLevel = value.toInt();
                          }),
                          activeColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getFocusLabel(_focusLevel),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Environnement et équipement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Impact émotionnel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedMoodImpact,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _moodImpactOptions.map((impact) {
                      return DropdownMenuItem(
                        value: impact,
                        child: Text(impact),
                      );
                    }).toList(),
                    onChanged: (value) => setState(
                      () => _selectedMoodImpact =
                          value ?? MoodImpactEnum.CALM.displayName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Moment idéal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedTimeOfDay,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _timeOfDayOptions.map((time) {
                      return DropdownMenuItem(value: time, child: Text(time));
                    }).toList(),
                    onChanged: (value) => setState(
                      () => _selectedTimeOfDay =
                          value ?? TimeOfDayEnum.MORNING.displayName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Environnement idéal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedIdealEnvironment,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _environmentOptions.map((env) {
                      return DropdownMenuItem(value: env, child: Text(env));
                    }).toList(),
                    onChanged: (value) => setState(
                      () => _selectedIdealEnvironment =
                          value ?? IdealEnvironmentEnum.QUIET.displayName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Équipement requis',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedEquipmentRequired,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _equipmentOptions.map((eq) {
                      return DropdownMenuItem(value: eq, child: Text(eq));
                    }).toList(),
                    onChanged: (value) => setState(
                      () => _selectedEquipmentRequired =
                          value ?? EquipmentRequiredEnum.NONE.displayName,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 5: Fonctionnalités supplémentaires
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Audio guidé',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _hasGuidedAudio,
                    onChanged: (value) =>
                        setState(() => _hasGuidedAudio = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Guide vidéo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _hasVideoGuide,
                    onChanged: (value) =>
                        setState(() => _hasVideoGuide = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Animation',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _hasAnimation,
                    onChanged: (value) => setState(() => _hasAnimation = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Interactif',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _isInteractive,
                    onChanged: (value) =>
                        setState(() => _isInteractive = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Rappels',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _hasReminders,
                    onChanged: (value) => setState(() => _hasReminders = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Suivi de progression',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _hasProgressTracking,
                    onChanged: (value) =>
                        setState(() => _hasProgressTracking = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 6: Âge minimum et accessibilité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Âge minimum:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Slider(
                          value: _minimumAge.toDouble(),
                          min: 0,
                          max: 18,
                          divisions: 18,
                          label: _minimumAge == 0
                              ? 'Tous âges'
                              : '$_minimumAge ans',
                          onChanged: (value) => setState(() {
                            _minimumAge = value.toInt();
                          }),
                          activeColor: const Color(0xFF7DBBC3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DBBC3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _minimumAge == 0 ? 'Tous' : '$_minimumAge+',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7DBBC3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text(
                      'Accessible',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Conçu pour être accessible à tous'),
                    value: _isAccessible,
                    onChanged: (value) => setState(() => _isAccessible = value),
                    activeColor: const Color(0xFF7DBBC3),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1:
        return 'Très faible';
      case 2:
        return 'Faible';
      case 3:
        return 'Modéré';
      case 4:
        return 'Élevé';
      case 5:
        return 'Très élevé';
      default:
        return 'Modéré';
    }
  }

  String _getFocusLabel(int level) {
    switch (level) {
      case 1:
        return 'Très faible';
      case 2:
        return 'Faible';
      case 3:
        return 'Modéré';
      case 4:
        return 'Élevé';
      case 5:
        return 'Très élevé';
      default:
        return 'Modéré';
    }
  }

  // ============ VUES ============
  Widget _buildUnauthorizedView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Accès non autorisé',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Accès réservé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ??
                    'Cette fonctionnalité est réservée aux administrateurs et créateurs de contenu.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DBBC3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Retour',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chargement...',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DBBC3)),
            ),
            SizedBox(height: 24),
            Text(
              'Vérification des permissions...',
              style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (!_isAdmin && !_isContentCreator) {
      return _buildUnauthorizedView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Nouvelle activité',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('À propos'),
                    content: const Text(
                      'Tous les champs marqués d\'un * sont obligatoires.\n\n'
                      'Les fichiers doivent être uploadés avant la création de l\'activité.\n\n'
                      'Les ID des fichiers sont automatiquement assignés après upload.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Compris'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ============ INDICATEUR UPLOADS ============
            if (_isUploadingCover || _isUploadingLottie || _isUploadingAudio)
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload en cours...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isUploadingCover)
                              _buildUploadProgressRow(
                                'Cover',
                                _coverUploadProgress,
                              ),
                            if (_isUploadingLottie)
                              _buildUploadProgressRow(
                                'Animation',
                                _lottieUploadProgress,
                              ),
                            if (_isUploadingAudio)
                              _buildUploadProgressRow(
                                'Audio',
                                _audioUploadProgress,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // ============ TITRE ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre de l\'activité *',
                    hintText: 'Méditation du matin',
                    prefixIcon: const Icon(
                      Icons.title,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLength: 200,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est requis';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============ DESCRIPTION COURTE ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _shortDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description courte',
                    hintText: 'Une brève description (max 150 caractères)',
                    prefixIcon: const Icon(
                      Icons.short_text,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLength: 150,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============ DESCRIPTION DÉTAILLÉE ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description détaillée',
                    hintText: 'Description complète de l\'activité...',
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============ TYPE ET CATÉGORIE ============
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: const Icon(
                            Icons.category,
                            color: Color(0xFF7DBBC3),
                          ),
                          border: InputBorder.none,
                        ),
                        items: _activityTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) => setState(
                          () => _type = value ?? _activityTypes.first,
                        ),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _isLoadingCategories
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Catégorie *',
                                prefixIcon: const Icon(
                                  Icons.folder,
                                  color: Color(0xFF7DBBC3),
                                ),
                                border: InputBorder.none,
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCategoryId = value),
                              validator: (value) =>
                                  value == null ? 'Requis' : null,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============ DURÉE ET DIFFICULTÉ ============
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextFormField(
                        controller: _durationController,
                        decoration: InputDecoration(
                          labelText: 'Durée (minutes) *',
                          prefixIcon: const Icon(
                            Icons.timer,
                            color: Color(0xFF7DBBC3),
                          ),
                          suffixText: 'min',
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requis';
                          final duration = int.tryParse(value);
                          if (duration == null || duration <= 0)
                            return 'Durée invalide';
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DropdownButtonFormField<String>(
                        value: _difficultyLevel,
                        decoration: InputDecoration(
                          labelText: 'Difficulté *',
                          prefixIcon: const Icon(
                            Icons.speed,
                            color: Color(0xFF7DBBC3),
                          ),
                          border: InputBorder.none,
                        ),
                        items: _difficultyLevels.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) => setState(
                          () => _difficultyLevel =
                              value ?? _difficultyLevels.first,
                        ),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============ TAGS ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (séparés par des virgules)',
                    hintText: 'relaxation, sommeil, stress',
                    prefixIcon: const Icon(Icons.tag, color: Color(0xFF7DBBC3)),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLength: 500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============ COULEUR ET ICÔNE ============
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Choisir une couleur'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: Color(
                                  int.tryParse(
                                        _colorHexController.text.replaceAll(
                                          '#',
                                          '0xFF',
                                        ),
                                      ) ??
                                      0xFF7DBBC3,
                                ),
                                onColorChanged: (color) {
                                  setState(() {
                                    _colorHexController.text =
                                        '#${color.value.toRadixString(16).substring(2)}';
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.tryParse(
                                        _colorHexController.text.replaceAll(
                                          '#',
                                          '0xFF',
                                        ),
                                      ) ??
                                      0xFF7DBBC3,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Couleur',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Text(
                                    _colorHexController.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.color_lens,
                              color: Color(0xFF7DBBC3),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _iconNameController,
                        decoration: InputDecoration(
                          labelText: 'Icône',
                          hintText: 'spa, fitness, etc.',
                          prefixIcon: const Icon(
                            Icons.emoji_emotions,
                            color: Color(0xFF7DBBC3),
                          ),
                          border: InputBorder.none,
                        ),
                        maxLength: 50,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============ FICHIERS OBLIGATOIRES ============
            const Text(
              'Fichiers requis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),

            // Cover Image
            _buildFilePickerCard(
              title: 'Image de couverture',
              fileName: _coverImageFile?.path.split('/').last,
              onPick: _pickCoverImage,
              icon: Icons.image,
              required: true,
              isUploading: _isUploadingCover,
              uploadProgress: _coverUploadProgress,
              assetId: _coverImageAssetId,
            ),
            const SizedBox(height: 12),

            // Lottie Animation
            _buildFilePickerCard(
              title: 'Animation Lottie',
              fileName: _lottieFile?.path.split('/').last,
              onPick: _pickLottieFile,
              icon: Icons.animation,
              required: true,
              isUploading: _isUploadingLottie,
              uploadProgress: _lottieUploadProgress,
              assetId: _lottieAssetId,
            ),
            const SizedBox(height: 12),

            // Audio Guide
            _buildFilePickerCard(
              title: 'Guide audio',
              fileName: _audioGuideFile?.path.split('/').last,
              onPick: _pickAudioFile,
              icon: Icons.audiotrack,
              required: true,
              isUploading: _isUploadingAudio,
              uploadProgress: _audioUploadProgress,
              assetId: _audioGuideAssetId,
            ),
            const SizedBox(height: 24),

            // ============ INSTRUCTIONS ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _instructionsController,
                  decoration: InputDecoration(
                    labelText: 'Instructions détaillées',
                    hintText:
                        'Instructions pas à pas pour réaliser l\'activité...',
                    prefixIcon: const Icon(
                      Icons.list_alt,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 2000,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============ PRÉREQUIS ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _prerequisitesController,
                  decoration: InputDecoration(
                    labelText: 'Prérequis',
                    hintText:
                        'Ce qu\'il faut savoir ou avoir avant de commencer...',
                    prefixIcon: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============ BÉNÉFICES ============
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _benefitsController,
                  decoration: InputDecoration(
                    labelText: 'Bénéfices',
                    hintText: 'Les bienfaits de cette activité...',
                    prefixIcon: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============ CONFIGURATION AVANCÉE ============
            _buildConfigurationSection(),
            const SizedBox(height: 32),

            // ============ BOUTON DE SOUMISSION ============
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    (_isSubmitting ||
                        _isUploadingCover ||
                        _isUploadingLottie ||
                        _isUploadingAudio)
                    ? null
                    : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline, size: 24),
                label: Text(
                  _isSubmitting ? 'Création en cours...' : 'Créer l\'activité',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DBBC3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgressRow(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7DBBC3),
              ),
              backgroundColor: Colors.blue.shade100,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
