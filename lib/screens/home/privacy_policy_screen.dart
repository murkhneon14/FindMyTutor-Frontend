import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            context,
            Icons.security,
            'Data Collection',
            'We collect information you provide when creating an account, including your name, email, phone number, and location. For tutors, we also collect qualifications and experience details.',
          ),
          _buildSection(
            context,
            Icons.lock_outline,
            'How We Use Your Data',
            'Your data is used to:\n• Connect students with suitable tutors\n• Facilitate communication between users\n• Improve our services\n• Send important notifications\n• Ensure platform security',
          ),
          _buildSection(
            context,
            Icons.share_outlined,
            'Data Sharing',
            'We do not sell your personal information. Your profile information is visible to other users to facilitate tutoring connections. We may share data with service providers who help us operate the platform.',
          ),
          _buildSection(
            context,
            Icons.location_on_outlined,
            'Location Data',
            'We use your location to help you find nearby tutors. Location data is only collected when you use the search feature and is not continuously tracked.',
          ),
          _buildSection(
            context,
            Icons.cookie_outlined,
            'Cookies & Tracking',
            'We use cookies and similar technologies to enhance your experience, remember your preferences, and analyze platform usage.',
          ),
          _buildSection(
            context,
            Icons.verified_user_outlined,
            'Your Rights',
            'You have the right to:\n• Access your personal data\n• Request data correction or deletion\n• Opt-out of marketing communications\n• Export your data\n• Close your account',
          ),
          _buildSection(
            context,
            Icons.child_care_outlined,
            'Children\'s Privacy',
            'Our service is not intended for users under 13 years of age. We do not knowingly collect data from children.',
          ),
          _buildSection(
            context,
            Icons.update_outlined,
            'Policy Updates',
            'We may update this policy periodically. Significant changes will be communicated via email or in-app notifications.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Questions about privacy?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact us at privacy@findmytutor.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Last updated: October 17, 2025',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
