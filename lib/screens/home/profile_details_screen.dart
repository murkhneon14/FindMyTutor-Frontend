import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/api.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback? onProfileUpdated;

  const ProfileDetailsScreen({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _userData;
  bool _isEditing = false;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _classGradeController;
  late TextEditingController _schoolNameController;
  late TextEditingController _guardianNameController;
  late TextEditingController _learningGoalsController;
  late TextEditingController _addressController;
  late TextEditingController _qualificationsController;
  late TextEditingController _experienceController;
  late TextEditingController _subjectsController;
  late TextEditingController _feesController;
  late TextEditingController _timingsController;
  late TextEditingController _bioController;
  late TextEditingController _minFeesController;
  late TextEditingController _maxFeesController;
  late TextEditingController _preferredClassesController;

  String? _selectedGender;
  DateTime? _selectedDob;
  List<String> _selectedGrades = [];
  List<String> _selectedPreferredClasses = [];
  final List<String> _grades = [
    'Pre-School',
    '1st Grade',
    '2nd Grade',
    '3rd Grade',
    '4th Grade',
    '5th Grade',
    '6th Grade',
    '7th Grade',
    '8th Grade',
    '9th Grade',
    '10th Grade',
    '11th Grade',
    '12th Grade',
    'BA',
    'B.COM',
    'B.Sc',
    'Baking Lessons',
    'Music Lessons',
  ];
  List<String> _selectedSubjects = [];
  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Economics',
    'Business Studies',
    'Geography',
    'Hindi',
    'Political Science',
    'Accountancy',
    'Baking Lessons',
    'Music Lessons',
  ];
  final List<String> _experienceOptions = [
    'Beginner',
    '1+',
    '2+',
    '3+',
    '4+',
    '5+',
    '6+',
    '7+',
    '8+',
    '9+',
    '10+',
    '10+ above'
  ];

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.user ?? {});
    _initControllers();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Debug: Print user role information
    print('👤 ProfileDetailsScreen - User Role: ${_userData['role']}');
    print('👤 ProfileDetailsScreen - Has teacherProfile: ${_userData['teacherProfile'] != null}');
    print('👤 ProfileDetailsScreen - Has studentProfile: ${_userData['studentProfile'] != null}');
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _userData['name']?.toString() ?? '');
    _emailController = TextEditingController(text: _userData['email']?.toString() ?? '');
    
    // Student profile data
    final studentProfile = _userData['studentProfile'] as Map<String, dynamic>?;
    
    // Parse classGrade into _selectedGrades list
    final gradesRaw = studentProfile?['classGrade'];
    if (gradesRaw != null) {
      if (gradesRaw is List) {
        _selectedGrades = gradesRaw.map((e) => e.toString()).toList();
      } else if (gradesRaw is String) {
        _selectedGrades = gradesRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    _classGradeController = TextEditingController(text: _selectedGrades.join(', '));
    _schoolNameController = TextEditingController(text: studentProfile?['schoolName']?.toString() ?? '');
    _guardianNameController = TextEditingController(text: studentProfile?['guardianName']?.toString() ?? '');
    _learningGoalsController = TextEditingController(text: studentProfile?['learningGoals']?.toString() ?? '');
    _addressController = TextEditingController(text: studentProfile?['address']?.toString() ?? '');
    
    // Teacher profile data
    final teacherProfile = _userData['teacherProfile'] as Map<String, dynamic>?;
    _qualificationsController = TextEditingController(text: teacherProfile?['qualifications']?.toString() ?? '');
    _experienceController = TextEditingController(text: teacherProfile?['experience']?.toString() ?? '');
    
    final subjectsRaw = teacherProfile?['subjects'];
    if (subjectsRaw != null) {
      if (subjectsRaw is List) {
        _selectedSubjects = subjectsRaw.map((e) => e.toString()).toList();
      } else if (subjectsRaw is String) {
        _selectedSubjects = subjectsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    _subjectsController = TextEditingController(text: _selectedSubjects.join(', '));
    
    // Parse preferred classes
    final prefClassesRaw = teacherProfile?['preferredClasses'];
    if (prefClassesRaw != null) {
      if (prefClassesRaw is List) {
        _selectedPreferredClasses = prefClassesRaw.map((e) => e.toString()).toList();
      } else if (prefClassesRaw is String) {
        _selectedPreferredClasses = prefClassesRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    _preferredClassesController = TextEditingController(text: _selectedPreferredClasses.join(', '));
    
    _feesController = TextEditingController(text: teacherProfile?['fees']?.toString() ?? '');
    
    // Initialize fee range controllers
    final minFees = teacherProfile?['minFees']?.toString() ?? '500';
    final maxFees = teacherProfile?['maxFees']?.toString() ?? '10000';
    _minFeesController = TextEditingController(text: minFees);
    _maxFeesController = TextEditingController(text: maxFees);

    _timingsController = TextEditingController(text: teacherProfile?['timings']?.toString() ?? '');
    _bioController = TextEditingController(text: teacherProfile?['bio']?.toString() ?? '');

    // Get gender from either student or teacher profile
    final profileData = studentProfile ?? teacherProfile;
    _selectedGender = _capitalizeFirst(profileData?['gender']?.toString() ?? '');
    if (_selectedGender?.isEmpty ?? true) _selectedGender = null;

    // Parse DOB
    final dobString = profileData?['dob']?.toString();
    if (dobString != null && dobString.isNotEmpty) {
      try {
        _selectedDob = DateTime.parse(dobString);
      } catch (_) {}
    }
  }

  String _formatSubjects(dynamic subjects) {
    if (subjects == null) return '';
    if (subjects is List) {
      return subjects.join(', ');
    }
    return subjects.toString();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _classGradeController.dispose();
    _schoolNameController.dispose();
    _guardianNameController.dispose();
    _learningGoalsController.dispose();
    _addressController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _subjectsController.dispose();
    _preferredClassesController.dispose();
    _feesController.dispose();
    _timingsController.dispose();
    _bioController.dispose();
    _minFeesController.dispose();
    _maxFeesController.dispose();
    super.dispose();
  }

  bool get _isTeacher {
    final role = _userData['role']?.toString().toLowerCase();
    final hasTeacherProfile = _userData['teacherProfile'] != null;
    
    print('🔍 _isTeacher check: role=$role, hasTeacherProfile=$hasTeacherProfile');
    
    // Check if role is 'teacher' OR if they have a teacherProfile
    return role == 'teacher' || hasTeacherProfile;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Session expired. Please login again.');
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Update profile based on user type
      final endpoint = _isTeacher
          ? ApiConfig.updateTeacherProfile
          : ApiConfig.updateStudentProfile;

      Map<String, dynamic> profileData;
      
      if (_isTeacher) {
        profileData = {
          'gender': _selectedGender?.toLowerCase(),
          'dob': _selectedDob?.toIso8601String(),
          'qualifications': _qualificationsController.text.trim(),
          'experience': _experienceController.text.trim(),
          'subjects': _selectedSubjects,
          'preferredClasses': _selectedPreferredClasses,
          'fees': int.tryParse(_feesController.text.trim()) ?? 0,
          'minFees': int.tryParse(_minFeesController.text.trim()) ?? 500,
          'maxFees': int.tryParse(_maxFeesController.text.trim()) ?? 10000,
          'timings': _timingsController.text.trim(),
        };
      } else {
        profileData = {
          'gender': _selectedGender?.toLowerCase(),
          'dob': _selectedDob?.toIso8601String(),
          'classGrade': _classGradeController.text.trim(),
          'schoolName': _schoolNameController.text.trim(),
          'guardianName': _guardianNameController.text.trim(),
          'learningGoals': _learningGoalsController.text.trim(),
          'address': _addressController.text.trim(),
        };
      }

      debugPrint('Updating profile with: ${jsonEncode(profileData)}');

      final response = await http.put(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(profileData),
      );

      debugPrint('Profile update response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // Update user name if changed
        if (_nameController.text.trim().isNotEmpty &&
            _nameController.text.trim() != _userData['name']) {
          await _updateName(token);
        }
        
        // Also update email if changed
        if (_emailController.text.trim().isNotEmpty &&
            _emailController.text.trim() != _userData['email']) {
          await _updateEmail(token);
        }

        if (mounted) {
          _showSuccess('Profile updated successfully!');
          setState(() {
            _isEditing = false;
          });
          widget.onProfileUpdated?.call();
        }
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _showError('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateName(String token) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': _nameController.text.trim()}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to update name');
      }
    } catch (e) {
      debugPrint('Error updating name: $e');
    }
  }

  Future<void> _updateEmail(String token) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateEmail),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': _emailController.text.trim()}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to update email');
      }
    } catch (e) {
      debugPrint('Error updating email: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(DateTime.now().year - 18),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Hero Header with Profile Avatar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
              actions: [
                if (!_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: TextButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withBlue(255),
                        AppTheme.accentColor,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      // Profile content
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // Avatar with ring
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Name
                              Text(
                                _userData['name']?.toString() ?? 'User',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Role badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isTeacher ? Icons.school : Icons.person,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isTeacher ? 'Teacher' : 'Student',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form Content
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      _buildSectionHeader('Personal Information', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildEditableCard(
                        children: [
                          _buildEditableField(
                            icon: Icons.person,
                            label: 'Full Name',
                            controller: _nameController,
                            enabled: _isEditing,
                            validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
                          ),
                          _buildDivider(),
                          _buildEditableField(
                            icon: Icons.email,
                            label: 'Email',
                            controller: _emailController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildDivider(),
                          _buildReadOnlyField(
                            icon: Icons.phone,
                            label: 'Phone Number',
                            value: _userData['phone']?.toString() ?? 'Not provided',
                            isLocked: true,
                          ),
                          _buildDivider(),
                          if (_isEditing)
                            _buildGenderSelector()
                          else
                            _buildReadOnlyField(
                              icon: Icons.transgender,
                              label: 'Gender',
                              value: _selectedGender ?? 'Not specified',
                            ),
                          _buildDivider(),
                          if (_isEditing)
                            _buildDateField()
                          else
                            _buildReadOnlyField(
                              icon: Icons.cake,
                              label: 'Date of Birth',
                              value: _selectedDob != null
                                  ? _formatDate(_selectedDob!)
                                  : 'Not specified',
                            ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Role-specific section
                      if (_isTeacher) ...[
                        _buildSectionHeader('Teaching Details', Icons.school),
                        const SizedBox(height: 16),
                        _buildEditableCard(
                          children: [
                            _buildEditableField(
                              icon: Icons.menu_book,
                              label: 'Subjects',
                              controller: _subjectsController,
                              enabled: _isEditing,
                              hint: 'Tap to select subjects',
                              readOnly: true,
                              onTap: _isEditing ? () => _showMultiSubjectPicker(context) : null,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.class_,
                              label: 'Preferred Classes',
                              controller: _preferredClassesController,
                              enabled: _isEditing,
                              hint: 'Tap to select preferred classes',
                              readOnly: true,
                              onTap: _isEditing ? () => _showPreferredClassesPicker(context) : null,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.school,
                              label: 'Qualifications',
                              controller: _qualificationsController,
                              enabled: _isEditing,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.work,
                              label: 'Years of Experience',
                              controller: _experienceController,
                              enabled: _isEditing,
                              hint: 'Tap to select experience',
                              readOnly: true,
                              onTap: _isEditing ? () => _showExperiencePicker(context) : null,
                            ),
                            _buildDivider(),
                            if (_isEditing)
                              _buildFeeRangeSelector()
                            else
                              _buildReadOnlyField(
                                icon: Icons.currency_rupee,
                                label: 'Fee Range (per month)',
                                value: '₹${_minFeesController.text} - ₹${_maxFeesController.text}',
                              ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.schedule,
                              label: 'Available Timings',
                              controller: _timingsController,
                              enabled: _isEditing,
                              hint: 'e.g., Mon-Fri, 4PM-8PM',
                            ),
                          ],
                        ),
                      ] else ...[
                        _buildSectionHeader('Academic Details', Icons.school),
                        const SizedBox(height: 16),
                        _buildEditableCard(
                          children: [
                            _buildEditableField(
                              icon: Icons.class_,
                              label: 'Class / Grade',
                              controller: _classGradeController,
                              enabled: _isEditing,
                              hint: 'Tap to select class/grade',
                              readOnly: true,
                              onTap: _isEditing ? () => _showMultiGradePicker(context) : null,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.business,
                              label: 'School / College Name',
                              controller: _schoolNameController,
                              enabled: _isEditing,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.family_restroom,
                              label: 'Guardian Name',
                              controller: _guardianNameController,
                              enabled: _isEditing,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.location_on,
                              label: 'Address',
                              controller: _addressController,
                              enabled: _isEditing,
                              maxLines: 2,
                            ),
                            _buildDivider(),
                            _buildEditableField(
                              icon: Icons.lightbulb_outline,
                              label: 'Learning Goals',
                              controller: _learningGoalsController,
                              enabled: _isEditing,
                              maxLines: 2,
                              hint: 'What do you want to learn?',
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Account Information
                      _buildSectionHeader('Account Information', Icons.info_outline),
                      const SizedBox(height: 16),
                      _buildEditableCard(
                        children: [
                          _buildReadOnlyField(
                            icon: Icons.calendar_today,
                            label: 'Member Since',
                            value: _formatDateTime(_userData['createdAt']),
                          ),
                          _buildDivider(),
                          _buildPremiumStatus(),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Save/Cancel buttons when editing
                      if (_isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                  _initControllers();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(
                                    color: isDarkMode ? Colors.white38 : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'Save Changes',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.15),
                AppTheme.accentColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableCard({required List<Widget> children}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDarkMode ? Colors.white12 : Colors.grey.shade100,
      indent: 70,
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white70 : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint ?? (enabled ? 'Enter $label' : ''),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: enabled,
                    fillColor: enabled
                        ? (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          if (enabled)
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
    bool isLocked = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white70 : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final genders = ['Male', 'Female', 'Other'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.transgender,
              color: isDarkMode ? Colors.white70 : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: genders.map((gender) {
                    final isSelected = _selectedGender == gender;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = gender),
                        child: Container(
                          margin: EdgeInsets.only(right: gender != genders.last ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected
                                ? null
                                : isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                                  ),
                          ),
                          child: Center(
                            child: Text(
                              gender,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isDarkMode
                                        ? Colors.white70
                                        : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.cake,
              color: isDarkMode ? Colors.white70 : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedDob != null
                              ? _formatDate(_selectedDob!)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _selectedDob != null
                                ? (isDarkMode ? Colors.white : AppTheme.textPrimary)
                                : (isDarkMode ? Colors.white30 : Colors.grey.shade400),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_month,
                          color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiGradePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMultiPickerSheet(
        'Select Class/Grade',
        _grades,
        _selectedGrades,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _selectedGrades = selected;
        _classGradeController.text = _selectedGrades.join(', ');
      });
    }
  }

  Widget _buildPremiumStatus() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isPremium = _userData['isPremium'] == true;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPremium
                  ? Colors.amber.withOpacity(0.15)
                  : isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: isPremium
                  ? Colors.amber.shade700
                  : isDarkMode
                      ? Colors.white70
                      : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium ? 'Premium Member' : 'Free Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPremium
                        ? Colors.amber.shade700
                        : isDarkMode
                            ? Colors.white
                            : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeeRangeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.currency_rupee,
              color: isDarkMode ? Colors.white70 : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fee Range (per month)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'lower range',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _minFeesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Min',
                              filled: true,
                              fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixText: '₹ ',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'higher range',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _maxFeesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Max',
                              filled: true,
                              fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixText: '₹ ',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExperiencePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPickerSheet(
        'Select Experience',
        _experienceOptions,
        _experienceController.text,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _experienceController.text = selected;
      });
    }
  }

  Widget _buildPickerSheet(String title, List<String> items, String selected) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item == selected;
                return ListTile(
                  title: Text(
                    item,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : isDarkMode
                              ? Colors.white
                              : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiSubjectPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMultiPickerSheet(
        'Select Subjects',
        _subjects,
        _selectedSubjects,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _selectedSubjects = selected;
        _subjectsController.text = _selectedSubjects.join(', ');
      });
    }
  }

  Widget _buildMultiPickerSheet(String title, List<String> items, List<String> selectedItems) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    List<String> tempSelected = List.from(selectedItems);
    
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom,
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        tempSelected.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tempSelected.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tempSelected.length} selected',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = tempSelected.contains(item);
                    return CheckboxListTile(
                      title: Text(
                        item,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      value: isSelected,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            tempSelected.add(item);
                          } else {
                            tempSelected.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done (${tempSelected.length} selected)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPreferredClassesPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMultiPickerSheet(
        'Select Preferred Classes',
        _grades,
        _selectedPreferredClasses,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _selectedPreferredClasses = selected;
        _preferredClassesController.text = _selectedPreferredClasses.join(', ');
      });
    }
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(dynamic dateTime) {
    try {
      if (dateTime == null) return 'Not available';
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return 'Not available';
      }
      return _formatDate(dt);
    } catch (_) {
      return 'Not available';
    }
  }
}
