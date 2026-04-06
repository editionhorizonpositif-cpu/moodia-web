// lib/pages/add_meditation_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/meditation.dart';
import '../models/media.dart';
import '../services/meditation_service.dart';
import '../services/media_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddMeditationPage extends StatefulWidget {
  const AddMeditationPage({super.key});

  @override
  State<AddMeditationPage> createState() => _AddMeditationPageState();
}

class _AddMeditationPageState extends State<AddMeditationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();

  MeditationService? _meditationService;
  MediaService? _mediaService;
  AuthService? _authService;

  File? _audioVideoFile;
  File? _posterImageFile;
  int? _audioVideoAssetId;
  int? _posterImageAssetId;

  // États d'upload pour chaque fichier
  bool _isUploadingAudioVideo = false;
  bool _isUploadingPoster = false;
  double _audioVideoUploadProgress = 0.0;
  double _posterUploadProgress = 0.0;

  bool _isPremium = false;
  String _difficultyLevel = 'BEGINNER';
  String _languageCode = 'fr';
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isContentCreator = false;
  String? _errorMessage;

  final List<String> _categories = [
    'Méditation',
    'Sommeil',
    'Stress',
    'Concentration',
    'Relaxation',
    'Yoga',
    'Respiration',
    'Pleine Conscience',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

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

      _meditationService = MeditationService(apiService);
      _mediaService = MediaService(apiService);

      await _checkUserRole();
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioVideo() async {
    if (_authService == null) return;

    final mediaType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir le type de média'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Vidéo'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: const Text('Audio'),
              onTap: () => Navigator.pop(context, 'audio'),
            ),
          ],
        ),
      ),
    );

    if (mediaType == null) return;

    try {
      FilePickerResult? result;

      if (mediaType == 'video') {
        result = await FilePicker.platform.pickFiles(type: FileType.video);
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        );
      }

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        setState(() {
          _audioVideoFile = file;
          _audioVideoAssetId = null;
          _audioVideoUploadProgress = 0.0;
        });

        await _uploadAudioVideo();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickPosterImage() async {
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
          _posterImageFile = File(file.path);
          _posterImageAssetId = null;
          _posterUploadProgress = 0.0;
        });
        await _uploadPosterImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadAudioVideo() async {
    if (_audioVideoFile == null ||
        _authService == null ||
        _mediaService == null) {
      return;
    }

    try {
      setState(() {
        _isUploadingAudioVideo = true;
        _audioVideoUploadProgress = 0.0;
      });

      // Simuler une progression pour l'upload
      _simulateAudioVideoUploadProgress();

      final currentUser = await _authService!.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Utiliser la méthode simplifiée
      final response = await _mediaService!.uploadMediaSimple(
        currentUser.id!,
        _audioVideoFile!,
        category: 'MEDITATION_AUDIO_VIDEO',
        isPublic: false,
      );

      setState(() {
        _audioVideoAssetId = response.mediaId;
        _audioVideoUploadProgress = 1.0; // Complété
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Petite pause pour l'animation

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${response.message} (ID: ${response.mediaId})'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _audioVideoUploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur upload audio/vidéo: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isUploadingAudioVideo = false;
      });
    }
  }

  void _simulateAudioVideoUploadProgress() {
    // Simuler une progression réaliste
    const totalSteps = 10;
    var currentStep = 0;

    final timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        currentStep++;
        _audioVideoUploadProgress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }

  Future<void> _uploadPosterImage() async {
    if (_posterImageFile == null ||
        _authService == null ||
        _mediaService == null) {
      return;
    }

    try {
      setState(() {
        _isUploadingPoster = true;
        _posterUploadProgress = 0.0;
      });

      // Simuler une progression pour l'upload
      _simulatePosterUploadProgress();

      final currentUser = await _authService!.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Utiliser la méthode simplifiée
      final response = await _mediaService!.uploadMediaSimple(
        currentUser.id!,
        _posterImageFile!,
        category: 'MEDITATION_POSTER',
        isPublic: true,
      );

      setState(() {
        _posterImageAssetId = response.mediaId;
        _posterUploadProgress = 1.0; // Complété
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Petite pause pour l'animation

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${response.message} (ID: ${response.mediaId})'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _posterUploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur upload image poster: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isUploadingPoster = false;
      });
    }
  }

  void _simulatePosterUploadProgress() {
    // Simuler une progression réaliste
    const totalSteps = 8;
    var currentStep = 0;

    final timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        currentStep++;
        _posterUploadProgress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _authService == null ||
        _meditationService == null) {
      return;
    }

    if (_audioVideoAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner et uploader un fichier audio/vidéo',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = await _authService!.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifiez que l'utilisateur a un ID
      if (currentUser.id == null) {
        throw Exception('ID utilisateur non disponible');
      }

      final request = MeditationCreateRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        audioVideoAssetId: _audioVideoAssetId,
        posterImageAssetId: _posterImageAssetId,
        durationMin: int.tryParse(_durationController.text) ?? 10,
        category: _categoryController.text.trim(),
        isPremium: _isPremium,
        difficultyLevel: _difficultyLevel,
        tags: _tagsController.text.trim().isNotEmpty
            ? _tagsController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList()
            : null,
        instructorName: _instructorController.text.trim().isNotEmpty
            ? _instructorController.text.trim()
            : null,
        languageCode: _languageCode,
      );

      // ← Passez l'ID utilisateur ici
      await _meditationService!.createMeditation(request, currentUser.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Méditation créée avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur création méditation: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildFilePicker(
    String title,
    String? fileName,
    VoidCallback onPick,
    IconData icon,
    bool required,
  ) {
    final bool isAudioVideo = required;
    final bool isUploaded = isAudioVideo
        ? _audioVideoAssetId != null
        : _posterImageAssetId != null;

    final bool isUploading = isAudioVideo
        ? _isUploadingAudioVideo
        : _isUploadingPoster;

    final double uploadProgress = isAudioVideo
        ? _audioVideoUploadProgress
        : _posterUploadProgress;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: required && !isUploaded
              ? Colors.red.shade300
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isUploading ? null : onPick,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône avec état
              if (isUploading)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: uploadProgress,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7DBBC3),
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    Text(
                      '${(uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                )
              else if (isUploaded)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 20),
                )
              else
                Icon(
                  icon,
                  color: required
                      ? (_audioVideoAssetId == null
                            ? Colors.red
                            : const Color(0xFF7DBBC3))
                      : const Color(0xFF7DBBC3),
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        if (required)
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),

                    if (fileName != null)
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                    // État d'upload
                    if (isUploading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: uploadProgress,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7DBBC3),
                            ),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upload en cours...',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      )
                    else if (isUploaded)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Uploadé',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isAudioVideo && _audioVideoAssetId != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '(ID: $_audioVideoAssetId)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            )
                          else if (!isAudioVideo && _posterImageAssetId != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '(ID: $_posterImageAssetId)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Flèche ou indicateur
              if (isUploading)
                const SizedBox(width: 8)
              else if (isUploaded)
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 20,
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

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
              Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                'Accès réservé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ??
                    'Cette fonctionnalité est réservée aux administrateurs et créateurs de contenu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retour'),
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
            SizedBox(height: 20),
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
          'Nouvelle Méditation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Indicateur d'état des uploads
            if (_isUploadingAudioVideo || _isUploadingPoster)
              Card(
                color: Colors.blue.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload en cours...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 20, 102, 196),
                              ),
                            ),
                            if (_isUploadingAudioVideo)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _audioVideoUploadProgress,
                                        minHeight: 4,
                                        borderRadius: BorderRadius.circular(2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF7DBBC3),
                                            ),
                                        backgroundColor: Colors.blue.shade100,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(_audioVideoUploadProgress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(
                                          255,
                                          21,
                                          101,
                                          192,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_isUploadingPoster)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _posterUploadProgress,
                                        minHeight: 4,
                                        borderRadius: BorderRadius.circular(2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.green,
                                            ),
                                        backgroundColor: Colors.green.shade100,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(_posterUploadProgress * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Titre
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    border: InputBorder.none,
                    hintText: 'Méditation du matin',
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

            // Description
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: InputBorder.none,
                    hintText: 'Description détaillée...',
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Catégorie
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _categoryController.text.isEmpty
                      ? _categories.first
                      : _categoryController.text,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie *',
                    border: InputBorder.none,
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryController.text = value ?? _categories.first;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La catégorie est requise';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Durée
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Durée (minutes) *',
                    border: InputBorder.none,
                    suffixText: 'min',
                    hintText: '10',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La durée est requise';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Durée invalide';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Audio/Video (obligatoire)
            _buildFilePicker(
              'Audio/Video *',
              _audioVideoFile?.path.split('/').last,
              _pickAudioVideo,
              Icons.videocam,
              true,
            ),

            const SizedBox(height: 16),

            // Image poster (optionnel)
            _buildFilePicker(
              'Image Poster',
              _posterImageFile?.path.split('/').last,
              _pickPosterImage,
              Icons.image,
              false,
            ),

            const SizedBox(height: 16),

            // Instructeur
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _instructorController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'instructeur',
                    border: InputBorder.none,
                    hintText: 'John Doe',
                  ),
                  maxLength: 100,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (séparés par des virgules)',
                    border: InputBorder.none,
                    hintText: 'relaxation, sommeil, stress',
                  ),
                  maxLength: 500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Configuration
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Premium
                    SwitchListTile(
                      title: const Text('Méditation Premium'),
                      subtitle: const Text('Réservée aux abonnés'),
                      value: _isPremium,
                      onChanged: (value) {
                        setState(() {
                          _isPremium = value;
                        });
                      },
                      activeColor: const Color(0xFF7DBBC3),
                    ),

                    const Divider(),

                    // Difficulté
                    DropdownButtonFormField<String>(
                      value: _difficultyLevel,
                      decoration: const InputDecoration(
                        labelText: 'Niveau de difficulté',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BEGINNER',
                          child: Text('Débutant'),
                        ),
                        DropdownMenuItem(
                          value: 'INTERMEDIATE',
                          child: Text('Intermédiaire'),
                        ),
                        DropdownMenuItem(
                          value: 'ADVANCED',
                          child: Text('Avancé'),
                        ),
                      ].toList(),
                      onChanged: (value) {
                        setState(() {
                          _difficultyLevel = value ?? 'BEGINNER';
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Langue
                    DropdownButtonFormField<String>(
                      value: _languageCode,
                      decoration: const InputDecoration(
                        labelText: 'Langue',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('Anglais')),
                        DropdownMenuItem(value: 'es', child: Text('Espagnol')),
                        DropdownMenuItem(value: 'de', child: Text('Allemand')),
                      ].toList(),
                      onChanged: (value) {
                        setState(() {
                          _languageCode = value ?? 'fr';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed:
                    (_isSubmitting ||
                        _isUploadingAudioVideo ||
                        _isUploadingPoster)
                    ? null
                    : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DBBC3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Créer la méditation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
