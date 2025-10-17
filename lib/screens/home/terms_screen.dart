import 'package:flutter/material.dart';
import '../../config/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            context,
            Icons.handshake_outlined,
            'Acceptance of Terms',
            'By accessing and using FindMyTutor, you accept and agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.',
          ),
          _buildSection(
            context,
            Icons.account_circle_outlined,
            'User Accounts',
            'You must:\n• Provide accurate and complete information\n• Maintain the security of your account\n• Be at least 13 years old\n• Not create multiple accounts\n• Notify us of any unauthorized access',
          ),
          _buildSection(
            context,
            Icons.school_outlined,
            'Tutor Responsibilities',
            'Tutors must:\n• Provide accurate qualifications and experience\n• Maintain professional conduct\n• Honor scheduled sessions\n• Communicate clearly about fees and availability\n• Comply with local laws and regulations',
          ),
          _buildSection(
            context,
            Icons.person_outlined,
            'Student Responsibilities',
            'Students must:\n• Treat tutors with respect\n• Communicate clearly about requirements\n• Honor payment agreements\n• Provide feedback honestly\n• Report any issues promptly',
          ),
          _buildSection(
            context,
            Icons.payment_outlined,
            'Payments & Fees',
            'FindMyTutor is a platform connecting students and tutors. Payment arrangements are made directly between users. We do not process payments or take commissions from tutoring fees.',
          ),
          _buildSection(
            context,
            Icons.gavel_outlined,
            'Prohibited Activities',
            'Users must not:\n• Harass or abuse other users\n• Share false or misleading information\n• Violate intellectual property rights\n• Use the platform for illegal activities\n• Attempt to bypass security measures',
          ),
          _buildSection(
            context,
            Icons.report_outlined,
            'Content & Conduct',
            'We reserve the right to remove content or suspend accounts that violate our policies. Users are responsible for their own content and interactions.',
          ),
          _buildSection(
            context,
            Icons.shield_outlined,
            'Limitation of Liability',
            'FindMyTutor provides a platform for connections. We are not responsible for:\n• Quality of tutoring services\n• Disputes between users\n• Payment issues\n• User conduct or safety',
          ),
          _buildSection(
            context,
            Icons.cancel_outlined,
            'Termination',
            'We may suspend or terminate accounts that violate these terms. Users may close their accounts at any time through the app settings.',
          ),
          _buildSection(
            context,
            Icons.edit_outlined,
            'Changes to Terms',
            'We may modify these terms at any time. Continued use of the platform after changes constitutes acceptance of the new terms.',
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
                  Icons.support_agent_outlined,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact us at support@findmytutor.com',
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
