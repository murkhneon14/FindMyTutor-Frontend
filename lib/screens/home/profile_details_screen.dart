import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ProfileDetailsScreen({super.key, required this.user});

  void _showEditDialog(
    BuildContext context,
    String field,
    String currentValue,
  ) {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $field';
              }
              if (field == 'Email' && !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                // In a real app, you would update the user's data here
                // For now, we'll just close the dialog
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$field updated successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppTheme.darkBackgroundColor
          : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Show options for what to edit
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Edit Name'),
                      onTap: () {
                        Navigator.pop(context);
                        _showEditDialog(
                          context,
                          'Name',
                          user?['name']?.toString() ?? '',
                        );
                      },
                    ),
                    if (user?['email'] != null)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Edit Email'),
                        onTap: () {
                          Navigator.pop(context);
                          _showEditDialog(
                            context,
                            'Email',
                            user!['email']?.toString() ?? '',
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text('Cancel'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header - Simplified
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Column(
                children: [
                  // Profile Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]!.withOpacity(0.5)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      user?['name']?.toString() ?? 'User',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // User Email
                  if (user?['email'] != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        user!['email']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Profile Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionHeader(
                    'Personal Information',
                    Icons.person_outline,
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    context: context,
                    items: [
                      if (user?['name'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.person,
                          label: 'Full Name',
                          value: user!['name']?.toString() ?? 'Not provided',
                        ),
                      if (user?['email'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.email,
                          label: 'Email',
                          value: user!['email']?.toString() ?? 'Not provided',
                        ),
                      if (user?['phone'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.phone,
                          label: 'Phone',
                          value: user!['phone']?.toString() ?? 'Not provided',
                        ),
                      if (user?['gender'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.transgender,
                          label: 'Gender',
                          value: _capitalizeFirst(
                            user!['gender']?.toString() ?? 'Not specified',
                          ),
                        ),
                      if (user?['dateOfBirth'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.cake,
                          label: 'Date of Birth',
                          value: _formatDate(user!['dateOfBirth']),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Account Information',
                    Icons.account_circle_outlined,
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    context: context,
                    items: [
                      if (user?['userType'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.category,
                          label: 'Account Type',
                          value: _capitalizeFirst(
                            user!['userType']?.toString() ?? 'User',
                          ),
                        ),
                      if (user?['createdAt'] != null)
                        _buildDetailItem(
                          context: context,
                          icon: Icons.calendar_today,
                          label: 'Member Since',
                          value: _formatDateTime(user!['createdAt']),
                        ),
                      if (user?['isEmailVerified'] != null)
                        _buildVerificationStatus(
                          context: context,
                          isVerified: user!['isEmailVerified'] == true,
                          label: 'Email Verification',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    BuildContext context,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white : Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          items.length,
          (index) => Column(
            children: [
              items[index],
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : Colors.grey[200],
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDarkMode
                  ? Colors.white70
                  : Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus({
    required BuildContext context,
    required bool isVerified,
    required String label,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification status icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? (isVerified
                        ? Colors.green[900]!.withOpacity(0.3)
                        : Colors.orange[900]!.withOpacity(0.3))
                  : (isVerified ? Colors.green[50] : Colors.orange[50]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVerified ? Icons.verified : Icons.warning_amber_rounded,
              color: isVerified
                  ? (isDarkMode ? Colors.green[300]! : Colors.green[600]!)
                  : (isDarkMode ? Colors.orange[300]! : Colors.orange[600]!),
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Verification status text and actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                // Status and resend button
                Row(
                  children: [
                    // Status text
                    Text(
                      isVerified ? 'Verified' : 'Not Verified',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? (isVerified
                                  ? Colors.green[300]!
                                  : Colors.orange[300]!)
                            : (isVerified
                                  ? Colors.green[600]!
                                  : Colors.orange[600]!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Resend button (only shown if not verified)
                    if (!isVerified) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement verification resend
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verification email sent!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'Not specified';

      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Invalid date';
      }

      // Format: MMM d, yyyy (e.g., Oct 8, 2023)
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
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
        return 'Invalid date';
      }

      // Format: MMM d, yyyy at h:mm AM/PM
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final period = dt.hour < 12 ? 'AM' : 'PM';
      var hour = dt.hour % 12;
      if (hour == 0) hour = 12;

      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
