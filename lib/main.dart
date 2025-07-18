import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/quran_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/download_provider.dart';
import 'providers/azkar_provider.dart';
import 'providers/language_provider.dart';
import 'models/surah_model.dart';
import 'screens/home_screen.dart';
import 'screens/surah_list_screen.dart';
import 'screens/surah_detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/downloads_screen.dart';
import 'widgets/app_initializer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.initializeSettings();

  runApp(QuranApp(settingsProvider: settingsProvider));
}

class QuranApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const QuranApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final quranProvider = QuranProvider();
            quranProvider.setSettingsProvider(settingsProvider);
            return quranProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final bookmarkProvider = BookmarkProvider();
            // Initialize bookmarks asynchronously
            Future.microtask(() => bookmarkProvider.initialize());
            return bookmarkProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final downloadProvider = DownloadProvider();
            // Initialize downloads asynchronously
            Future.microtask(() => downloadProvider.initialize());
            return downloadProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AzkarProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: Consumer2<SettingsProvider, LanguageProvider>(
        builder: (context, settings, languageProvider, child) {
          return AppInitializer(
            child: MaterialApp(
              title: 'Holy Quran',
              debugShowCheckedModeBanner: false,
              locale: languageProvider.currentLocale,
              supportedLocales: LanguageProvider.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: settings.themeMode,
              theme: ThemeData(
                primarySwatch: Colors.teal,
                primaryColor: const Color(0xFF00695C),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF00695C),
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                fontFamily: 'Inter',
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                ),
                cardTheme: CardTheme(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                primarySwatch: Colors.teal,
                primaryColor: const Color(0xFF004D40),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF004D40),
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
                fontFamily: 'Inter',
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                ),
                cardTheme: CardTheme(
                  elevation: 2,
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              home: const HomeScreen(),
              routes: {
                '/surah-list': (context) => const SurahListScreen(),
                '/search': (context) => const SearchScreen(),
                '/settings': (context) => const SettingsScreen(),
                '/bookmarks': (context) => const BookmarksScreen(),
                '/downloads': (context) => const DownloadsScreen(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == '/surah-detail') {
                  final surah = settings.arguments as Surah;
                  return MaterialPageRoute(builder: (context) => SurahDetailScreen(surah: surah));
                }
                return null;
              },
            ),
          );
        },
      ),
    );
  }
}
