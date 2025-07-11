import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'blocs/memory_bloc.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/memories_screen.dart';
import 'screens/location_tab.dart';
import 'services/location_service.dart';
import 'services/background_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/geofence_service.dart';
import 'models/memory.dart';

// Global navigator key for handling notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    debugPrint('Starting app initialization...');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter binding initialized');

    // Wrap the entire app with error handling
    runApp(const ErrorBoundary(child: MyApp()));
  } catch (e, stackTrace) {
    debugPrint('Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app with error display
    runApp(const ErrorDisplay());
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          debugPrint('Error caught by ErrorWidget: ${errorDetails.exception}');
          debugPrint('Stack trace: ${errorDetails.stack}');
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorDetails.exception.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget ?? const Scaffold();
      },
      home: child,
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your device settings and try again.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeServices(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error initializing services: ${snapshot.error}');
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Initialization Error',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Force a rebuild of the FutureBuilder
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFCEB00)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Initializing...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return BlocProvider(
          create: (context) => MemoryBloc()..add(LoadMemories()),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'ChronoLapse',
            theme: ThemeData(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF182747), // Deep Navy
                secondary: const Color(0xFFD4AF37), // Classic Gold
                background: const Color(0xFFFFFBF5), // Warm Cream
                surface: const Color(0xFFF8F5ED), // Slightly darker cream for cards
                onPrimary: Colors.white,
                onSecondary: const Color(0xFF0A1931), // Darkest blue for contrast
                onBackground: const Color(0xFF0A1931),
                onSurface: const Color(0xFF182747),
                tertiary: const Color(0xFFE97777), // Terracotta accent
                outline: const Color(0xFFA0AEC0), // Blue-grey for borders
              ),
              textTheme: GoogleFonts.poppinsTextTheme().apply(
                bodyColor: const Color(0xFF0A1931),
                displayColor: const Color(0xFF182747),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFFFFFBF5),
                foregroundColor: const Color(0xFF182747),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: GoogleFonts.comfortaa(
                  color: const Color(0xFF0A1931),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              useMaterial3: true,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37), // Classic Gold
                  foregroundColor: const Color(0xFF0A1931),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFFF8F5ED), // Slightly darker cream
              ),
              iconTheme: const IconThemeData(
                color: Color(0xFF182747), // Deep Navy
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/home': (context) => const MainScreen(),
            },
          ),
        );
      },
    );
  }

  Future<bool> _initializeServices() async {
    try {
      debugPrint('Initializing services...');
      
      // Initialize database first
      final databaseService = DatabaseService();
      await databaseService.database;
      debugPrint('Database service initialized');

      // Initialize location service
      final locationService = LocationService();
      await locationService.initialize();
      debugPrint('Location service initialized');

      // Request permissions but don't fail if not granted
      final hasPermissions = await locationService.requestPermissions().catchError((e) {
        debugPrint('Permission request failed: $e');
        return false;
      });
      debugPrint('Location permissions status: $hasPermissions');

      // Initialize background service
      final backgroundService = BackgroundService();
      await backgroundService.initialize().catchError((e) {
        debugPrint('Background service initialization failed: $e');
      });
      debugPrint('Background service initialized');

      // Initialize notification service
      final notificationService = NotificationService();
      await notificationService.initialize().catchError((e) {
        debugPrint('Notification service initialization failed: $e');
      });
      debugPrint('Notification service initialized');

      // Initialize geofence service
      final geofenceService = GeofenceService();
      await geofenceService.initialize().catchError((e) {
        debugPrint('Geofence service initialization failed: $e');
      });
      debugPrint('Geofence service initialized');

      // Start geofence monitoring
      await geofenceService.startGeofenceMonitoring().catchError((e) {
        debugPrint('Geofence monitoring start failed: $e');
      });
      debugPrint('Geofence monitoring started');

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error in _initializeServices: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          LocationTab(),
          MemoriesScreen(), // Changed to actual MemoriesScreen widget
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureMemory,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).colorScheme.background,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.outline,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 1 ? Icons.location_on : Icons.location_on_outlined),
              label: 'Location',
            ),
            BottomNavigationBarItem(
              icon: Icon(_currentIndex == 2 ? Icons.photo_library : Icons.photo_library_outlined),
              label: 'Memories',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureMemory() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      // Ensure we have a persistent file path
      final imageFile = File(image.path);
      if (!await imageFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Image file not found. Please try again.')),
        );
        return;
      }

      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Please check your location settings.')),
        );
        return;
      }

      // Show note input dialog
      String? note = await showDialog<String>(
        context: context,
        barrierDismissible: true, // Allow dismissing by tapping outside
        builder: (context) {
          final textController = TextEditingController();
          return AlertDialog(
            title: const Text('Add a Note'),
            content: TextField(
              controller: textController,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What\'s special about this moment?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ''), // Return empty string instead of null
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, textController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      // If dialog was dismissed by clicking outside, use empty note
      note ??= '';

      final memory = Memory(
        imagePath: image.path,
        note: note,
        timestamp: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      context.read<MemoryBloc>().add(AddMemory(memory));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory captured successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing memory: $e')),
      );
    }
  }
}
