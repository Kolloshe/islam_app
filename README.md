# 📖 Quran App

A beautiful and feature-rich Quran application built with Flutter, offering a complete Islamic reading and listening experience.

## ✨ Features

### 📚 Core Features
- **Complete Quran Text**: All 114 surahs with Arabic text and translations
- **Audio Recitations**: High-quality audio from renowned reciters worldwide
- **Bookmarks**: Save your favorite verses and reading positions
- **Continue Reading**: Resume from where you left off
- **Search**: Find specific surahs, verses, or keywords
- **Offline Support**: Download audio files for offline listening

### 🌍 Localization
- **Bilingual Support**: Full English and Arabic interface
- **RTL Support**: Proper right-to-left layout for Arabic
- **Cultural Adaptation**: Context-aware translations and formatting

### 🎵 Audio Features
- **Multiple Reciters**: Choose from various recitation styles
- **Background Playback**: Listen while using other apps
- **Speed Control**: Adjust playback speed
- **Download Management**: Download surahs for offline access

### 📱 User Experience
- **Modern UI**: Clean, intuitive interface with Material Design
- **Dark/Light Theme**: Comfortable reading in any lighting
- **Responsive Design**: Optimized for all screen sizes
- **Accessibility**: Screen reader support and large text options

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/quran_app.git
   cd quran_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── l10n/                 # Localization files
│   ├── app_en.arb       # English translations
│   └── app_ar.arb       # Arabic translations
├── models/              # Data models
│   ├── surah_model.dart
│   ├── reciter_model.dart
│   ├── bookmark_model.dart
│   └── azkar_model.dart
├── providers/           # State management
│   ├── quran_provider.dart
│   ├── audio_provider.dart
│   ├── bookmark_provider.dart
│   └── settings_provider.dart
├── screens/             # UI screens
│   ├── home_screen.dart
│   ├── surah_list_screen.dart
│   ├── surah_detail_screen.dart
│   ├── reciters_screen.dart
│   └── settings_screen.dart
├── services/            # Business logic
│   ├── quran_api_service.dart
│   ├── audio_service.dart
│   └── bookmark_service.dart
└── widgets/             # Reusable UI components
    ├── surah_card.dart
    ├── audio_player_widget.dart
    └── continue_reading_widget.dart
```

## 🛠 Technologies Used

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **HTTP**: API communication
- **Shared Preferences**: Local data storage
- **Audio Players**: Media playback
- **Localization**: Multi-language support

## 📱 Screenshots

*[Add screenshots of your app here]*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Quran API for providing the Quran text and translations
- Audio reciters for their beautiful recitations
- Flutter community for the excellent framework and packages

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

**Made with ❤️ for the Muslim community**
