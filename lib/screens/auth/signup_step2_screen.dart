import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api.dart';

class SignupStep2Screen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String userType; // 'student' or 'teacher'

  const SignupStep2Screen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.userType,
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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _isTeacher = false;
  String? _selectedGender;
  DateTime? _selectedDob;
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
    'College',
    'University',
  ];

  @override
  void initState() {
    super.initState();
    _isTeacher = widget.userType == 'teacher';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _experienceController.dispose();
    _instituteController.dispose();
    _gradeController.dispose();
    _guardianNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
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
          response = await http.post(
            Uri.parse(ApiConfig.teacherProfile),
            headers: headers,
            body: jsonEncode({
              'phone': _phoneController.text.trim(),
              'dob': _selectedDob?.toIso8601String(),
              'gender': (_selectedGender ?? '').toLowerCase(),
              'qualifications': _instituteController.text.trim(),
              'experience': _experienceController.text.trim(),
              'subjects': [_subjectController.text.trim()],
              'fees': 0,
              'timings': 'flexible',
              'location': { 'type': 'Point', 'coordinates': [0, 0] },
              'documents': [],
            }),
          );
        } else {
          response = await http.post(
            Uri.parse(ApiConfig.studentProfile),
            headers: headers,
            body: jsonEncode({
              'phone': _phoneController.text.trim(),
              'dob': _selectedDob?.toIso8601String(),
              'gender': (_selectedGender ?? '').toLowerCase(),
              'classGrade': _gradeController.text.trim(),
              'schoolName': _instituteController.text.trim(),
              'guardianName': _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
              'learningGoals': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
              'address': _addressController.text.trim(),
            }),
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
          Navigator.popUntil(context, (route) => route.isFirst);
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
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
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
                          // Phone Number
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.length != 10) {
                                return 'Please enter a valid 10-digit number';
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
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
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
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDob != null
                                        ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                                        : 'Select your date of birth',
                                    style: TextStyle(
                                      color: _selectedDob != null
                                          ? AppTheme.textPrimary
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                            _buildTextField(
                              controller: _subjectController,
                              label: 'Subject',
                              hint: 'Select your subject',
                              icon: Icons.menu_book_outlined,
                              readOnly: true,
                              onTap: () => _showSubjectPicker(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a subject';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _experienceController,
                              label: 'Years of Experience',
                              hint: 'Enter years of experience',
                              icon: Icons.work_outline,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter years of experience';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            _buildTextField(
                              controller: _instituteController,
                              label: 'School/Institute Name',
                              hint: 'Enter your school or institute name',
                              icon: Icons.school_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your school/institute name';
                                }
                                return null;
                              },
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
                                if (value.length < 30) {
                                  return 'Please write at least 30 characters';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // Student/Parent Specific Fields
                            _buildTextField(
                              controller: _gradeController,
                              label: 'Class/Grade',
                              hint: 'Select your class/grade',
                              icon: Icons.school_outlined,
                              readOnly: true,
                              onTap: () => _showGradePicker(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your class/grade';
                                }
                                return null;
                              },
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: Container(
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
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                readOnly: readOnly,
                keyboardType: keyboardType,
                maxLines: maxLines,
                inputFormatters: inputFormatters,
                validator: validator,
                onTap: onTap,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
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

  void _showGradePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPickerSheet(
        'Select Grade/Class',
        _grades,
        _gradeController.text,
      ),
    );
    
    if (selected != null && mounted) {
      setState(() {
        _gradeController.text = selected;
      });
    }
  }

  Widget _buildPickerSheet(String title, List<String> items, String selected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
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
}
