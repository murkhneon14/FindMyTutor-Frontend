import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/subject.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api.dart';
import '../../services/chat_service.dart';
import '../../models/chat_room.dart';
import '../chat_screen.dart';
import '../../services/subscription_service.dart';
import '../subscription/subscription_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _bannerController;
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  List<String> _selectedSubjects = []; // Changed to support multiple subjects
  List<String> _selectedPreferredClasses =
      []; // Filter by preferred classes/grades
  double _searchRadius = 5.0; // km
  String? _currentUserId;
  String? _currentUserName;
  String? _userRole; // Track user role (teacher/student)
  int _currentBannerPage = 0;

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
    _bannerController = PageController(viewportFraction: 0.9);
    _getCurrentLocation();
    _loadCurrentUser();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _bannerController.hasClients) {
        final nextPage = (_currentBannerPage + 1) % 3;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _currentBannerPage = nextPage;
        _startAutoScroll();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? userName = prefs.getString('user_name');
    String? userRole = prefs.getString('user_role');

    // If user data is not in SharedPreferences, try to fetch it from the API
    if (userId == null || userName == null) {
      final token = prefs.getString('auth_token');
      if (token != null) {
        try {
          final response = await http
              .get(
                Uri.parse(ApiConfig.me),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw Exception('Request timeout - please check your internet connection');
                },
              );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final user = data['user'] ?? data;

            userId = user['_id']?.toString() ?? user['id']?.toString();
            userName = user['name']?.toString();
            final userEmail = user['email']?.toString();
            userRole = user['role']?.toString();

            // Save to SharedPreferences for future use
            if (userId != null) await prefs.setString('user_id', userId);
            if (userName != null) await prefs.setString('user_name', userName);
            if (userEmail != null)
              await prefs.setString('user_email', userEmail);
            if (userRole != null) await prefs.setString('user_role', userRole);

            print(
              '✅ Fetched and saved user data: ID=$userId, Name=$userName, Role=$userRole',
            );
          } else {
            print('❌ Error fetching profile: HTTP ${response.statusCode}');
          }
        } catch (e) {
          print('❌ Error fetching profile: $e');
          // Continue with cached data if available
        }
      }
    }

    // Always set the state with the loaded or fetched data
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _currentUserName = userName;
        _userRole = userRole;
      });
    }

    print('User role loaded: $_userRole');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentLocation = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
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
        if (_selectedSubjects.isNotEmpty)
          'subjects': _selectedSubjects, // Send array of subjects
        if (_selectedPreferredClasses.isNotEmpty)
          'preferredClasses':
              _selectedPreferredClasses, // Send array of preferred classes
        'page': 1,
        'limit': 20,
      };

      print('🔍 ========== SEARCH NEARBY TEACHERS ==========');
      print('🔍 Endpoint: ${ApiConfig.nearbyTeachers}');
      print('🔍 Request Headers: Content-Type: application/json, Authorization: Bearer ***');
      print('🔍 Request Body: $requestBody');
      print('🔍 ============================================');

      final response = await http
          .post(
            Uri.parse(ApiConfig.nearbyTeachers),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout - please check your internet connection');
            },
          );

      print('✅ Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<')) {
          throw FormatException('Server returned HTML instead of JSON. Endpoint may not exist.');
        }
        
        final responseData = jsonDecode(response.body);
        print('✅ Parsed response data: $responseData');

        final tutors = responseData['tutors'] ?? [];
        print('✅ Found ${tutors.length} teachers');

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
        print('❌ API Error - Status Code: ${response.statusCode}');
        print('❌ Response Headers: ${response.headers}');
        print('❌ Response Body: ${response.body}');
        
        final errorMessage = response.body.isNotEmpty
            ? jsonDecode(response.body)['message'] ?? 'Unknown error occurred'
            : 'No response from server';

        print('❌ Error Message: $errorMessage');

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
      print('❌❌❌ EXCEPTION in _searchNearbyTeachers ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);

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

  Future<void> _searchNearbyStudents() async {
    if (_currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location to search nearby students'),
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
              content: Text('Please login to search for students'),
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
        if (_selectedPreferredClasses.isNotEmpty)
          'classGrades': _selectedPreferredClasses, // Send array of class grades
        'page': 1,
        'limit': 20,
      };

      print('🔍 ========== SEARCH NEARBY STUDENTS ==========');
      print('🔍 Endpoint: ${ApiConfig.nearbyStudents}');
      print('🔍 Request Headers: Content-Type: application/json, Authorization: Bearer ***');
      print('🔍 Request Body: $requestBody');
      print('🔍 ============================================');

      final response = await http
          .post(
            Uri.parse(ApiConfig.nearbyStudents),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout - please check your internet connection');
            },
          );

      print('✅ Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<')) {
          throw FormatException('Server returned HTML instead of JSON. Endpoint may not exist.');
        }
        
        final responseData = jsonDecode(response.body);
        print('✅ Parsed response data: $responseData');

        final students = responseData['students'] ?? [];
        print('✅ Found ${students.length} students');

        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(students);
        });

        if (students.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No students found in this area'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('❌ API Error - Status Code: ${response.statusCode}');
        print('❌ Response Headers: ${response.headers}');
        print('❌ Response Body: ${response.body}');
        
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to fetch students';
        print('❌ Error Message: $errorMessage');

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
      print('❌❌❌ EXCEPTION in _searchNearbyStudents ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);

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

  // Search teachers by subject when subject card is tapped
  Future<void> _searchBySubject(String subjectName) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      // Switch to search tab and set the subject filter
      _tabController.animateTo(1); // Switch to Search tab
      _selectedSubjects = [subjectName]; // Set the selected subject
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to search'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final requestBody = {
        'subject': subjectName, // Search by this subject (no location needed)
        'page': 1,
        'limit': 50, // Get more results since we're not filtering by location
      };

      print('🔍 ========== SEARCH BY SUBJECT ==========');
      print('🔍 Subject: $subjectName');
      print('🔍 Request Body: $requestBody');
      print('🔍 Endpoint: ${ApiConfig.searchBySubject}');
      print('🔍 ========================================');

      final response = await http
          .post(
            Uri.parse(ApiConfig.searchBySubject),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      print('✅ Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final isHtml = response.body.trim().startsWith('<');
      if (response.statusCode == 200 && !isHtml) {
        final data = jsonDecode(response.body);
        final teachersList = data['teachers'] ?? [];
        print('📦 Found ${teachersList.length} teachers for $subjectName');

        if (mounted) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(teachersList);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${_searchResults.length} $subjectName teachers'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Fallback when dedicated endpoint is unavailable or returns HTML
        print('⚠️ search-by-subject unavailable (status ${response.statusCode}, html=$isHtml). Falling back...');

        // 1) If we have location, use nearbyTeachers with subject filter
        if (_currentLocation != null) {
          final fallbackBody = {
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
            'radius': _searchRadius,
            'subjects': [subjectName],
            'page': 1,
            'limit': 20,
          };

          final nearby = await http.post(
            Uri.parse(ApiConfig.nearbyTeachers),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(fallbackBody),
          ).timeout(const Duration(seconds: 15));

          if (nearby.statusCode == 200 && !nearby.body.trim().startsWith('<')) {
            final data = jsonDecode(nearby.body);
            final tutors = data['tutors'] ?? data['teachers'] ?? [];
            if (mounted) {
              setState(() {
                _searchResults = List<Map<String, dynamic>>.from(tutors);
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found ${_searchResults.length} $subjectName teachers nearby'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            return;
          }
        }

        // 2) Otherwise fetch all and filter client-side by subject name
        try {
          final all = await http.get(
            Uri.parse(ApiConfig.allTeachers),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 15));

          if (all.statusCode == 200 && !all.body.trim().startsWith('<')) {
            final data = jsonDecode(all.body);
            final list = (data['teachers'] ?? data) as dynamic;
            final List filtered = (list as List).where((t) {
              final subjects = (t['subjects'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [];
              return subjects.contains(subjectName.toLowerCase());
            }).toList();

            if (mounted) {
              setState(() {
                _searchResults = List<Map<String, dynamic>>.from(filtered.cast<Map<String, dynamic>>());
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found ${_searchResults.length} $subjectName teachers'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            throw Exception('Fallback failed: all-teachers status ${all.statusCode}');
          }
        } catch (_) {
          throw Exception('Failed to search: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error in _searchBySubject: $e');
      print(stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for $subjectName teachers: $e'),
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildPromoBanner(),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [_buildPopularTab(), _buildSearchTab()],
          ),
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
                    'Find My',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      _userRole == 'teacher' ? ' Student' : ' Tutor',
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

  Widget _buildPromoBanner() {
    final List<String> bannerImages = [
      'assets/images/lekhi_tutorials_banner.jpg',
      'assets/images/lekhi_tutorials_banner1.jpg',
      'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1200&h=400&fit=crop',
    ];

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: bannerImages.length,
        controller: _bannerController,
        onPageChanged: (index) {
          setState(() {
            _currentBannerPage = index;
          });
        },
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    bannerImages[index].startsWith('http')
                        ? Image.network(
                            bannerImages[index],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackBanner();
                            },
                          )
                        : Image.asset(
                            bannerImages[index],
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackBanner();
                            },
                          ),
                    // Page Indicator
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          bannerImages.length,
                          (dotIndex) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentBannerPage == dotIndex ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentBannerPage == dotIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_rounded, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(
              'Advertise Your Coaching',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reach thousands of students',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, size: 20),
                SizedBox(width: 8),
                Text('Popular'),
              ],
            ),
          ),
          Tab(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, size: 20),
                SizedBox(width: 8),
                Text('Search'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return _AnimatedSubjectCard(
                subject: _subjects[index],
                index: index,
                onTap: () => _searchBySubject(_subjects[index].name),
              );
            }, childCount: _subjects.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildSearchTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
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
                max: 100,
                divisions: 99,
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

              // Filter Section - Show subjects for students, class grades for teachers
              if (_userRole != 'teacher') ...[
                // Subject Filter (for students)
                Text(
                  'Filter by Subject',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects.map((subject) {
                        final isSelected = _selectedSubjects.contains(
                          subject.name,
                        );
                        return FilterChip(
                          label: Text(subject.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSubjects.add(subject.name);
                              } else {
                                _selectedSubjects.remove(subject.name);
                              }
                            });
                          },
                          backgroundColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          selectedColor: subject.color.withOpacity(0.3),
                          checkmarkColor: subject.color,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? subject.color
                                : (isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? subject.color
                                : (isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[400]!),
                            width: isSelected ? 2 : 1,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedSubjects.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedSubjects.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              // Class/Grade Filter (for both students and teachers)
              const SizedBox(height: 16),
              Text(
                _userRole == 'teacher'
                    ? 'Filter by Class/Grade'
                    : 'Filter by Preferred Classes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final grades = [
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

                      return InkWell(
                        onTap: () async {
                          // Make a working copy
                          final selected = Set<String>.from(_selectedPreferredClasses);

                          await showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setLocalState) {
                                  return AlertDialog(
                                    title: const Text('Select Classes/Grades'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: grades.map((g) {
                                            final isChecked = selected.contains(g);
                                            return CheckboxListTile(
                                              value: isChecked,
                                              onChanged: (val) {
                                                setLocalState(() {
                                                  if (val == true) {
                                                    selected.add(g);
                                                  } else {
                                                    selected.remove(g);
                                                  }
                                                });
                                              },
                                              title: Text(g),
                                              dense: true,
                                              controlAffinity: ListTileControlAffinity.leading,
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          selected.clear();
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _selectedPreferredClasses.clear();
                                          });
                                        },
                                        child: const Text('Clear'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          setState(() {
                                            _selectedPreferredClasses = selected.toList();
                                          });
                                        },
                                        child: const Text('Apply'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedPreferredClasses.isEmpty
                                      ? 'Select classes/grades'
                                      : _selectedPreferredClasses.join(', '),
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_drop_down,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (_selectedPreferredClasses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedPreferredClasses.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSearching
                      ? null
                      : (_userRole == 'teacher'
                            ? _searchNearbyStudents
                            : _searchNearbyTeachers),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(
                      0.5,
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _userRole == 'teacher'
                              ? 'Search Students'
                              : 'Search Teachers',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                      _userRole == 'teacher'
                          ? '${_searchResults.length} Students Found'
                          : '${_searchResults.length} Teachers Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._searchResults
                        .map(
                          (result) => _userRole == 'teacher'
                              ? _buildStudentCard(result)
                              : _buildTeacherCard(result),
                        )
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
                          color: isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
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

    // Check if user has premium subscription
    final isPremium = await SubscriptionService().isPremiumUser();
    if (!isPremium) {
      _showPremiumDialog();
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

    // Don't allow messaging yourself
    if (teacherId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get or create chat
      final chatRoom = await _chatService.getOrCreateChat(
        _currentUserId!,
        teacherId,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to chat screen
      if (mounted && chatRoom != null) {
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
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if it's a premium subscription error
        if (errorMessage.contains('PREMIUM_REQUIRED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Premium subscription required to message teachers',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Subscribe',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (errorMessage.contains('USER_NOT_FOUND')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile not found. Please ensure both you and the teacher have completed profile setup.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${errorMessage.replaceAll('Exception: CHAT_ERROR: ', '').replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _handleMessageStudent(Map<String, dynamic> student) async {
    if (_currentUserId == null || _currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to message students'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user has premium subscription
    final isPremium = await SubscriptionService().isPremiumUser();
    if (!isPremium) {
      _showPremiumDialog();
      return;
    }

    final user = student['userId'] ?? {};
    final studentId = user['_id']?.toString();
    final studentName = user['name']?.toString() ?? 'Student';
    final studentEmail = user['email']?.toString() ?? '';

    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to message this student'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Don't allow messaging yourself
    if (studentId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get or create chat
      final chatRoom = await _chatService.getOrCreateChat(
        _currentUserId!,
        studentId,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to chat screen
      if (mounted && chatRoom != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatRoom.id,
              currentUserId: _currentUserId!,
              currentUserName: _currentUserName!,
              otherUser: ChatUser(
                id: studentId,
                name: studentName,
                email: studentEmail,
                role: 'student',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if it's a premium subscription error
        if (errorMessage.contains('PREMIUM_REQUIRED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Premium subscription required to message students',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Subscribe',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (errorMessage.contains('USER_NOT_FOUND')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile not found. Please ensure both you and the student have completed profile setup.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${errorMessage.replaceAll('Exception: CHAT_ERROR: ', '').replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final user = student['userId'] ?? {};
    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '';
    final classGrade = student['classGrade']?.toString() ?? 'N/A';
    final schoolName = student['schoolName']?.toString() ?? 'N/A';
    final learningGoals = student['learningGoals']?.toString() ?? 'Not specified';
    final guardianName = student['guardianName']?.toString();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate distance if location data is available
    final studentLat = student['latitude'];
    final studentLon = student['longitude'];
    double? distance;
    if (_currentLocation != null && studentLat != null && studentLon != null) {
      distance = LocationService.calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        studentLat is double ? studentLat : (studentLat as num).toDouble(),
        studentLon is double ? studentLon : (studentLon as num).toDouble(),
      );
    }

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
                          color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.successColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Class: $classGrade',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schoolName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (guardianName != null && guardianName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.family_restroom,
                          size: 16,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guardian: $guardianName',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Goals: $learningGoals',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleMessageStudent(student),
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

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(Icons.lock, color: Color(0xFF6C63FF), size: 28),
            SizedBox(width: 10),
            Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messaging is a premium feature. Subscribe to unlock:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),
            _buildPremiumFeature('Unlimited messaging'),
            _buildPremiumFeature('Direct chat access'),
            _buildPremiumFeature('Real-time notifications'),
            _buildPremiumFeature('Priority support'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '₹299',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  Text(
                    '/month',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Subscribe Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF6C63FF),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}

// Animated 3D Subject Card Widget
class _AnimatedSubjectCard extends StatefulWidget {
  final Subject subject;
  final int index;
  final VoidCallback onTap;

  const _AnimatedSubjectCard({
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedSubjectCard> createState() => _AnimatedSubjectCardState();
}

class _AnimatedSubjectCardState extends State<_AnimatedSubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Start animation
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_isHovered ? -0.05 : 0.0)
                  ..rotateY(_isHovered ? 0.05 : 0.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(
                    0,
                    _isHovered ? -8 : 0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.subject.color.withOpacity(
                          _isHovered ? 0.4 : 0.2,
                        ),
                        blurRadius: _isHovered ? 20 : 12,
                        offset: Offset(0, _isHovered ? 12 : 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.subject.color,
                            widget.subject.color.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Background pattern
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getSubjectIcon(widget.subject.name),
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.subject.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getSubjectIcon(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'english':
        return Icons.menu_book_rounded;
      case 'physics':
        return Icons.bolt_rounded;
      case 'chemistry':
        return Icons.biotech_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
