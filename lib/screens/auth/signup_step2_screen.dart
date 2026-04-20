import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api.dart';
import '../home/main_navigation.dart';
import '../../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class SignupStep2Screen extends StatefulWidget {
  final String name;
  final String phone; // Already verified via Firebase
  final String userType; // 'student' or 'teacher'
  final String? email; // Optional

  const SignupStep2Screen({
    super.key,
    required this.name,
    required this.phone,
    required this.userType,
    this.email,
  });

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _experienceController = TextEditingController();
  final _instituteController = TextEditingController();
  final _gradeController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _emailController = TextEditingController(); // Optional email
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _minFeesController = TextEditingController();
  final _maxFeesController = TextEditingController();
  final _dobController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTeacher = false;
  String? _selectedGender;
  DateTime? _selectedDob;
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;
  List<String> _selectedSubjects = [];
  List<String> _selectedPreferredClasses = [];
  List<String> _selectedGrades = [];
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
  ];
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
  ];

  @override
  void initState() {
    super.initState();
    _isTeacher = widget.userType == 'teacher';
    // Get location automatically for both teachers and students
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _experienceController.dispose();
    _instituteController.dispose();
    _gradeController.dispose();
    _guardianNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _minFeesController.dispose();
    _maxFeesController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 10),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token == null) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please verify OTP again.')),
          );
          return;
        }

        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final isTeacher = _isTeacher;
        http.Response response;

        debugPrint('Submitting profile. Teacher: $isTeacher');
        debugPrint('POST headers: ' + headers.toString());

        if (isTeacher) {
          // Validate required fields before sending
          if (_selectedGender == null || _selectedGender!.isEmpty) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select your gender')),
            );
            return;
          }
          
          if (_selectedSubjects.isEmpty) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select at least one preferred subject')),
            );
            return;
          }
          
          if (_experienceController.text.trim().isEmpty) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your experience')),
            );
            return;
          }
          
          if (_instituteController.text.trim().isEmpty) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter your qualifications')),
            );
            return;
          }
          

          // Check if location is available
          if (_currentLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable location to complete your profile'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          final teacherData = {
            'phone': widget.phone, // Already verified
            'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
            'dob': _selectedDob?.toIso8601String(),
            'gender': _selectedGender!.toLowerCase(),
            'qualifications': _instituteController.text.trim(),
            'experience': _experienceController.text.trim(),
            'subjects': _selectedSubjects,
            'preferredClasses': _selectedPreferredClasses,
            'fees': int.tryParse(_minFeesController.text.trim()) ?? 500, // Save start as base fee
            'minFees': int.tryParse(_minFeesController.text.trim()) ?? 500,
            'maxFees': int.tryParse(_maxFeesController.text.trim()) ?? 10000,
            'timings': 'flexible',
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
            'documents': [],
          };
          
          debugPrint('Sending teacher profile data: ${jsonEncode(teacherData)}');

          response = await http.post(
            Uri.parse(ApiConfig.teacherProfile),
            headers: headers,
            body: jsonEncode(teacherData),
          );
        } else {
          // Check if location is available for student
          if (_currentLocation == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable location to complete your profile'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          if (_selectedGrades.isEmpty) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select at least one class/grade'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Student profile with location
          final studentData = {
            'phone': widget.phone, // Already verified
            'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
            'dob': _selectedDob?.toIso8601String(),
            'gender': (_selectedGender ?? '').toLowerCase(),
            'classGrade': _selectedGrades.join(', '),
            'schoolName': _instituteController.text.trim(),
            'guardianName': _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
            'learningGoals': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            'address': _addressController.text.trim(),
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
          };
          
          debugPrint('Sending student profile data: ${jsonEncode(studentData)}');
          
          response = await http.post(
            Uri.parse(ApiConfig.studentProfile),
            headers: headers,
            body: jsonEncode(studentData),
          );
        }

        if (!mounted) return;

        setState(() => _isLoading = false);

        debugPrint('Profile response: ' + response.statusCode.toString() + ' ' + response.body);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile created successfully!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Go straight to Explore tab after successful signup
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigation(initialIndex: 1),
            ),
            (route) => false,
          );
        } else {
          final msg = _extractError(response.body) ?? 'Failed to create profile';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    }
  }

  String? _extractError(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map && map['message'] is String) return map['message'] as String;
    } catch (_) {}
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = position;
          _isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location obtained: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Unable to get location';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.accentColor.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and progress
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Consumer<ThemeNotifier>(
                          builder: (context, themeNotifier, _) {
                            final isDarkMode = themeNotifier.isDarkMode;
                            return IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        // Progress Indicator
                        _buildProgressIndicator(2, 2),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTeacher ? 'Teacher Profile' : 'Student Profile',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Step 2 of 2 - ${_isTeacher ? 'Professional' : 'Academic'} Details',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verified Phone Number (Read-only display)
                          _buildVerifiedPhoneDisplay(),
                          const SizedBox(height: 20),
                          
                          // Optional Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email (Optional)',
                            hint: 'Enter your email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && !value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Date of Birth
                          Text(
                            'Date of Birth',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dobController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            inputFormatters: [_DateInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'dd/mm/yyyy',
                              counterText: '',
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.edit_calendar_outlined,
                                    color: AppTheme.primaryColor),
                                onPressed: () => _selectDate(context),
                                tooltip: 'Pick from calendar',
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppTheme.primaryColor),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.length == 10) {
                                final parts = val.split('/');
                                if (parts.length == 3) {
                                  final d = int.tryParse(parts[0]);
                                  final m = int.tryParse(parts[1]);
                                  final y = int.tryParse(parts[2]);
                                  if (d != null && m != null && y != null) {
                                    try {
                                      final date = DateTime(y, m, d);
                                      if (date.isBefore(DateTime.now())) {
                                        setState(() => _selectedDob = date);
                                      }
                                    } catch (_) {}
                                  }
                                }
                              } else {
                                setState(() => _selectedDob = null);
                              }
                            },
                            validator: (val) {
                              if (_selectedDob == null) {
                                return 'Please enter a valid date of birth (dd/mm/yyyy)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Gender Selection
                          Text(
                            'Gender',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderOption('Male', Icons.male),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGenderOption('Female', Icons.female),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGenderOption('Other', Icons.transgender),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Conditional Fields based on User Type
                          if (_isTeacher) ...[
                            // Teacher Specific Fields
                            // Multi-select Subjects
                            _buildMultiSelectField(
                              label: 'Preferred Subjects',
                              hint: 'Tap to select preferred subjects',
                              icon: Icons.library_books_outlined,
                              selectedItems: _selectedSubjects,
                              onTap: () => _showMultiSubjectPicker(context),
                            ),
                            const SizedBox(height: 20),
                            
                            // Preferred Classes
                            _buildMultiSelectField(
                              label: 'Preferred Classes/Grades',
                              hint: 'Tap to select preferred classes',
                              icon: Icons.school_outlined,
                              selectedItems: _selectedPreferredClasses,
                              onTap: () => _showPreferredClassesPicker(context),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _experienceController,
                              label: 'Years of Experience',
                              hint: 'Select years of experience',
                              icon: Icons.work_outline,
                              readOnly: true,
                              onTap: () => _showExperiencePicker(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select years of experience';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _instituteController,
                              label: _isTeacher ? 'Qualification' : 'School/Institute Name',
                              hint: _isTeacher ? 'Enter your qualification' : 'Enter your school or institute name',
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return _isTeacher ? 'Please enter your qualification' : 'Please enter your school/institute name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            _buildFeeRangeSelector(),
                            const SizedBox(height: 20),
                            
                            // Location Section for Teachers
                            Text(
                              'Location',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _currentLocation != null 
                                      ? AppTheme.successColor.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _currentLocation != null 
                                            ? Icons.location_on 
                                            : Icons.location_off,
                                        color: _currentLocation != null 
                                            ? AppTheme.successColor 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _currentLocation != null
                                                  ? 'Location Obtained'
                                                  : _locationError ?? 'Location Required',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _currentLocation != null 
                                                    ? AppTheme.successColor 
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                            if (_currentLocation != null)
                                              Text(
                                                'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, Lon: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_isLoadingLocation)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.refresh),
                                          onPressed: _getCurrentLocation,
                                          color: AppTheme.primaryColor,
                                          tooltip: 'Refresh Location',
                                        ),
                                    ],
                                  ),
                                  if (_locationError != null && _currentLocation == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Tap refresh to get your location. This helps students find you.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _bioController,
                              label: 'Bio/Introduction',
                              hint: 'Tell us about yourself and your teaching style',
                              icon: Icons.info_outline,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please write a short bio';
                                }
                                if (value.length < 10) {
                                  return 'Please write at least 10 characters';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // Student/Parent Specific Fields
                            _buildMultiSelectField(
                              label: 'Class/Grade',
                              hint: 'Tap to select your class/grade',
                              icon: Icons.school_outlined,
                              selectedItems: _selectedGrades,
                              onTap: () => _showGradePicker(context),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _instituteController,
                              label: 'School/College Name',
                              hint: 'Enter your school/college name',
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your school/college name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _guardianNameController,
                              label: 'Guardian Name (if under 18)',
                              hint: 'Enter guardian name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            
                            // Location Section for Students
                            Text(
                              'Location',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _currentLocation != null 
                                      ? AppTheme.successColor.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _currentLocation != null 
                                            ? Icons.location_on 
                                            : Icons.location_off,
                                        color: _currentLocation != null 
                                            ? AppTheme.successColor 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _currentLocation != null
                                                  ? 'Location Obtained'
                                                  : _locationError ?? 'Location Required',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _currentLocation != null 
                                                    ? AppTheme.successColor 
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                            if (_currentLocation != null)
                                              Text(
                                                'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, Lon: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_isLoadingLocation)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.refresh),
                                          onPressed: _getCurrentLocation,
                                          color: AppTheme.primaryColor,
                                          tooltip: 'Refresh Location',
                                        ),
                                    ],
                                  ),
                                  if (_locationError != null && _currentLocation == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Tap refresh to get your location. This helps teachers find you.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _bioController,
                              label: 'Learning Goals',
                              hint: 'What do you want to achieve with tutoring?',
                              icon: Icons.lightbulb_outline,
                              maxLines: 3,
                            ),
                          ],
                          
                          // Address
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Address',
                            hint: 'Enter your full address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                          
                          // Terms and Conditions
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: true,
                                onChanged: (value) {},
                                activeColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'I agree to the Terms of Service and Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Sign Up Button
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _handleSignup,
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Complete Sign Up',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
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
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    return Row(
      children: [
        Text(
          'Step $current of $total',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(
          total,
          (index) => Container(
            margin: const EdgeInsets.only(left: 4),
            width: 30,
            height: 4,
            decoration: BoxDecoration(
              color: index < current
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                gender,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedPhoneDisplay() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: AppTheme.successColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                '+91 ${widget.phone}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      color: AppTheme.successColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Fee Range (₹)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
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
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _minFeesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Min',
                      filled: true,
                      fillColor: Colors.grey[100],
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
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _maxFeesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Max',
                      filled: true,
                      fillColor: Colors.grey[100],
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                readOnly: readOnly,
                keyboardType: keyboardType,
                maxLines: maxLines,
                inputFormatters: inputFormatters,
                validator: validator,
                onTap: onTap,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white54 : AppTheme.textSecondary,
                  ),
                  prefixIcon: Icon(icon, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: maxLines > 1 ? 16 : 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSubjectPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPickerSheet(
        'Select Subject',
        _subjects,
        _subjectController.text,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _subjectController.text = selected;
      });
    }
  }

  void _showExperiencePicker(BuildContext context) async {
    final options = [
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
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPickerSheet(
        'Select Experience',
        options,
        _experienceController.text,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _experienceController.text = selected;
      });
    }
  }

  void _showGradePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMultiPickerSheet(
        'Select Grade/Class',
        _grades,
        _selectedGrades,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedGrades = selected;
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

  // Multi-select Subject Picker
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
      });
    }
  }

  // Multi-select Preferred Classes Picker
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
      });
    }
  }

  // Multi-select Picker Sheet
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

  // Multi-select Field Builder
  Widget _buildMultiSelectField({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> selectedItems,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedItems.isEmpty ? hint : '${selectedItems.length} selected',
                        style: TextStyle(
                          color: selectedItems.isEmpty
                              ? Colors.grey[500]
                              : AppTheme.textPrimary,
                          fontWeight: selectedItems.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                if (selectedItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Automatically inserts '/' after dd and dd/mm while the user types digits.
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
