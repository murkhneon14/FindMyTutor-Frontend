# FindMyTutor - Premium Tutor Marketplace App

A beautiful and modern Flutter application for connecting students with qualified tutors for face-to-face learning.

## Features

### Phase 1 (Current Implementation)
- **Onboarding Experience**: Beautiful animated onboarding screens introducing the app's value proposition
- **Subject Exploration**: Browse tutors by subject with stunning visual cards
- **Tab Navigation**: Switch between Popular and Search views
- **Bottom Navigation**: Easy access to Messages, Explore, and Account sections
- **Premium UI**: Modern design with gradients, smooth animations, and polished components

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator or physical device

### Installation

1. Clone the repository or navigate to the project directory:
```bash
cd "c:/Users/Nikhil Nectar/Downloads/FindMyTutor"
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── theme.dart              # App theme and color configuration
├── models/
│   └── subject.dart            # Subject data model
├── screens/
│   ├── onboarding/
│   │   ├── onboarding_screen.dart
│   │   └── widgets/
│   │       └── onboarding_page.dart
│   └── home/
│       ├── main_navigation.dart
│       ├── explore_screen.dart
│       ├── messages_screen.dart
│       ├── account_screen.dart
│       └── widgets/
│           └── subject_card.dart
└── main.dart                   # App entry point
```

## Design Highlights

- **Color Scheme**: Modern blue gradient (Primary: #2196F3, Accent: #00BCD4)
- **Typography**: Google Fonts (Poppins) for clean, professional look
- **Animations**: Smooth page transitions and element animations
- **Cards**: Elevated cards with shadows and gradients
- **Icons**: Material Design icons with custom styling

## Packages Used

- `google_fonts`: Premium typography
- `smooth_page_indicator`: Elegant page indicators
- `flutter_svg`: SVG support for scalable graphics
- `animations`: Advanced animation capabilities

## Future Enhancements

- Tutor profile pages with ratings and reviews
- Real-time messaging system
- Advanced search and filtering
- Booking and scheduling system
- Payment integration
- User authentication
- Push notifications
- Favorites and saved tutors

## License

This project is created for educational purposes.
