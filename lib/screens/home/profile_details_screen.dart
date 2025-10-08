import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ProfileDetailsScreen({super.key, this.user});

  String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = _stringOrEmpty(user != null ? user!['name'] : '');
    final email = _stringOrEmpty(user != null ? user!['email'] : '');
    final phone = _stringOrEmpty(user != null ? user!['phone'] : '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoTile(context, 'Email', email, Icons.email_outlined),
          _buildInfoTile(context, 'Phone', phone, Icons.phone_outlined),
          _buildInfoTile(
            context,
            'Role',
            _stringOrEmpty(user != null ? user!['role'] : ''),
            Icons.badge_outlined,
          ),
          _buildInfoTile(
            context,
            'Joined',
            _stringOrEmpty(user != null ? user!['createdAt'] : ''),
            Icons.calendar_month_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


