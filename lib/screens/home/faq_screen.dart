import 'package:flutter/material.dart';
import '../../config/theme.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFAQItem(
            context,
            'How do I find a tutor?',
            'Go to the Explore tab, enter your location or use GPS, select your subject, and browse through available tutors near you.',
          ),
          _buildFAQItem(
            context,
            'How do I contact a tutor?',
            'Click on a tutor\'s profile and tap the "Message" button to start a conversation. You can discuss your requirements, schedule, and fees directly.',
          ),
          _buildFAQItem(
            context,
            'Is FindMyTutor free to use?',
            'Yes! Basic features are completely free. You can search for tutors, message them, and book sessions at no cost. Premium features offer additional benefits.',
          ),
          _buildFAQItem(
            context,
            'How do I become a tutor?',
            'Sign up as a teacher, complete your profile with qualifications and experience, set your availability and fees, and start receiving student requests.',
          ),
          _buildFAQItem(
            context,
            'How is payment handled?',
            'Payment is arranged directly between students and tutors. FindMyTutor does not process payments, giving you flexibility in payment methods.',
          ),
          _buildFAQItem(
            context,
            'Can I cancel a session?',
            'Yes, you can cancel sessions through the chat with your tutor. We recommend informing them at least 24 hours in advance as a courtesy.',
          ),
          _buildFAQItem(
            context,
            'How do I report a problem?',
            'If you encounter any issues, please contact us through the app or email us at support@findmytutor.com. We\'re here to help!',
          ),
          _buildFAQItem(
            context,
            'Is my data secure?',
            'Absolutely! We use industry-standard encryption to protect your data. Read our Privacy Policy for more details on how we handle your information.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
