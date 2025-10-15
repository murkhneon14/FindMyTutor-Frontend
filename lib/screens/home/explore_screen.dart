import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/subject.dart';
import 'widgets/subject_card.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api.dart';
import '../../services/chat_service.dart';
import '../../models/chat_room.dart';
import '../chat_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  String? _selectedSubject;
  double _searchRadius = 5.0; // km
  String? _currentUserId;
  String? _currentUserName;

  final List<Subject> _subjects = [
    Subject(
      name: 'Mathematics',
      imageUrl:
          'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800',
      tutorCount: 245,
      color: const Color(0xFF6366F1),
    ),
    Subject(
      name: 'History',
      imageUrl:
          'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=800',
      tutorCount: 189,
      color: const Color(0xFFEC4899),
    ),
    Subject(
      name: 'Science',
      imageUrl:
          'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800',
      tutorCount: 312,
      color: const Color(0xFF10B981),
    ),
    Subject(
      name: 'English',
      imageUrl:
          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800',
      tutorCount: 198,
      color: const Color(0xFFF59E0B),
    ),
    Subject(
      name: 'Physics',
      imageUrl:
          'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=800',
      tutorCount: 156,
      color: const Color(0xFF8B5CF6),
    ),
    Subject(
      name: 'Chemistry',
      imageUrl:
          'https://images.unsplash.com/photo-1603126857599-f6e157fa2fe6?w=800',
      tutorCount: 143,
      color: const Color(0xFF06B6D4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? userName = prefs.getString('user_name');
    
    // If user data is not in SharedPreferences, try to fetch it from the API
    if (userId == null || userName == null) {
      final token = prefs.getString('auth_token');
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final user = data['user'] ?? data;
            
            userId = user['_id']?.toString() ?? user['id']?.toString();
            userName = user['name']?.toString();
            final userEmail = user['email']?.toString();
            final userRole = user['role']?.toString();
            
            // Save to SharedPreferences for future use
            if (userId != null) await prefs.setString('user_id', userId);
            if (userName != null) await prefs.setString('user_name', userName);
            if (userEmail != null) await prefs.setString('user_email', userEmail);
            if (userRole != null) await prefs.setString('user_role', userRole);
            
            print('Fetched and saved user data: ID=$userId, Name=$userName');
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }
    }
    
    setState(() {
      _currentUserId = userId;
      _currentUserName = userName;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchNearbyTeachers() async {
    if (_currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location to search nearby teachers'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _getCurrentLocation();
      return;
    }

    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('Auth Token: ${token != null ? 'Token exists' : 'No token found'}');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to search for teachers'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final requestBody = {
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'radius': _searchRadius,
        if (_selectedSubject != null && _selectedSubject!.isNotEmpty)
          'subject': _selectedSubject,
        'page': 1,
        'limit': 20,
      };

      print(
        'Sending request to: ${ApiConfig.baseUrl}/api/auth/nearby-teachers',
      );
      print('Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/nearby-teachers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');

        final tutors = responseData['tutors'] ?? [];
        print('Found ${tutors.length} teachers');

        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(tutors);
        });

        if (mounted) {
          if (_searchResults.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No teachers found in your area'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      } else {
        final errorMessage = response.body.isNotEmpty
            ? jsonDecode(response.body)['message'] ?? 'Unknown error occurred'
            : 'No response from server';

        print('Error response: $errorMessage');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Exception in _searchNearbyTeachers: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildPopularTab(), _buildSearchTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      'Perfect Tutor',
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _currentLocation != null
                              ? Icons.location_on
                              : Icons.location_off,
                        ),
                  onPressed: _getCurrentLocation,
                  color: AppTheme.primaryColor,
                  tooltip: _currentLocation != null
                      ? 'Location: ${_currentLocation!.latitude.toStringAsFixed(2)}, ${_currentLocation!.longitude.toStringAsFixed(2)}'
                      : 'Get Location',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Popular'),
          Tab(text: 'Search'),
        ],
      ),
    );
  }

  Widget _buildPopularTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            return SubjectCard(subject: _subjects[index]);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSearchTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),

        // Location Status
        if (_currentLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppTheme.successColor.withOpacity(0.15)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Searching near: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Search Radius Slider
        Text(
          'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        Slider(
          value: _searchRadius,
          min: 1,
          max: 50,
          divisions: 49,
          label: '${_searchRadius.toStringAsFixed(1)} km',
          activeColor: AppTheme.primaryColor,
          inactiveColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
          onChanged: (value) {
            setState(() {
              _searchRadius = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Subject Filter
        Text(
          'Filter by Subject',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey[700]!
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'All Subjects',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'All Subjects',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                ..._subjects.map(
                  (subject) => DropdownMenuItem<String>(
                    value: subject.name,
                    child: Text(
                      subject.name,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Search Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSearching ? null : _searchNearbyTeachers,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
            ),
            child: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Search Teachers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Search Results
        if (_searchResults.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_searchResults.length} Teachers Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ..._searchResults
                  .map((teacher) => _buildTeacherCard(teacher))
                  .toList(),
            ],
          )
        else if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_searchController.text.isNotEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No teachers found',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search radius or filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleMessageTeacher(Map<String, dynamic> teacher) async {
    if (_currentUserId == null || _currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to message teachers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = teacher['userId'] ?? {};
    final teacherId = user['_id']?.toString();
    final teacherName = user['name']?.toString() ?? 'Teacher';
    final teacherEmail = user['email']?.toString() ?? '';

    if (teacherId == null || teacherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to message this teacher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get or create chat
      final chatRoom = await _chatService.getOrCreateChat(
        _currentUserId!,
        teacherId,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (chatRoom != null) {
        // Navigate to chat screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatRoom.id,
                currentUserId: _currentUserId!,
                currentUserName: _currentUserName!,
                otherUser: ChatUser(
                  id: teacherId,
                  name: teacherName,
                  email: teacherEmail,
                  role: 'teacher',
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create chat. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final user = teacher['userId'] ?? {};
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final subjects = (teacher['subjects'] as List?)?.join(', ') ?? 'N/A';
    final experience = teacher['experience']?.toString() ?? 'N/A';
    final fees = teacher['fees']?.toDouble() ?? 0.0;
    final qualifications = teacher['qualifications']?.toString() ?? 'N/A';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subjects,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${fees.toStringAsFixed(0)}/hr',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.school,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    qualifications,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.work,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '$experience years experience',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleMessageTeacher(teacher),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.message, color: Colors.white, size: 18),
                label: const Text(
                  'Message',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
