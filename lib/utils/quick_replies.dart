/// Quick reply options for the chat message system.
/// Shown above the input area based on user role (parent vs teacher).
class QuickReplies {
  /// Quick replies for parents (when chatting with teachers)
  static const List<String> forParents = [
    'Hello sir, are you available to chat?',
    'Good morning!',
    'Are you currently free for a teaching session?',
    'Good evening!',
    'Are you taking new students?',
    'Good afternoon! I\'d like to discuss about the classes and schedule?',
    'Please let me know your fee structure.',
    'Thank you for responding!',
  ];

  /// Quick replies for teachers (when chatting with parents/students)
  static const List<String> forTeachers = [
    'Hello! Are you looking for tuition for your child?',
    'I\'m available to chat now. How can I help?',
    'May I know the subject and class of the student?',
    'Good morning! Please share your location for offline classes.',
    'I can provide a demo class if needed.',
    'Thank you for contacting me!',
    'Please feel free to ask any questions.',
  ];

  /// Get quick replies based on current user's role.
  /// When chatting with a teacher, current user is parent.
  /// When chatting with a student, current user is teacher.
  static List<String> getRepliesForRole(String otherUserRole) {
    final role = otherUserRole.toLowerCase();
    if (role == 'teacher') {
      return forParents;
    }
    return forTeachers;
  }
}
